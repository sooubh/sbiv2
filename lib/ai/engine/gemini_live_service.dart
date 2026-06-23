import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Models known to be deprecated or shut down.
/// If a user has one of these persisted in Hive, it will be auto-migrated.
const kDeprecatedLiveModels = <String>{
  'models/gemini-2.0-flash-live-001',
  'models/gemini-live-2.5-flash-preview-native-audio',
  'models/gemini-2.0-flash-live',
  'gemini-2.0-flash-live-001',
  'gemini-live-2.5-flash-preview-native-audio',
  'gemini-2.0-flash-live',
};

/// The current recommended Live API model (June 2026).
const kDefaultLiveModel = 'models/gemini-3.1-flash-live-preview';

class GeminiLiveService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _sessionId;
  final bool _isSessionRestored = false;

  final Map<String, String> _pendingToolCalls = {};
  final StringBuffer _responseBuffer = StringBuffer();

  // Callback interfaces
  void Function(String text)? onMessageReceived;
  void Function(String name, Map<String, dynamic> args, String callId)? onToolCallReceived;
  void Function(String error)? onError;
  void Function()? onDisconnected;
  void Function()? onConnected;
  void Function(String sessionId)? onSessionIdReceived;
  
  // Reconnect stability callbacks (kept for API compatibility)
  void Function()? onReconnectStarted;
  void Function()? onReconnectSuccess;
  void Function(String error)? onReconnectFailed;

  bool get isConnected => _isConnected;
  bool get isSessionRestored => _isSessionRestored;
  String? get sessionId => _sessionId;

  /// Validates and normalizes the model name.
  /// Returns the corrected model string, or replaces deprecated models
  /// with [kDefaultLiveModel].
  static String normalizeAndValidateModel(String model) {
    String normalized = model.trim();

    // Normalize: ensure "models/" prefix
    if (!normalized.startsWith('models/')) {
      normalized = 'models/$normalized';
    }

    // Check for deprecated models
    if (kDeprecatedLiveModels.contains(normalized) ||
        kDeprecatedLiveModels.contains(model.trim())) {
      if (kDebugMode) {
        print("[LIVE_MODEL] Deprecated model detected: '$model'. "
            "Auto-migrating to '$kDefaultLiveModel'.");
      }
      return kDefaultLiveModel;
    }

    return normalized;
  }

  /// Returns true if the given model string is known to be deprecated.
  static bool isModelDeprecated(String model) {
    final normalized = model.trim();
    return kDeprecatedLiveModels.contains(normalized) ||
        kDeprecatedLiveModels.contains(
            normalized.startsWith('models/') ? normalized : 'models/$normalized');
  }

  Future<bool> connect({
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> tools,
    required String model,
  }) async {
    if (apiKey.isEmpty) {
      _triggerError("Gemini API key is required");
      return false;
    }

    try {
      if (kDebugMode) print("[LIVE_CONNECT] Attempting to connect via WebSocketChannel...");
      disconnect();

      // Normalize and validate model name
      final normalizedModel = normalizeAndValidateModel(model);
      if (kDebugMode) {
        print("[LIVE_CONNECT] Using model: $normalizedModel (requested: $model)");
      }

      final uri = Uri.parse(
        "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey",
      );

      _channel = WebSocketChannel.connect(uri);

      // Listen to the stream
      _subscription = _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (err, stack) {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          final errorMsg = "WebSocket error: $err (Close Code: $closeCode, Reason: $closeReason)";
          if (kDebugMode) print("[LIVE_ERROR] $errorMsg");
          _triggerError(errorMsg);
          _handleDisconnect();
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          if (kDebugMode) {
            print("[LIVE_CLOSE] WebSocket closed. Close Code: $closeCode, Reason: $closeReason");
          }
          if (closeCode != null && closeCode != 1000) {
            _triggerError("WebSocket closed unexpectedly. Code: $closeCode, Reason: $closeReason");
          }
          _handleDisconnect();
        },
      );

      // Build the session setup configuration.
      //
      // CRITICAL FIX: The Gemini Live API models (gemini-3.1-flash-live-preview
      // and similar native audio models) do NOT support responseModalities: ["TEXT"].
      // They are native audio models that require AUDIO as the response modality.
      //
      // To receive text output alongside audio, we enable outputAudioTranscription
      // which provides a synchronized text transcript of the model's audio response.
      //
      // Reference: https://ai.google.dev/api/multimodal-live
      // Error without fix: WebSocket Close Code 1007 —
      //   "The requested combination of response modalities (TEXT) is not supported
      //    by the model. models/gemini-3.1-flash-live-preview"
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
          // outputAudioTranscription is a top-level field on BidiGenerateContentSetup,
          // NOT a field of GenerationConfig. It enables text transcripts of audio output
          // so the app can display text in the UI while using AUDIO response modality.
          // Reference: https://ai.google.dev/api/live#BidiGenerateContentSetup
          "outputAudioTranscription": {},
          "systemInstruction": {
            "parts": [
              {"text": systemInstruction}
            ]
          },
          "tools": tools.isNotEmpty
              ? [
                  {
                    "functionDeclarations": tools,
                  }
                ]
              : null,
        }
      };

      if (kDebugMode) {
        print("[LIVE_CONNECT] Sending setup message for model: $normalizedModel");
      }

      _channel!.sink.add(jsonEncode(setupMessage));
      
      _isConnected = true;
      onConnected?.call();
      return true;
    } catch (e) {
      if (kDebugMode) print("[LIVE_CONNECT] Failed to connect: $e");
      _triggerError("Failed to connect: $e");
      return false;
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
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
      final Map<String, dynamic> data = jsonDecode(msgStr);
      
      // 1. Setup complete
      if (data.containsKey('setupComplete')) {
        if (kDebugMode) print("[LIVE_SETUP_COMPLETE] Setup complete received.");
      }

      // 2. Session Resumption update
      if (data.containsKey('sessionResumptionUpdate')) {
        final resumption = data['sessionResumptionUpdate'] as Map<String, dynamic>;
        final newHandle = resumption['newHandle'] as String?;
        if (newHandle != null) {
          _sessionId = newHandle;
          onSessionIdReceived?.call(_sessionId!);
        }
      }

      // 3. Server content (model turn with audio, text, or transcription parts)
      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'] as Map<String, dynamic>;
        
        // 3a. Model turn — may contain inline text parts and/or audio data
        if (serverContent.containsKey('modelTurn')) {
          final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>;
          if (modelTurn.containsKey('parts')) {
            final parts = modelTurn['parts'] as List;
            for (final part in parts) {
              if (part is Map<String, dynamic> && part.containsKey('text')) {
                final text = part['text'] as String;
                if (text.isNotEmpty) {
                  _responseBuffer.write(text);
                }
              }
              // Audio data parts (inlineData) are intentionally ignored here
              // since this app uses text-based UI. The audio stream exists to
              // satisfy the model's AUDIO response modality requirement.
            }
          }
        }

        // 3b. Output audio transcription — the text transcript of audio output.
        // This is the primary mechanism for receiving text when using AUDIO modality.
        if (serverContent.containsKey('outputTranscription')) {
          final transcription = serverContent['outputTranscription'] as Map<String, dynamic>;
          
          final directText = transcription['text'] as String?;
          if (directText != null && directText.isNotEmpty) {
            _responseBuffer.write(directText);
          } else if (transcription.containsKey('parts')) {
            final parts = transcription['parts'] as List;
            for (final part in parts) {
              if (part is Map<String, dynamic> && part.containsKey('text')) {
                final text = part['text'] as String;
                if (text.isNotEmpty) {
                  _responseBuffer.write(text);
                }
              }
            }
          }
        }

        // 3c. Interrupt detection
        final isInterrupted = serverContent['interrupted'] as bool? ?? false;
        if (isInterrupted) {
          _responseBuffer.clear();
        }

        // 3d. Check if turn or generation is complete
        final isTurnComplete = serverContent['turnComplete'] as bool? ?? false;
        final isGenerationComplete = serverContent['generationComplete'] as bool? ?? false;
        if (isTurnComplete || isGenerationComplete) {
          if (_responseBuffer.isNotEmpty) {
            final fullResponse = _responseBuffer.toString().trim();
            if (kDebugMode) {
              print("[LIVE_RESPONSE_COMPLETE] $fullResponse");
            }
            onMessageReceived?.call(fullResponse);
            _responseBuffer.clear();
          }
        }
      }

      // 4. Tool calls
      if (data.containsKey('toolCall')) {
        final toolCall = data['toolCall'] as Map<String, dynamic>;
        if (toolCall.containsKey('functionCalls')) {
          final functionCalls = toolCall['functionCalls'] as List;
          for (final call in functionCalls) {
            if (call is Map<String, dynamic>) {
              final id = call['id'] as String?;
              final name = call['name'] as String?;
              final args = call['args'] as Map<String, dynamic>? ?? {};
              if (id != null && name != null) {
                _pendingToolCalls[id] = name;
                onToolCallReceived?.call(name, args, id);
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("[LIVE_PARSING_ERROR] Error parsing message: $e");
    }
  }

  void sendMessage(String text) {
    _responseBuffer.clear();
    if (!_isConnected || _channel == null) {
      _triggerError("Cannot send message. WebSocket is not connected.");
      return;
    }
    
    final clientContentMessage = {
      "clientContent": {
        "turns": [
          {
            "role": "user",
            "parts": [
              {"text": text}
            ]
          }
        ],
        "turnComplete": true
      }
    };
    
    _channel!.sink.add(jsonEncode(clientContentMessage));
  }

  void sendToolResponse(String callId, Map<String, dynamic> output) {
    if (!_isConnected || _channel == null) return;
    final name = _pendingToolCalls.remove(callId) ?? '';
    
    final toolResponseMessage = {
      "toolResponse": {
        "functionResponses": [
          {
            "name": name,
            "id": callId,
            "response": {
              "output": output
            }
          }
        ]
      }
    };
    
    _channel!.sink.add(jsonEncode(toolResponseMessage));
  }

  void _handleDisconnect() {
    _isConnected = false;
    onDisconnected?.call();
  }

  void _triggerError(String msg) {
    onError?.call(msg);
  }

  void disconnect() {
    _isConnected = false;
    _pendingToolCalls.clear();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
