import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/features/splash/splash_screen.dart';
import 'package:sbiv2/features/settings/debug_simulation_page.dart';
import 'package:sbiv2/features/settings/ai_testing_lab_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _liveModelController;
  late TextEditingController _restModelController;

  @override
  void initState() {
    super.initState();
    final apiKey = ref.read(geminiApiKeyProvider);
    final modelConfig = ref.read(aiModelConfigProvider);
    _apiKeyController = TextEditingController(text: apiKey);
    _liveModelController = TextEditingController(text: modelConfig.liveModel);
    _restModelController = TextEditingController(text: modelConfig.restModel);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _liveModelController.dispose();
    _restModelController.dispose();
    super.dispose();
  }

  void _logoutAndExit(WidgetRef ref) {
    ref.read(isLoggedInProvider.notifier).state = false;
    ref.read(profileTypeProvider.notifier).setProfile('B'); // Reset to default
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentStateProvider);
    final voiceState = ref.watch(voiceStateProvider);
    final aiState = ref.watch(aiCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Config',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Gemini API Section
          Text(
            'API KEY CONFIGURATION',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini API Settings',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provide a valid Gemini API Key to enable voice and REST integrations. If left empty, the application runs in offline-simulation mode.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    labelStyle: GoogleFonts.inter(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: const Icon(Icons.key, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(aiCoordinatorProvider.notifier).updateApiKey(_apiKeyController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gemini API configuration successfully updated.'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                    child: Text('Save Configuration', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Model Configuration Section
          Text(
            'MODEL CONFIGURATION',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centralized AI Models',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _restModelController,
                  decoration: InputDecoration(
                    labelText: 'Gemini REST Model',
                    labelStyle: GoogleFonts.inter(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(aiModelConfigProvider.notifier).updateModels(
                        liveModel: _liveModelController.text.trim(),
                        restModel: _restModelController.text.trim(),
                      );
                      // Re-initialize the active agent coordinator to reconnect with the new models!
                      ref.read(aiCoordinatorProvider.notifier).updateApiKey(ref.read(geminiApiKeyProvider));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI models updated and service re-initialized.'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                    child: Text('Save Model Config', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Connection Status Card
          Text(
            'ENGINE STATUS & RUNTIME',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildStatusRow(
                  label: 'AI Engine Transport',
                  value: agentState.transportType.toUpperCase(),
                  valueColor: agentState.transportType == "rest" ? AppTheme.accentGreen : AppTheme.aiTeal,
                  icon: Icons.wifi,
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  label: 'Model Mode',
                  value: aiState.mode.name.toUpperCase(),
                  valueColor: AppTheme.primary,
                  icon: Icons.psychology,
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  label: 'Voice Engine',
                  value: voiceState.status.name.toUpperCase(),
                  valueColor: voiceState.status == VoiceStatus.error ? AppTheme.accentOrange : AppTheme.aiTeal,
                  icon: Icons.mic_none,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),



          // Developer Access
          Text(
            'DEVELOPER ACCESS',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.aiTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.science),
            label: Text('Open AI Testing Lab', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AITestingLabScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.bug_report),
            label: Text('Open Developer Debug Portal', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugSimulationPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.exit_to_app),
            label: Text('Switch Profile / Exit Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () => _logoutAndExit(ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: AppTheme.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class WebSocketDiagnosticsCard extends ConsumerStatefulWidget {
  const WebSocketDiagnosticsCard({super.key});

  @override
  ConsumerState<WebSocketDiagnosticsCard> createState() => _WebSocketDiagnosticsCardState();
}

class _WebSocketDiagnosticsCardState extends ConsumerState<WebSocketDiagnosticsCard> {
  bool _isRunningTest = false;
  final List<String> _logs = [];
  String _statusText = "Not Started";
  Color _statusColor = AppTheme.textSecondary;
  final ScrollController _scrollController = ScrollController();

  void _runDiagnostics() async {
    setState(() {
      _isRunningTest = true;
      _logs.clear();
      _statusText = "Running...";
      _statusColor = Colors.amber;
    });

    void log(String message) {
      final time = DateTime.now().toIso8601String().substring(11, 19);
      if (mounted) {
        setState(() {
          _logs.add("[$time] $message");
        });
        // Auto-scroll to bottom
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    final apiKey = ref.read(geminiApiKeyProvider);
    final modelConfig = ref.read(aiModelConfigProvider);

    if (apiKey.isEmpty) {
      log("Error: Gemini API Key is empty. Please set it in Settings.");
      if (mounted) {
        setState(() {
          _statusText = "Failed: Missing API Key";
          _statusColor = Colors.red;
          _isRunningTest = false;
        });
      }
      return;
    }

    log("Initializing diagnostics...");
    log("Live Model: ${modelConfig.liveModel}");

    String normalizedModel = modelConfig.liveModel;
    if (!normalizedModel.startsWith('models/')) {
      normalizedModel = 'models/$normalizedModel';
    }

    const host = "generativelanguage.googleapis.com";
    const path = "/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent";
    final uri = Uri.parse("wss://$host$path?key=$apiKey");

    log("Connecting to WebSocket endpoint...");
    log("URI: wss://$host$path?key=***${apiKey.length > 5 ? apiKey.substring(apiKey.length - 5) : ''}");

    WebSocketChannel? channel;
    StreamSubscription? subscription;

    try {
      channel = WebSocketChannel.connect(uri);
      
      final completer = Completer<void>();
      bool receivedResponse = false;
      bool setupCompleted = false;

      subscription = channel.stream.listen(
        (message) {
          String msgStr;
          if (message is String) {
            msgStr = message;
          } else if (message is List<int>) {
            msgStr = utf8.decode(message);
          } else if (message is List) {
            msgStr = utf8.decode(message.cast<int>());
          } else {
            msgStr = utf8.decode(List<int>.from(message as Iterable));
          }
          log("Raw message received: ${msgStr.substring(0, msgStr.length > 120 ? 120 : msgStr.length)}...");
          try {
            final Map<String, dynamic> data = jsonDecode(msgStr);
            if (data.containsKey('setupComplete')) {
              log("✓ Received setupComplete confirmation.");
              setupCompleted = true;
              
              // Now send a test ping message
              log("Sending test ping: 'Hello, connection test.'");
              final clientContentMessage = {
                "clientContent": {
                  "turns": [
                    {
                      "role": "user",
                      "parts": [
                        {"text": "Hello, connection test."}
                      ]
                    }
                  ],
                  "turnComplete": true
                }
              };
              channel!.sink.add(jsonEncode(clientContentMessage));
            } else if (data.containsKey('serverContent')) {
              final serverContent = data['serverContent'] as Map<String, dynamic>;
              
              // Handle modelTurn (may contain audio inlineData and/or text parts)
              if (serverContent.containsKey('modelTurn')) {
                log("✓ Received serverContent modelTurn.");
                final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>;
                if (modelTurn.containsKey('parts')) {
                  final parts = modelTurn['parts'] as List;
                  for (final part in parts) {
                    if (part is Map<String, dynamic>) {
                      if (part.containsKey('text')) {
                        log("Model Reply (text): \"${part['text']}\"");
                      } else if (part.containsKey('inlineData')) {
                        log("✓ Received audio data chunk.");
                      }
                    }
                  }
                }
                receivedResponse = true;
                if (!completer.isCompleted) completer.complete();
              }

              // Handle outputTranscription — text transcript of audio output
              if (serverContent.containsKey('outputTranscription')) {
                final transcription = serverContent['outputTranscription'] as Map<String, dynamic>;
                final directText = transcription['text'] as String?;
                if (directText != null && directText.isNotEmpty) {
                  log("Model Reply (transcription): \"$directText\"");
                } else if (transcription.containsKey('parts')) {
                  final parts = transcription['parts'] as List;
                  for (final part in parts) {
                    if (part is Map<String, dynamic> && part.containsKey('text')) {
                      log("Model Reply (transcription - fallback): \"${part['text']}\"");
                    }
                  }
                }
                receivedResponse = true;
                if (!completer.isCompleted) completer.complete();
              }
            } else if (data.containsKey('toolCall')) {
              log("✓ Received toolCall suggestion.");
            }
          } catch (e) {
            log("Error decoding JSON: $e");
          }
        },
        onError: (err) {
          final code = channel?.closeCode;
          final reason = channel?.closeReason;
          log("❌ Stream error: $err (Close Code: $code, Reason: $reason)");
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          final code = channel?.closeCode;
          final reason = channel?.closeReason;
          log("WebSocket stream closed. Close Code: $code, Reason: $reason");
          if (!completer.isCompleted) completer.complete();
        },
      );

      // Immediately send setup configuration payload
      // NOTE: Live API models (gemini-3.1-flash-live-preview) require AUDIO modality.
      // TEXT-only causes WebSocket close code 1007. We use outputAudioTranscription
      // to receive the text transcript of the model's audio response.
      log("Sending session setup message (AUDIO modality + transcription)...");
      final setupMessage = {
        "setup": {
          "model": normalizedModel,
          "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
              "voiceConfig": {
                "prebuiltVoiceConfig": {
                  "voiceName": "Puck"
                }
              }
            },
          },
          // outputAudioTranscription is a top-level BidiGenerateContentSetup field,
          // NOT a GenerationConfig field.
          "outputAudioTranscription": {},
          "systemInstruction": {
            "parts": [
              {"text": "You are a connection diagnostics test assistant."}
            ]
          }
        }
      };
      channel.sink.add(jsonEncode(setupMessage));

      // Wait for response with a timeout of 10 seconds
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log("⏰ Timeout: No response received from server within 10s.");
          throw TimeoutException("Timeout waiting for response");
        },
      );

      if (receivedResponse && setupCompleted) {
        log("🎉 Diagnostic test PASSED! Connection is fully functional.");
        if (mounted) {
          setState(() {
            _statusText = "Passed";
            _statusColor = Colors.green;
          });
        }
      } else {
        log("❌ Diagnostic test failed: setupComplete=$setupCompleted, receivedResponse=$receivedResponse");
        if (mounted) {
          setState(() {
            _statusText = "Failed";
            _statusColor = Colors.red;
          });
        }
      }
    } catch (e) {
      log("❌ Connection test failed with exception: $e");
      final code = channel?.closeCode;
      final reason = channel?.closeReason;
      log("Final Close Code: $code, Reason: $reason");
      if (mounted) {
        setState(() {
          _statusText = "Failed";
          _statusColor = Colors.red;
        });
      }
    } finally {
      subscription?.cancel();
      channel?.sink.close();
      if (mounted) {
        setState(() {
          _isRunningTest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Live WebSocket Diagnostics',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusText.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Test the low-latency Gemini Live WebSocket connection and view raw communication logs to debug closures.',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (_logs.isNotEmpty) ...[
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10,
                        color: _logs[index].contains('❌')
                            ? Colors.redAccent
                            : _logs[index].contains('✓') || _logs[index].contains('🎉')
                                ? Colors.greenAccent
                                : Colors.lightBlueAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningTest ? null : _runDiagnostics,
              icon: _isRunningTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(
                _isRunningTest ? 'Testing Connection...' : 'Run Diagnostics Connection Test',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
