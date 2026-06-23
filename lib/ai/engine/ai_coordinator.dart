import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbiv2/ai/engine/gemini_live_service.dart';
import 'package:sbiv2/ai/engine/gemini_rest_service.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';
import 'package:sbiv2/ai/tools/tool_dispatcher.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/events/agent_event.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/behavior/proactive_agent_engine.dart';
import 'package:sbiv2/ai/behavior/retention_rules.dart';

// API Key provider (can be updated in UI)
final geminiApiKeyProvider = StateProvider<String>((ref) {
  return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
});

enum AIServiceMode { live, rest, simulated }

class AICoordinatorState {
  final AIServiceMode mode;
  final bool isConnecting;
  final bool isThinking;
  final String? error;

  AICoordinatorState({
    required this.mode,
    required this.isConnecting,
    required this.isThinking,
    this.error,
  });

  AICoordinatorState copyWith({
    AIServiceMode? mode,
    bool? isConnecting,
    bool? isThinking,
    String? error,
  }) {
    return AICoordinatorState(
      mode: mode ?? this.mode,
      isConnecting: isConnecting ?? this.isConnecting,
      isThinking: isThinking ?? this.isThinking,
      error: error,
    );
  }
}

class ToolCallItem {
  final String name;
  final Map<String, dynamic> args;
  final String callId;
  final Future<void> Function(String name, Map<String, dynamic> args, String callId) action;

  ToolCallItem({
    required this.name,
    required this.args,
    required this.callId,
    required this.action,
  });
}

final aiCoordinatorProvider = StateNotifierProvider<AICoordinator, AICoordinatorState>((ref) {
  return AICoordinator(ref);
});

class AICoordinator extends StateNotifier<AICoordinatorState> {
  final Ref _ref;
  final GeminiLiveService _liveService = GeminiLiveService();
  final GeminiRestService _restService = GeminiRestService();

  // Keep conversation history for REST API & Simulated fallback
  final List<Map<String, dynamic>> _restHistory = [];

  // Sequential Tool Call Queue
  final List<ToolCallItem> _toolCallQueue = [];

  // Pending confirmations map
  final Map<String, Completer<bool>> _pendingConfirmations = {};

  void confirmToolCall(String toolCallId, bool approve) {
    final completer = _pendingConfirmations.remove(toolCallId);
    if (completer != null) {
      completer.complete(approve);

      final memory = _ref.read(agentMemoryProvider);
      final profileType = _ref.read(profileTypeProvider);
      final isOnboarding = !memory.onboardingCompleted && profileType == 'A';
      final chatNotifier = isOnboarding
          ? _ref.read(onboardingChatProvider.notifier)
          : _ref.read(bankingChatProvider.notifier);

      chatNotifier.updateMessageStatus(toolCallId, approve ? 'approved' : 'rejected');
    }
  }

  AICoordinator(this._ref)
      : super(AICoordinatorState(
          mode: AIServiceMode.simulated,
          isConnecting: false,
          isThinking: false,
        )) {
    // Listen to profile switches to re-initiate
    _ref.listen(profileTypeProvider, (previous, next) {
      _restHistory.clear();
      _toolCallQueue.clear();
      final memory = _ref.read(agentMemoryProvider);
      final isOnboarding = !memory.onboardingCompleted && next == 'A';
      _ref.read(agentStateProvider.notifier).setMode(
        isOnboarding ? AgentMode.onboarding : AgentMode.banking
      );
      _ref.read(agentStateProvider.notifier).reset();
      _initializeService();
    });

    _initializeService();
  }

