import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiLiveService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _sessionId;
  final bool _isSessionRestored = false;

  final Map<String, String> _pendingToolCalls = {};

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

      // Normalize model name (Gemini Live API expects "models/model-name")
      String normalizedModel = model;
      if (!normalizedModel.startsWith('models/')) {
        normalizedModel = 'models/$normalizedModel';
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

      // Immediately send setup configuration
      final setupMessage = {
        "setup": {
          "model": normalizedModel,
          "generationConfig": {
            "responseModalities": ["TEXT"],
          },
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

      _channel!.sink.add(jsonEncode(setupMessage));
      
      _isConnected = true;
      onConnected?.call();
      return true;
    } catch (e) {
      _triggerError("Failed to connect: $e");
      return false;
    }
  }

  void _handleIncomingMessage(dynamic messageStr) {
    try {
      final Map<String, dynamic> data = jsonDecode(messageStr as String);
      
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

      // 3. Text output
      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'] as Map<String, dynamic>;
        if (serverContent.containsKey('modelTurn')) {
          final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>;
          if (modelTurn.containsKey('parts')) {
            final parts = modelTurn['parts'] as List;
            for (final part in parts) {
              if (part is Map<String, dynamic> && part.containsKey('text')) {
                final text = part['text'] as String;
                if (text.isNotEmpty) {
                  onMessageReceived?.call(text);
                }
              }
            }
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
