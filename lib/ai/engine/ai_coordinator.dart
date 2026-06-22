import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbiv2/ai/engine/gemini_live_service.dart';
import 'package:sbiv2/ai/engine/gemini_rest_service.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';
import 'package:sbiv2/ai/tools/tool_dispatcher.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';

// API Key provider (can be updated in UI)
final geminiApiKeyProvider = StateProvider<String>((ref) {
  // Try to load from environment first, otherwise empty default (which triggers high-fidelity Mock simulation)
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

final aiCoordinatorProvider = StateNotifierProvider<AICoordinator, AICoordinatorState>((ref) {
  return AICoordinator(ref);
});

class AICoordinator extends StateNotifier<AICoordinatorState> {
  final Ref _ref;
  final GeminiLiveService _liveService = GeminiLiveService();
  final GeminiRestService _restService = GeminiRestService();

  // Keep conversation history for REST API & Simulated fallback
  final List<Map<String, dynamic>> _restHistory = [];

  AICoordinator(this._ref)
      : super(AICoordinatorState(
          mode: AIServiceMode.simulated,
          isConnecting: false,
          isThinking: false,
        )) {
    // Listen to profile switches to re-initiate
    _ref.listen(profileTypeProvider, (previous, next) {
      _restHistory.clear();
      _initializeService();
    });

    _initializeService();
  }

  Future<void> _initializeService() async {
    final apiKey = _ref.read(geminiApiKeyProvider);
    if (apiKey.isEmpty) {
      state = state.copyWith(mode: AIServiceMode.simulated, error: "No API Key. Running in high-fidelity mock simulation mode.");
      return;
    }

    state = state.copyWith(isConnecting: true, error: null);

    final sysPrompt = _buildSystemPrompt();
    final tools = _getToolDeclarations();

    // Try Live WebSockets first
    _liveService.disconnect();
    _liveService.onConnected = () {
      state = state.copyWith(mode: AIServiceMode.live, isConnecting: false, isThinking: false);
    };
    _liveService.onMessageReceived = (text) {
      state = state.copyWith(isThinking: false);
      _addMessageToUI('agent', text);
    };
    _liveService.onToolCallReceived = (name, args, callId) async {
      state = state.copyWith(isThinking: true);
      _addMessageToUI('system', "Agent executing tool: $name...", toolCall: {'name': name, 'args': args});
      
      final output = await ToolDispatcher.dispatch(_ref, name, args);
      
      _addMessageToUI('tool', "Agent completed $name ✅", toolCall: {'output': output});
      _liveService.sendToolResponse(callId, output);
      state = state.copyWith(isThinking: false);
    };
    _liveService.onError = (err) {
      if (kDebugMode) print("Live error: $err");
    };
    _liveService.onDisconnected = () {
      if (state.mode == AIServiceMode.live) {
        // Switch to REST fallback
        state = state.copyWith(mode: AIServiceMode.rest, error: "WebSocket disconnected. Switched to REST fallback.");
      }
    };

    final connected = await _liveService.connect(
      apiKey: apiKey,
      systemInstruction: sysPrompt,
      tools: tools,
    );

    if (!connected) {
      // Try REST
      state = state.copyWith(mode: AIServiceMode.rest, isConnecting: false);
    }
  }

  String _buildSystemPrompt() {
    final profile = _ref.read(userProfileProvider);
    final txs = _ref.read(transactionsProvider);
    final signals = PatternEngine.analyze(profile, txs);

    return """
You are the YONO SBI 2.0 Agent, a proactive, helpful, and smart conversational AI banking assistant. 
You can talk to the user and perform banking operations on their behalf.
You speak in a blend of English and Hindi (Hinglish), keeping a friendly and reassuring tone.
Always start the conversation appropriate to the user's KYC state and account type.

Active Financial Signals Detected by PatternEngine (inject this context into your decisions):
${signals.summaryForAgent}

YOUR TOOLS:
1. qualify_lead: Use this when the user is Rohan (Naya Customer) and gives their name, income bracket (e.g. 0-5 Lakhs, 5-10 Lakhs, etc.), and banking need.
2. initiate_kyc_step: Call this during Rohan's onboarding to do PAN, Aadhaar, or Video KYC verification. You must do this sequentially.
3. activate_upi: Call this when Rohan selects a UPI VPA (like rohan@sbi) to activate UPI.
4. surface_recommendation: Call this to add a custom recommendation for the user.
5. log_spending_insight: Call this to add a spending alert or anomaly to their story feed.
6. boost_goal_savings: Call this to transfer money from balance to a savings goal (max ₹500, once per session).
7. execute_transfer: Call this when the user asks to send/transfer money (e.g. "mom ko 2000 bhej do" -> recipient: "mom", amount: 2000).
8. suggest_service_activation: Call this to activate a digital banking service (like Fixed Deposit, SIP, Mutual Funds, etc.).

If KYC is not complete, focus on getting the customer onboarded. 
If KYC is complete, look at active signals like missedRecurring (missed SIP) or idleBalance (large balance in savings) and suggest taking action, executing transfers, or setting up FDs.
Keep your reasoning short and always explain why you are running a tool in chat.
""";
  }

  List<Map<String, dynamic>> _getToolDeclarations() {
    return [
      {
        'name': 'qualify_lead',
        'description': 'Updates user profile with income bracket, banking need, and existing bank.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'income_bracket': {'type': 'STRING', 'description': 'Income range (e.g. 0-5 Lakhs, 5-10 Lakhs, 10+ Lakhs)'},
            'banking_need': {'type': 'STRING', 'description': 'E.g. Savings & UPI, Wealth Creation, Loans'},
            'existing_bank': {'type': 'STRING', 'description': 'E.g. HDFC, ICICI, None'}
          },
          'required': ['income_bracket', 'banking_need', 'existing_bank']
        }
      },
      {
        'name': 'initiate_kyc_step',
        'description': 'Advances user KYC step conversational verification.',
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
      },
      {
        'name': 'surface_recommendation',
        'description': 'Surfaces a personalized financial recommendation card.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'recommendation_id': {'type': 'STRING', 'description': 'E.g. rec_fd, rec_sip'},
            'reason': {'type': 'STRING', 'description': 'Explain why the recommendation is surfaced.'}
          },
          'required': ['recommendation_id', 'reason']
        }
      },
      {
        'name': 'log_spending_insight',
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
      },
      {
        'name': 'boost_goal_savings',
        'description': 'Saves money from balance into a specific savings goal (max ₹500 limit).',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'goal_id': {'type': 'STRING', 'description': 'Goal identifier'},
            'amount': {'type': 'NUMBER', 'description': 'Amount to save (max 500)'},
            'reason': {'type': 'STRING', 'description': 'Reason for boosting'}
          },
          'required': ['goal_id', 'amount', 'reason']
        }
      },
      {
        'name': 'execute_transfer',
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
        'name': 'suggest_service_activation',
        'description': 'Recommends and activates a digital banking service.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'service_id': {'type': 'STRING', 'description': 'Service identifier'},
            'reason': {'type': 'STRING', 'description': 'Why this service is suggested'}
          },
          'required': ['service_id', 'reason']
        }
      }
    ];
  }

  void _addMessageToUI(String sender, String text, {Map<String, dynamic>? toolCall}) {
    final profile = _ref.read(userProfileProvider);
    // Route message to correct chat provider based on current KYC status (onboarding vs general banking chat)
    if (!profile.kycComplete && _ref.read(profileTypeProvider) == 'A') {
      _ref.read(onboardingChatProvider.notifier).addMessage(
            ChatMessage(sender: sender, text: text, timestamp: DateTime.now(), toolCall: toolCall),
          );
    } else {
      _ref.read(bankingChatProvider.notifier).addMessage(
            ChatMessage(sender: sender, text: text, timestamp: DateTime.now(), toolCall: toolCall),
          );
    }
  }

  Future<void> sendMessage(String text) async {
    _addMessageToUI('user', text);
    state = state.copyWith(isThinking: true);

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

    _restHistory.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });

    try {
      final response = await _restService.generateContent(
        apiKey: apiKey,
        systemInstruction: sysPrompt,
        contents: _restHistory,
        tools: tools,
      );

      final candidate = response['candidates']?[0];
      final message = candidate?['content'];
      if (message != null) {
        _restHistory.add(message);
        final parts = message['parts'] as List;
        for (var part in parts) {
          if (part['text'] != null) {
            _addMessageToUI('agent', part['text']);
          }
          if (part['functionCall'] != null) {
            final funcCall = part['functionCall'];
            final name = funcCall['name'];
            final args = Map<String, dynamic>.from(funcCall['args'] ?? {});
            
            _addMessageToUI('system', "Agent executing tool: $name...", toolCall: {'name': name, 'args': args});
            final output = await ToolDispatcher.dispatch(_ref, name, args);
            _addMessageToUI('tool', "Agent completed $name ✅", toolCall: {'output': output});

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
            );
            final followUpCandidate = followUpResponse['candidates']?[0];
            final followUpMsg = followUpCandidate?['content'];
            if (followUpMsg != null) {
              _restHistory.add(followUpMsg);
              final fuParts = followUpMsg['parts'] as List;
              for (var fuPart in fuParts) {
                if (fuPart['text'] != null) {
                  _addMessageToUI('agent', fuPart['text']);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("REST error: $e");
      state = state.copyWith(mode: AIServiceMode.simulated, error: "REST API failed: $e. Switched to Simulation Mode.");
      await _sendSimulatedMessage(text);
      return;
    } finally {
      state = state.copyWith(isThinking: false);
    }
  }

  // High-fidelity local simulation mode when offline or no API Key
  Future<void> _sendSimulatedMessage(String text) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate thinking lag

    final query = text.toLowerCase();
    String reply = "";
    String? triggerTool;
    Map<String, dynamic> toolArgs = {};

    final profile = _ref.read(userProfileProvider);

    if (!profile.kycComplete && _ref.read(profileTypeProvider) == 'A') {
      // Rohan Onboarding Chat Simulation
      if (profile.incomeBracket.isEmpty) {
        // Qualify lead
        reply = "Aapka details note kar liya hai! Main SBI Quick Savings account open karne ke liye lead qualify kar raha hun.";
        triggerTool = "qualify_lead";
        toolArgs = {
          'income_bracket': '5-10 Lakhs',
          'banking_need': 'Savings & UPI',
          'existing_bank': 'None',
        };
      } else if (profile.kycStep == 'none') {
        reply = "Aapke qualified details confirm ho gaye hain. Ab PAN verification start karte hain. Kya main verify karu?";
        triggerTool = "initiate_kyc_step";
        toolArgs = {'step': 'pan', 'user_confirmed': true};
      } else if (profile.kycStep == 'pan') {
        reply = "PAN verify ho gaya hai! Next step Aadhaar link karne ka hai. Kya verification verify kar dein?";
        triggerTool = "initiate_kyc_step";
        toolArgs = {'step': 'aadhaar', 'user_confirmed': true};
      } else if (profile.kycStep == 'aadhaar') {
        reply = "Aadhaar authentication green ho gaya! Final KYC verification ke liye Video KYC start karte hain. Confirm kijiye.";
        triggerTool = "initiate_kyc_step";
        toolArgs = {'step': 'video_kyc', 'user_confirmed': true};
      } else if (profile.kycStep == 'video_kyc') {
        reply = "KYC Complete! 🎉 Ab quick transfers ke liye UPI set karte hain. Preferred UPI ID rohan@sbi set kar dein?";
        triggerTool = "activate_upi";
        toolArgs = {'vpa': 'rohan@sbi'};
      } else {
        reply = "Aapka SBI account fully ready hai! Pehla transfer karein ya savings goals set up karein?";
      }
    } else {
      // Sourabh / General Banking Assistant Chat Simulation
      if (query.contains('send') || query.contains('bhej') || query.contains('transfer') || query.contains('pay')) {
        // Extract amount and recipient
        double amount = 2000;
        String recipient = "Mom";
        final matchAmount = RegExp(r'\d+').firstMatch(query);
        if (matchAmount != null) {
          amount = double.parse(matchAmount.group(0)!);
        }
        if (query.contains('sourabh') || query.contains('rohan')) {
          recipient = "Sourabh";
        }

        reply = "Theek hai! ₹${amount.toStringAsFixed(0)} $recipient ko send karne ka request trigger kar raha hun.";
        triggerTool = "execute_transfer";
        toolArgs = {'recipient': recipient, 'amount': amount, 'reason': 'Direct Pay from AI Chat'};
      } else if (query.contains('sip') || query.contains('mutual fund') || query.contains('invest')) {
        reply = "June ka SIP resume karne ki priority recommendation compute ki hai. Bluechip fund SIP setup trigger karta hun.";
        triggerTool = "suggest_service_activation";
        toolArgs = {'service_id': 'srv_sip', 'reason': 'Resume June SIP - AI Insight'};
      } else if (query.contains('fd') || query.contains('fixed deposit') || query.contains('saving')) {
        reply = "Idle cash buffer detect kiya hai. ₹50,000 SBI Tax Savings FD activate kar raha hun, returns 7.2% secure.";
        triggerTool = "suggest_service_activation";
        toolArgs = {'service_id': 'srv_fd', 'reason': 'Allocate idle balance to FD'};
      } else if (query.contains('goal') || query.contains('save') || query.contains('boost')) {
        reply = "Dream Car goal boost kar raha hun with balance safety rules.";
        triggerTool = "boost_goal_savings";
        toolArgs = {'goal_id': 'goal_01', 'amount': 500, 'reason': 'AI Coach auto-boost'};
      } else if (query.contains('balance') || query.contains('paisa') || query.contains('khata')) {
        reply = "Aapka primary balance ₹${profile.balance.toStringAsFixed(2)} hai. Aapki savings account safe zone mein hai.";
      } else if (query.contains('health') || query.contains('spending') || query.contains('story')) {
        reply = "Aapka financial health score 82/100 hai! Ek anomaly check kiya gaya hai: Salary credit hone ke baad abhi tak Goal savings update nahi kiya hai. Goal boost ya FD set karne ki recommendation active hai.";
      } else {
        reply = "Main aapka statement analyze kar sakta hun, balance check, goal boost ya direct money transfer kar sakta hun. Kya trigger karun?";
      }
    }

    _addMessageToUI('agent', reply);

    if (triggerTool != null) {
      _addMessageToUI('system', "Agent executing tool (simulated): $triggerTool...", toolCall: {'name': triggerTool, 'args': toolArgs});
      await Future.delayed(const Duration(milliseconds: 1000));
      final output = await ToolDispatcher.dispatch(_ref, triggerTool, toolArgs);
      _addMessageToUI('tool', "Agent completed $triggerTool ✅", toolCall: {'output': output});
    }

    state = state.copyWith(isThinking: false);
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