  Future<void> _initializeService() async {
    final apiKey = _ref.read(geminiApiKeyProvider);
    final agentState = _ref.read(agentStateProvider.notifier);
    final eventNotifier = _ref.read(agentEventProvider.notifier);

    // Initialize mode
    final memory = _ref.read(agentMemoryProvider);
    final profileType = _ref.read(profileTypeProvider);
    final isOnboarding = !memory.onboardingCompleted && profileType == 'A';
    agentState.setMode(isOnboarding ? AgentMode.onboarding : AgentMode.banking);

    if (apiKey.isEmpty) {
      state = state.copyWith(mode: AIServiceMode.simulated, error: "No API Key. Running in simulated mode.");
      agentState.setConnectionStatus("disconnected");
      agentState.setStatus(AgentStatus.idle);
      agentState.updateTransportInfo(
        transportType: "simulated",
        webSocketStatus: "disconnected",
        restStatus: "inactive",
        decisionSource: "Local Rule Engine",
      );
      _triggerProactiveWelcome();
      return;
    }

    state = state.copyWith(mode: AIServiceMode.rest, isConnecting: false, error: null);
    agentState.setConnectionStatus("REST_ACTIVE");
    agentState.setStatus(AgentStatus.idle);
    agentState.updateTransportInfo(
      transportType: "rest",
      webSocketStatus: "disconnected",
      restStatus: "active",
      decisionSource: "Gemini REST",
    );
    eventNotifier.emit(AgentEventType.connected, "Connected to Gemini REST");
    _ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.connection,
      title: 'Gemini REST Active',
      description: 'REST session active with Gemini API.',
      status: TimelineEntryStatus.success,
    );
    _triggerProactiveWelcome();
  }

  // Unified tool caller that handles agent state machine transitions and failures
  Future<Map<String, dynamic>> _executeTool(String name, Map<String, dynamic> args) async {
    final agentState = _ref.read(agentStateProvider.notifier);
    final eventNotifier = _ref.read(agentEventProvider.notifier);
    final timeline = _ref.read(timelineProvider.notifier);
    agentState.startToolCall(name);

    eventNotifier.emit(AgentEventType.toolStarted, "Tool execution started: $name", metadata: {'name': name, 'args': args});
    timeline.log(
      type: TimelineEntryType.toolStarted,
      title: 'Tool: $name',
      description: 'Args: ${args.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      status: TimelineEntryStatus.running,
    );

    try {
      final output = await ToolDispatcher.dispatch(_ref, name, args);
      if (output['status'] == 'failed' || output['status'] == 'error') {
        final reason = output['reason'] ?? 'Unknown tool failure';
        agentState.endToolCall(error: reason);
        eventNotifier.emit(AgentEventType.toolFailed, "Tool execution failed: $name", metadata: {'name': name, 'reason': reason});
        timeline.log(
          type: TimelineEntryType.toolFailed,
          title: '$name Failed',
          description: reason,
          status: TimelineEntryStatus.failed,
        );
      } else {
        agentState.endToolCall();
        eventNotifier.emit(AgentEventType.toolCompleted, "Tool execution completed: $name", metadata: {'name': name, 'output': output});
        // Special labels for KYC / UPI tools
        final isKyc = name == 'start_kyc';
        final isUpi = name == 'activate_upi';
        timeline.log(
          type: isKyc || isUpi ? TimelineEntryType.onboarding : TimelineEntryType.toolCompleted,
          title: isKyc
              ? 'KYC Step Completed'
              : isUpi
                  ? 'UPI Activated'
                  : '$name Completed',
          description: output['message']?.toString() ?? 'Tool executed successfully.',
          status: TimelineEntryStatus.success,
        );
      }
      return output;
    } catch (e) {
      final errStr = e.toString();
      agentState.endToolCall(error: errStr);
      eventNotifier.emit(AgentEventType.toolFailed, "Tool execution threw exception: $name", metadata: {'name': name, 'reason': errStr});
      timeline.log(
        type: TimelineEntryType.toolFailed,
        title: '$name Exception',
        description: errStr,
        status: TimelineEntryStatus.failed,
      );
      return {'status': 'error', 'reason': errStr};
    }
  }

  String _buildSystemPrompt() {
    final profile = _ref.read(userProfileProvider);
    final txs = _ref.read(transactionsProvider);
    final signals = PatternEngine.analyze(profile, txs);
    final memory = _ref.read(agentMemoryProvider);

    // Track the last detected signal in memory
    if (signals.compactSummaries.isNotEmpty) {
      final latestSignal = signals.compactSummaries.first;
      if (memory.lastDetectedSignal == null || memory.lastDetectedSignal!.key != latestSignal.key) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ref.read(agentMemoryProvider.notifier).setLastDetectedSignal(latestSignal);
          // Log new signal detection to timeline
          _ref.read(timelineProvider.notifier).log(
            type: TimelineEntryType.signalDetected,
            title: 'Signal: ${latestSignal.key}',
            description: latestSignal.title,
            status: TimelineEntryStatus.info,
          );
        });
      }
    }

    final isOnboarding = !memory.onboardingCompleted && memory.activeProfileType == 'A';

    if (isOnboarding) {
      return """
You are the YONO SBI 2.0 Onboarding Agent, a guided conversational AI assistant.
Your ONLY goal is to help Rohan complete account opening onboarding.
The onboarding flow has 7 steps:
1. Full Name: Ask the user for their full name. Acknowledge it when provided.
2. Mobile Number: Ask the user for their 10-digit mobile number.
3. PAN Verification: Ask for their 10-character PAN number. When provided, call `start_kyc(step: "pan", user_confirmed: true)`.
4. Aadhaar Verification: Ask for their 12-digit Aadhaar number. When provided, call `start_kyc(step: "aadhaar", user_confirmed: true)`.
5. Permanent Address: Ask for their permanent address.
6. Video KYC: Ask them to start Video KYC. Call `start_kyc(step: "video_kyc", user_confirmed: true)` when they agree.
7. UPI Activation: Ask them to configure their VPA. Call `activate_upi(vpa: "preferred_vpa")` to complete.

BEHAVIOR RULES:
- Ask short, guided questions. Do not ask for multiple things at once.
- Advance exactly one step at a time.
- If onboarding is complete, congratulate the user and instruct them to proceed to banking.
- Speak in a friendly Hinglish/English blend.
""";
    } else {
      String signalContext = signals.summaryForAgent;
      if (memory.lastDetectedSignal != null) {
        final timeDiff = DateTime.now().difference(memory.lastDetectedSignal!.timestamp);
        if (timeDiff.inMinutes < 60) {
          signalContext += "\nNote: You recently addressed the '${memory.lastDetectedSignal!.key}' signal. Avoid repeating the exact suggestion unless the user specifically asks.";
        }
      }

      return """
You are the YONO SBI 2.0 Banking Agent, a proactive and smart conversational banking assistant.
You speak in a friendly blend of English and Hindi (Hinglish). Keep response style banking-like, concise, and professional.

Active Financial Signals Detected by PatternEngine:
$signalContext

USER PROFILE MEMORY:
- Primary Goal: ${memory.primaryGoal}
- Risk Level: ${memory.riskLevel}
- User Preference Summary: ${memory.userPreferenceSummary}
- Last Executed Tool: ${memory.lastExecutedTool}
- Action History: ${memory.actionHistory.join(", ")}

YOUR TOOLS:
1. transfer_money(recipient, amount, reason): Use this when the user asks to send or transfer money.
2. move_to_fd(amount, reason): Use this to transfer idle savings balance to Fixed Deposit.
3. resume_sip(reason): Use this to resume a missed Mutual Fund SIP investment.
4. create_goal(name, target_amount): Use this to create a new financial goal.
5. log_insight(category, observation, reason): Use this to log a spending/saving alert or insight card.

BEHAVIOR RULES:
- Proactively suggest the next best action based on the active financial signals.
- Use the memory context to tailor your responses.
- Explain briefly what you are doing before executing a tool call.
""";
    }
  }

  List<Map<String, dynamic>> _getToolDeclarations() {
    final memory = _ref.read(agentMemoryProvider);
    final isOnboarding = !memory.onboardingCompleted && memory.activeProfileType == 'A';

    if (isOnboarding) {
      return [
        {
          'name': 'update_profile_info',
          'description': 'Updates user profile information such as name, mobile number, or permanent address.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'name': {'type': 'STRING', 'description': 'Full name of the user (e.g. Rohan)'},
              'mobile_number': {'type': 'STRING', 'description': '10-digit mobile number of the user'},
              'address': {'type': 'STRING', 'description': 'Permanent address of the user'}
            },
            'required': []
          }
        },
        {
          'name': 'start_kyc',
          'description': 'Advances user KYC step verification sequentially.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'step': {'type': 'STRING', 'description': 'Step to verify: "pan", "aadhaar", or "video_kyc"'},
              'user_confirmed': {'type': 'BOOLEAN', 'description': 'If user confirmed to initiate the KYC step'}
            },
            'required': ['step', 'user_confirmed']
          }
        },
        {
          'name': 'activate_upi',
          'description': 'Activates UPI services for the current user.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'vpa': {'type': 'STRING', 'description': 'Preferred VPA/UPI ID, e.g. rohan@sbi'}
            },
            'required': ['vpa']
          }
        }
      ];
    } else {
      return [
        {
          'name': 'transfer_money',
          'description': 'Executes a direct money transfer to a recipient.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'recipient': {'type': 'STRING', 'description': 'Who is receiving the money'},
              'amount': {'type': 'NUMBER', 'description': 'Amount to send'},
              'reason': {'type': 'STRING', 'description': 'Purpose of payment'}
            },
            'required': ['recipient', 'amount', 'reason']
          }
        },
        {
          'name': 'manage_sip',
          'description': 'Creates, updates, or cancels a Mutual Fund SIP.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'action': {'type': 'STRING', 'description': 'Action: "create", "update", or "cancel"'},
              'fund_name': {'type': 'STRING', 'description': 'Mutual fund name'},
              'amount': {'type': 'NUMBER', 'description': 'SIP amount (required for create/update)'}
            },
            'required': ['action', 'fund_name']
          }
        },
        {
          'name': 'manage_fd',
          'description': 'Opens, closes, or renews a Fixed Deposit.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'action': {'type': 'STRING', 'description': 'Action: "open", "close", or "renew"'},
              'title': {'type': 'STRING', 'description': 'FD Title, e.g. "Tax Saving FD"'},
              'amount': {'type': 'NUMBER', 'description': 'Principal amount (required for open)'},
              'auto_renew': {'type': 'BOOLEAN', 'description': 'Auto-renew option'}
            },
            'required': ['action', 'title']
          }
        },
        {
          'name': 'manage_loan',
          'description': 'Pays EMI or executes prepayment on a loan.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'action': {'type': 'STRING', 'description': 'Action: "pay_emi" or "prepay"'},
              'loan_id': {'type': 'STRING', 'description': 'Loan account ID, e.g. "loan_01"'},
              'amount': {'type': 'NUMBER', 'description': 'Amount to pay'}
            },
            'required': ['action', 'loan_id', 'amount']
          }
        },
        {
          'name': 'manage_budget',
          'description': 'Sets overall or category-wise budget limits.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'action': {'type': 'STRING', 'description': 'Action: "set_limit" or "set_category_limit"'},
              'category': {'type': 'STRING', 'description': 'Budget category (required for set_category_limit)'},
              'limit': {'type': 'NUMBER', 'description': 'Budget limit amount'}
            },
            'required': ['action', 'limit']
          }
        },
        {
          'name': 'create_goal',
          'description': 'Creates a new savings goal for the user.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'name': {'type': 'STRING', 'description': 'Name of the goal'},
              'target_amount': {'type': 'NUMBER', 'description': 'Target savings amount'}
            },
            'required': ['name', 'target_amount']
          }
        },
        {
          'name': 'log_insight',
          'description': 'Logs a spending alert or pattern flag to user Feed.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'category': {'type': 'STRING', 'description': 'Category of spending'},
              'observation': {'type': 'STRING', 'description': 'What was noticed'},
              'reason': {'type': 'STRING', 'description': 'Why this was noticed'}
            },
            'required': ['category', 'observation', 'reason']
          }
        }
      ];
    }
  }

  void _addMessageToUI(String sender, String text, {Map<String, dynamic>? toolCall, String? toolStatus, String? toolCallId}) {
    final memory = _ref.read(agentMemoryProvider);
    final profileType = _ref.read(profileTypeProvider);
    final isOnboarding = !memory.onboardingCompleted && profileType == 'A';

    if (isOnboarding) {
      _ref.read(onboardingChatProvider.notifier).addMessage(
            ChatMessage(sender: sender, text: text, timestamp: DateTime.now(), toolCall: toolCall, toolStatus: toolStatus, toolCallId: toolCallId),
          );
    } else {
      _ref.read(bankingChatProvider.notifier).addMessage(
            ChatMessage(sender: sender, text: text, timestamp: DateTime.now(), toolCall: toolCall, toolStatus: toolStatus, toolCallId: toolCallId),
          );
    }
  }

  Future<void> sendMessage(String text) async {
    final agentState = _ref.read(agentStateProvider.notifier);
    _addMessageToUI('user', text);
    state = state.copyWith(isThinking: true);
    agentState.setStatus(AgentStatus.thinking);

    if (state.mode == AIServiceMode.live) {
      _liveService.sendMessage(text);
      return;
    }

    if (state.mode == AIServiceMode.rest) {
      await _sendRestMessage(text);
      return;
    }

    if (state.mode == AIServiceMode.simulated) {
      await _sendSimulatedMessage(text);
      return;
    }
  }

  Future<void> _sendRestMessage(String text) async {
    final apiKey = _ref.read(geminiApiKeyProvider);
    final sysPrompt = _buildSystemPrompt();
    final tools = _getToolDeclarations();
    final agentState = _ref.read(agentStateProvider.notifier);

    _restHistory.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });

    final modelConfig = _ref.read(aiModelConfigProvider);
    try {
      final response = await _restService.generateContent(
        apiKey: apiKey,
        systemInstruction: sysPrompt,
        contents: _restHistory,
        tools: tools,
        model: modelConfig.restModel,
      );

      final candidate = response['candidates']?[0];
      final message = candidate?['content'];
      if (message != null) {
        _restHistory.add(message);
        final parts = message['parts'] as List;
        for (var part in parts) {
          if (part['text'] != null) {
            agentState.setLastAgentMessage(part['text']);
            _addMessageToUI('agent', part['text']);
            _ref.read(voiceServiceProvider).speak(part['text']);
          }
          if (part['functionCall'] != null) {
            final funcCall = part['functionCall'];
            final name = funcCall['name'];
            final args = Map<String, dynamic>.from(funcCall['args'] ?? {});
            
            Map<String, dynamic> output;

            if (name == 'update_profile_info') {
              // Auto-approve profile updates for a smooth conversational flow
              output = await _executeTool(name, args);
              _addMessageToUI('tool', "Agent updated profile info ✅", toolCall: {'output': output});
            } else {
              final toolCallId = 'rest_call_${DateTime.now().millisecondsSinceEpoch}';
              final completer = Completer<bool>();
              _pendingConfirmations[toolCallId] = completer;

              _addMessageToUI(
                'system',
                "Agent wants to execute tool: $name",
                toolCall: {'name': name, 'args': args},
                toolStatus: 'pending',
                toolCallId: toolCallId,
              );

              final approved = await completer.future;

              if (approved) {
                output = await _executeTool(name, args);
                if (output['status'] == 'failed' || output['status'] == 'error') {
                  final reason = output['reason'] ?? 'Tool call failed';
                  _addMessageToUI('tool', "Agent tool $name failed ❌: $reason", toolCall: {'output': output});
                } else {
                  _addMessageToUI('tool', "Agent completed $name ✅", toolCall: {'output': output});
                }
              } else {
                output = {'status': 'failed', 'reason': 'User rejected/cancelled tool execution.'};
                _addMessageToUI('tool', "Agent tool execution for $name was cancelled by user ❌", toolCall: {'output': output});
              }
            }

            // Send tool response to REST in the next call
            _restHistory.add({
              'role': 'tool',
              'parts': [
                {
                  'functionResponse': {
                    'name': name,
                    'response': {'output': output}
                  }
                }
              ]
            });

            // Trigger follow up generation
            final followUpResponse = await _restService.generateContent(
              apiKey: apiKey,
              systemInstruction: sysPrompt,
              contents: _restHistory,
              tools: tools,
              model: modelConfig.restModel,
            );
            final followUpCandidate = followUpResponse['candidates']?[0];
            final followUpMsg = followUpCandidate?['content'];
            if (followUpMsg != null) {
              _restHistory.add(followUpMsg);
              final fuParts = followUpMsg['parts'] as List;
              for (var fuPart in fuParts) {
                if (fuPart['text'] != null) {
                  agentState.setLastAgentMessage(fuPart['text']);
                  _addMessageToUI('agent', fuPart['text']);
                  _ref.read(voiceServiceProvider).speak(fuPart['text']);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("REST error: $e");
      state = state.copyWith(mode: AIServiceMode.simulated, error: "REST API failed: $e. Switched to Simulation Mode.");
      agentState.setConnectionStatus("disconnected");
      agentState.updateTransportInfo(
        transportType: "simulated",
        webSocketStatus: "error",
        restStatus: "error",
        decisionSource: "Local Rule Engine",
      );
      await _sendSimulatedMessage(text);
      return;
    } finally {
      state = state.copyWith(isThinking: false);
      if (agentState.state.status != AgentStatus.error) {
        agentState.setStatus(AgentStatus.idle);
      }
    }
  }

  // High-fidelity local simulation mode when offline or no API Key
  Future<void> _sendSimulatedMessage(String text) async {
    final agentState = _ref.read(agentStateProvider.notifier);
    await Future.delayed(const Duration(milliseconds: 800)); // Initial thinking delay

    final query = text.toLowerCase();
    String agentInitialText = "";
    String agentFinalText = "";
    String? triggerTool;
    Map<String, dynamic> toolArgs = {};

    final profile = _ref.read(userProfileProvider);
    final profileType = _ref.read(profileTypeProvider);
    final memory = _ref.read(agentMemoryProvider);
    final isOnboarding = !memory.onboardingCompleted && profileType == 'A';

    if (isOnboarding) {
      // Rohan Onboarding Chat Simulation
      if (profile.name.isEmpty) {
        _ref.read(userProfileProvider.notifier).updateName(text);
        agentInitialText = "Name validation protocol complete.";
        agentFinalText = "Namaste $text! Name saved. Now please enter your 10-digit mobile number.";
      } else if (profile.mobileNumber.isEmpty) {
        _ref.read(userProfileProvider.notifier).updateMobileNumber(text);
        agentInitialText = "Registering mobile connection details...";
        agentFinalText = "Got your mobile number. Now please enter your 10-character PAN card number to initiate identity check.";
      } else if (profile.kycStep == 'none') {
        agentInitialText = "Understood. PAN Verification check initialise kar raha hun. API parameters fetch ho rahe hain...";
        triggerTool = "start_kyc";
        toolArgs = {'step': 'pan', 'user_confirmed': true};
        agentFinalText = "PAN verified successfully! ✅ 25 SBI Coins earned. Next step, please enter your 12-digit Aadhaar number for secure verification.";
      } else if (profile.kycStep == 'pan') {
        agentInitialText = "Aadhaar secure verification loop starts... Checking links in background.";
        triggerTool = "start_kyc";
        toolArgs = {'step': 'aadhaar', 'user_confirmed': true};
        agentFinalText = "Aadhaar link verified! ✅ 25 SBI Coins earned. Now, please enter your permanent address.";
      } else if (profile.kycStep == 'aadhaar' && profile.address.isEmpty) {
        _ref.read(userProfileProvider.notifier).updateAddress(text);
        agentInitialText = "Address validation started...";
        agentFinalText = "Address saved. We are ready for Video KYC. Tap the button below to start camera facial checks.";
      } else if (profile.kycStep == 'video_kyc') {
        agentInitialText = "Opening secure Video KYC session interface... Agent online.";
        triggerTool = "start_kyc";
        toolArgs = {'step': 'video_kyc', 'user_confirmed': true};
        agentFinalText = "Video KYC verification completed! 🎉 50 SBI Coins awarded. Finally, let's setup your UPI VPA to enable digital payments. Enter your preferred VPA (e.g. name@sbi).";
      } else {
        agentInitialText = "Activating UPI quick pay protocol... Allocating primary VPA $text.";
        triggerTool = "activate_upi";
        toolArgs = {'vpa': text};
        agentFinalText = "UPI set up complete! ✅ VPA: $text is active. 30 SBI Coins earned. Welcome to YONO SBI 2.0. You are ready to enter Banking Mode!";
      }
    } else {
      // Regex Matchers for Banking Simulation
      final matchCreateSip = RegExp(r'(?:create|start|initiate)\s+(?:sip|mutual fund)\s+(?:of|for)?\s*₹?(\d+)(?:\s+in\s+([a-zA-Z0-9\s]+))?', caseSensitive: false).firstMatch(query);
      final matchUpdateSip = RegExp(r'(?:update|change|modify)\s+(?:sip)\s+(?:of|for|amount to)?\s*₹?(\d+)(?:\s+(?:in|for)\s+([a-zA-Z0-9\s]+))?', caseSensitive: false).firstMatch(query);
      final matchCancelSip = RegExp(r'(?:cancel|stop|close)\s+(?:sip|mutual fund)\s+(?:in|for)?\s*([a-zA-Z0-9\s]+)', caseSensitive: false).firstMatch(query);
      
      final matchOpenFd = RegExp(r'(?:open|create|start)\s+(?:fd|fixed deposit)\s+(?:of|for)?\s*₹?(\d+)', caseSensitive: false).firstMatch(query);
      final matchCloseFd = RegExp(r'(?:close|cancel|withdraw)\s+(?:fd|fixed deposit)\s+(?:named|for)?\s*([a-zA-Z0-9\s\-\(\)]+)', caseSensitive: false).firstMatch(query);
      
      final matchPrepayLoan = RegExp(r'(?:prepay|part pay)\s+(?:loan)\s+(?:of|with)?\s*₹?(\d+)', caseSensitive: false).firstMatch(query);
      final matchPayEmi = RegExp(r'(?:pay|debit)\s+(?:emi|loan emi)(?:\s+(?:of|for)?\s*₹?(\d+))?', caseSensitive: false).firstMatch(query);
      
      final matchSetBudget = RegExp(r'(?:set|change)\s+(?:budget limit|limit|budget)\s+(?:to)?\s*₹?(\d+)', caseSensitive: false).firstMatch(query);
      final matchSetCategoryBudget = RegExp(r'(?:set|change)\s+([a-zA-Z\s]+)\s+(?:budget|limit)\s+(?:to)?\s*₹?(\d+)', caseSensitive: false).firstMatch(query);

      if (matchCreateSip != null) {
        final amount = double.parse(matchCreateSip.group(1)!);
        final fundName = matchCreateSip.group(2)?.trim() ?? 'SBI Bluechip Fund';
        agentInitialText = "SBI SIP setup utility active. Main $fundName mein ₹${amount.toStringAsFixed(0)} ki monthly SIP configure kar raha hun.";
        triggerTool = "manage_sip";
        toolArgs = {'action': 'create', 'fund_name': fundName, 'amount': amount};
        agentFinalText = "$fundName mein ₹${amount.toStringAsFixed(0)} ki monthly SIP register ho chuki hai! 🎉 Streak status: Active.";
      } else if (matchUpdateSip != null) {
        final amount = double.parse(matchUpdateSip.group(1)!);
        final fundName = matchUpdateSip.group(2)?.trim() ?? 'SBI Bluechip Fund';
        agentInitialText = "SIP amount modify request. $fundName ki monthly limit update karke ₹${amount.toStringAsFixed(0)} karne ka setup chal raha hai.";
        triggerTool = "manage_sip";
        toolArgs = {'action': 'update', 'fund_name': fundName, 'amount': amount};
        agentFinalText = "SIP modified successfully! ✅ $fundName ki monthly investment ab ₹${amount.toStringAsFixed(0)} hai.";
      } else if (matchCancelSip != null) {
        final fundName = matchCancelSip.group(1)!.trim();
        agentInitialText = "SIP cancellation initialization. $fundName standard auto-debit payments cancel karne ka request process ho raha hai.";
        triggerTool = "manage_sip";
        toolArgs = {'action': 'cancel', 'fund_name': fundName};
        agentFinalText = "SIP cancelled! ❌ $fundName investments close kar di gayi hain.";
      } else if (matchOpenFd != null) {
        final amount = double.parse(matchOpenFd.group(1)!);
        if (profile.balance < amount) {
          agentInitialText = "Checking balance for FD request...";
          agentFinalText = "Oops! Fixed Deposit open karne ke liye ₹${amount.toStringAsFixed(0)} balance insufficient hai.";
        } else {
          agentInitialText = "Savings surplus review. ₹${amount.toStringAsFixed(0)} se secure Fixed Deposit initialize kar raha hun at 7.2% secure interest rate.";
          triggerTool = "manage_fd";
          toolArgs = {'action': 'open', 'amount': amount, 'title': 'Standard FD'};
          agentFinalText = "Fixed Deposit open ho chuka hai! ✅ ₹${amount.toStringAsFixed(0)} lock kar diye gaye hain. interest rate: 7.20% p.a.";
        }
      } else if (matchCloseFd != null) {
        final title = matchCloseFd.group(1)!.trim();
        agentInitialText = "Fixed Deposit closure request. $title ka mature closure initialize kar raha hun.";
        triggerTool = "manage_fd";
        toolArgs = {'action': 'close', 'title': title};
        agentFinalText = "Fixed Deposit close ho gaya! Principal amount savings balance mein add ho chuka hai.";
      } else if (matchPrepayLoan != null) {
        final amount = double.parse(matchPrepayLoan.group(1)!);
        if (profile.balance < amount) {
          agentInitialText = "Loan prepayment balance verification...";
          agentFinalText = "Outstanding prepayment ke liye ₹${amount.toStringAsFixed(0)} sufficient balance nahi hai.";
        } else {
          agentInitialText = "Loan prepayment procedure start. ₹${amount.toStringAsFixed(0)} amount deduct karke outstanding balance reduce kar raha hun.";
          triggerTool = "manage_loan";
          toolArgs = {'action': 'prepay', 'loan_id': 'loan_01', 'amount': amount};
          agentFinalText = "Prepayment complete! Home Loan outstanding balance is reduced by ₹${amount.toStringAsFixed(0)}. ₹1.2L projected interest saved.";
        }
      } else if (matchPayEmi != null) {
        final amount = matchPayEmi.group(1) != null ? double.parse(matchPayEmi.group(1)!) : 28500.0;
        if (profile.balance < amount) {
          agentInitialText = "EMI automated debit check...";
          agentFinalText = "Monthly EMI payment ke liye ₹${amount.toStringAsFixed(0)} available nahi hai.";
        } else {
          agentInitialText = "EMI Auto-Debit processing. Paying installment of ₹${amount.toStringAsFixed(0)}.";
          triggerTool = "manage_loan";
          toolArgs = {'action': 'pay_emi', 'loan_id': 'loan_01', 'amount': amount};
          agentFinalText = "EMI payment successful! ✅ ₹${amount.toStringAsFixed(0)} paid towards your Home Loan.";
        }
      } else if (matchSetBudget != null) {
        final limit = double.parse(matchSetBudget.group(1)!);
        agentInitialText = "Wallet monthly limit reconfiguration processing...";
        triggerTool = "manage_budget";
        toolArgs = {'action': 'set_limit', 'limit': limit};
        agentFinalText = "Overall budget limit updated to ₹${limit.toStringAsFixed(0)} successfully!";
      } else if (matchSetCategoryBudget != null) {
        final category = matchSetCategoryBudget.group(1)!.trim();
        final limit = double.parse(matchSetCategoryBudget.group(2)!);
        agentInitialText = "$category sub-limit category threshold update initialize...";
        triggerTool = "manage_budget";
        toolArgs = {'action': 'set_category_limit', 'category': category, 'limit': limit};
        agentFinalText = "$category limit set to ₹${limit.toStringAsFixed(0)}. Spending analyzer active.";
      } else if (query.contains('send') || query.contains('bhej') || query.contains('transfer') || query.contains('pay')) {
        double amount = 2000;
        String recipient = "Mom";
        final matchAmount = RegExp(r'\d+').firstMatch(query);
        if (matchAmount != null) {
          amount = double.parse(matchAmount.group(0)!);
        }
        if (query.contains('sourabh') || query.contains('rohan')) {
          recipient = "Sourabh";
        }

        if (profile.balance < amount) {
          agentInitialText = "Checking account balance for ₹${amount.toStringAsFixed(0)} transfer to $recipient...";
          agentFinalText = "Oops! Aapka balance ₹${profile.balance.toStringAsFixed(2)} insufficient hai. Transfer execute nahi kiya ja sakta.";
        } else {
          agentInitialText = "Theek hai! ₹${amount.toStringAsFixed(0)} $recipient ko send karne ka request process kar raha hun.";
          triggerTool = "transfer_money";
          toolArgs = {'recipient': recipient, 'amount': amount, 'reason': 'Direct Pay from AI Chat'};
          
          final updatedBalance = profile.balance - amount;
          agentFinalText = "Transfer complete! ✅ ₹${amount.toStringAsFixed(0)} successfully transferred to $recipient. Your updated balance is ₹${updatedBalance.toStringAsFixed(2)}.";
        }
      } else if (query.contains('balance') || query.contains('paisa') || query.contains('khata')) {
        agentInitialText = "Account profile checking in progress...";
        agentFinalText = "Aapka savings account balance ₹${profile.balance.toStringAsFixed(2)} hai. Status: Safe zone.";
      } else if (query.contains('health') || query.contains('spending') || query.contains('story')) {
        agentInitialText = "Analyzing financial statement records and streaks...";
        agentFinalText = "Aapka Financial Health score: 82/100 (Safe). Detected anomaly: June MF SIP was missed. Suggestion: Tap 'Products' or type 'Resume SIP' to restore your SIP and secure active coins.";
      } else {
        agentInitialText = "Main aapka check balance details provide kar sakta hun, Fixed Deposit start kar sakta hun, Goal boost ya direct money transfer execute kar sakta hun. Kaise help karu?";
      }
    }

    // Phase 1: Output agent's initial thoughts/intent
    if (agentInitialText.isNotEmpty) {
      agentState.setLastAgentMessage(agentInitialText);
      _addMessageToUI('agent', agentInitialText);
      _ref.read(voiceServiceProvider).speak(agentInitialText);
    }

    // Phase 2: Execute simulated tool calling sequence
    if (triggerTool != null) {
      await Future.delayed(const Duration(milliseconds: 600));
      final toolCallId = 'sim_call_${DateTime.now().millisecondsSinceEpoch}';
      final completer = Completer<bool>();
      _pendingConfirmations[toolCallId] = completer;

      _addMessageToUI(
        'system',
        "Agent wants to execute tool (simulated): $triggerTool",
        toolCall: {'name': triggerTool, 'args': toolArgs},
        toolStatus: 'pending',
        toolCallId: toolCallId,
      );

      final approved = await completer.future;

      if (approved) {
        final output = await _executeTool(triggerTool, toolArgs);
        if (output['status'] == 'failed' || output['status'] == 'error') {
          final reason = output['reason'] ?? 'Tool call failed';
          _addMessageToUI('tool', "Agent tool $triggerTool failed ❌: $reason", toolCall: {'output': output});
        } else {
          _addMessageToUI('tool', "Agent completed $triggerTool ✅", toolCall: {'output': output});
        }

        // Phase 3: Output final response reflecting the updated state
        if (agentFinalText.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 600));
          agentState.setLastAgentMessage(agentFinalText);
          _addMessageToUI('agent', agentFinalText);
          _ref.read(voiceServiceProvider).speak(agentFinalText);
        }
      } else {
        _addMessageToUI('tool', "Agent tool execution for $triggerTool was cancelled by user ❌", toolCall: {'output': {'status': 'failed'}});
        const cancelReply = "Theek hai, main target transaction cancel kar raha hun. Budget or investments modify nahi kiye gaye hain. Aur kuch help chahiye?";
        agentState.setLastAgentMessage(cancelReply);
        _addMessageToUI('agent', cancelReply);
        _ref.read(voiceServiceProvider).speak(cancelReply);
      }
    } else {
      // Direct reply without tool execution
      if (agentFinalText.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 400));
        agentState.setLastAgentMessage(agentFinalText);
        _addMessageToUI('agent', agentFinalText);
        _ref.read(voiceServiceProvider).speak(agentFinalText);
      }
    }

    state = state.copyWith(isThinking: false);
    if (agentState.state.status != AgentStatus.error) {
      agentState.setStatus(AgentStatus.idle);
    }
  }

  Future<void> simulateAgentResponse(String text) async {
    final agentState = _ref.read(agentStateProvider.notifier);
    state = state.copyWith(isThinking: true);
    agentState.setStatus(AgentStatus.thinking);
    
    // Simulate short thinking delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    state = state.copyWith(isThinking: false);
    agentState.setLastAgentMessage(text);
    _addMessageToUI('agent', text);
    
    // Speak the response
    await _ref.read(voiceServiceProvider).speak(text);
    
    if (agentState.state.status != AgentStatus.error) {
      agentState.setStatus(AgentStatus.idle);
    }
  }

  void _triggerProactiveWelcome() async {
    final profile = _ref.read(userProfileProvider);
    final memory = _ref.read(agentMemoryProvider);
    final txs = _ref.read(transactionsProvider);
    final goals = _ref.read(goalsProvider);
    final recs = _ref.read(recommendationsProvider);
    final timeline = _ref.read(timelineProvider.notifier);
    final memoryNotifier = _ref.read(agentMemoryProvider.notifier);

    // 1. Greet the user once per session or profile swap
    if (memory.lastWelcomeMessage == null || memory.lastSeenProfile != profile.name) {
      final greeting = RetentionRules.getGreeting(profile.name, profile.name == 'Rohan' ? 'A' : 'B', memory.lastWelcomeMessage);
      
      memoryNotifier.updateProactiveState(
        lastWelcomeMessage: greeting,
        lastSeenProfile: profile.name,
      );

      timeline.log(
        type: TimelineEntryType.insight,
        title: 'Agent Welcome Prompted',
        description: greeting,
        status: TimelineEntryStatus.info,
      );

      await Future.delayed(const Duration(milliseconds: 1000));
      simulateAgentResponse(greeting);
      return;
    }

    // 2. Proactively alert on a critical Next Best Action if not spammed
    final action = ProactiveAgentEngine.determineNextBestAction(
      profile: profile,
      transactions: txs,
      goals: goals,
      memory: memory,
      recommendations: recs,
    );

    if (action.type != NextBestActionType.healthSummary && action.type != NextBestActionType.goalNudge) {
      if (memory.lastProactiveSuggestion != action.id) {
        memoryNotifier.updateProactiveState(
          lastProactiveSuggestion: action.id,
          lastRecommendationTimestamp: DateTime.now().millisecondsSinceEpoch,
        );

        timeline.log(
          type: TimelineEntryType.recommendation,
          title: 'Agent Proactive Alert: ${action.title}',
          description: '${action.subtitle} (Reason: ${action.aiReason})',
          status: TimelineEntryStatus.info,
        );

        final alertText = "SBI Proactive Alert: I noticed ${action.title.toLowerCase()}. ${action.subtitle}";
        await Future.delayed(const Duration(milliseconds: 1200));
        simulateAgentResponse(alertText);
      }
    }
  }

  void updateApiKey(String key) {
    _ref.read(geminiApiKeyProvider.notifier).state = key;
    _initializeService();
  }

  @override
  void dispose() {
    _liveService.disconnect();
    super.dispose();
  }
}
