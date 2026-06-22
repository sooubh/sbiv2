import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class GeminiLiveService {
  WebSocket? _webSocket;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;
  Timer? _watchdogTimer;
  Timer? _interruptionTimer;
  String? _sessionId; // For session resumption

  // Callback interfaces
  void Function(String text)? onMessageReceived;
  void Function(String name, Map<String, dynamic> args, String callId)? onToolCallReceived;
  void Function(String error)? onError;
  void Function()? onDisconnected;
  void Function()? onConnected;

  bool get isConnected => _isConnected;

  Future<bool> connect({
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> tools,
  }) async {
    if (apiKey.isEmpty) {
      _triggerError("Gemini API key is required");
      return false;
    }

    try {
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      _webSocket = await WebSocket.connect(wsUrl.toString()).timeout(const Duration(seconds: 10));
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnected?.call();

      // Send Setup Payload
      final setupPayload = {
        'setup': {
          'model': 'models/gemini-2.0-flash-live-001',
          'generationConfig': {
            'responseModalities': ['TEXT'],
          },
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'tools': tools.isNotEmpty ? [{'functionDeclarations': tools}] : null,
          if (_sessionId != null) 'sessionResumption': {'sessionId': _sessionId}
        }
      };

      _sendPayload(setupPayload);
      _startWatchdog();

      _subscription = _webSocket!.listen(
        (data) {
          _resetWatchdog();
          _handleIncomingMessage(data);
        },
        onError: (err) {
          _triggerError("WebSocket error: $err");
          _handleDisconnect(apiKey, systemInstruction, tools);
        },
        onDone: () {
          _handleDisconnect(apiKey, systemInstruction, tools);
        },
        cancelOnError: true,
      );

      return true;
    } catch (e) {
      _triggerError("Failed to connect: $e");
      return false;
    }
  }

  void _sendPayload(Map<String, dynamic> payload) {
    if (_webSocket != null && _isConnected) {
      _webSocket!.add(jsonEncode(payload));
    }
  }

  void sendMessage(String text) {
    if (!_isConnected) {
      _triggerError("Cannot send message. WebSocket is not connected.");
      return;
    }

    final messagePayload = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text}
            ]
          }
        ],
        'turnComplete': true
      }
    };
    _sendPayload(messagePayload);
    _startWatchdog();
  }

  void sendToolResponse(String callId, Map<String, dynamic> output) {
    final responsePayload = {
      'toolResponse': {
        'functionResponses': [
          {
            'response': {'output': output},
            'id': callId
          }
        ]
      }
    };
    _sendPayload(responsePayload);
    _startWatchdog(); // Reset watchdog
  }

  void _handleIncomingMessage(dynamic rawData) {
    try {
      final json = jsonDecode(rawData as String);

      // Save session ID if provided for session resumption
      if (json['setupComplete'] != null && json['setupComplete']['sessionId'] != null) {
        _sessionId = json['setupComplete']['sessionId'];
      }

      if (json['serverContent'] != null) {
        final serverContent = json['serverContent'];

        // Handle Interrupted event
        if (serverContent['interrupted'] == true) {
          _handleInterruption();
          return;
        }

        // Parse turns
        if (serverContent['modelTurn'] != null && serverContent['modelTurn']['parts'] != null) {
          final parts = serverContent['modelTurn']['parts'] as List;
          for (var part in parts) {
            if (part['text'] != null) {
              onMessageReceived?.call(part['text']);
            }
            if (part['functionCall'] != null) {
              final funcCall = part['functionCall'];
              final name = funcCall['name'] as String;
              final args = Map<String, dynamic>.from(funcCall['args'] ?? {});
              final callId = funcCall['id'] as String;
              onToolCallReceived?.call(name, args, callId);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error parsing message: $e");
    }
  }

  // Stability requirement: Watchdog timer - if no serverContent in 8 seconds, send empty nudge
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 8), () {
      if (_isConnected) {
        // Send a soft nudge payload
        final nudgePayload = {
          'clientContent': {
            'turns': [],
            'turnComplete': true
          }
        };
        _sendPayload(nudgePayload);
        _startWatchdog(); // restart
      }
    });
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
  }

  // Stability requirement: After interruption, start 4-second timer, then send empty nudge to unfreeze model
  void _handleInterruption() {
    _interruptionTimer?.cancel();
    _interruptionTimer = Timer(const Duration(seconds: 4), () {
      if (_isConnected) {
        final nudgePayload = {
          'clientContent': {
            'turns': [],
            'turnComplete': true
          }
        };
        _sendPayload(nudgePayload);
      }
    });
  }

  // Stability requirement: Auto-reconnect with backoff
  void _handleDisconnect(String apiKey, String systemInstruction, List<Map<String, dynamic>> tools) {
    _isConnected = false;
    _resetWatchdog();
    _interruptionTimer?.cancel();
    _subscription?.cancel();
    _webSocket?.close();
    onDisconnected?.call();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff: 2s, 4s, 6s
      Timer(delay, () {
        connect(apiKey: apiKey, systemInstruction: systemInstruction, tools: tools);
      });
    } else {
      _triggerError("Max connection attempts reached. Switching to REST fallback.");
    }
  }

  void _triggerError(String msg) {
    onError?.call(msg);
  }

  void disconnect() {
    _isConnected = false;
    _resetWatchdog();
    _interruptionTimer?.cancel();
    _subscription?.cancel();
    _webSocket?.close();
    _webSocket = null;
  }
}
