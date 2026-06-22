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
  Timer? _reconnectTimer;
  String? _sessionId; // For session resumption
  bool _isSessionRestored = false;

  // Callback interfaces
  void Function(String text)? onMessageReceived;
  void Function(String name, Map<String, dynamic> args, String callId)? onToolCallReceived;
  void Function(String error)? onError;
  void Function()? onDisconnected;
  void Function()? onConnected;
  void Function(String sessionId)? onSessionIdReceived;
  
  // Reconnect stability callbacks
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
      if (kDebugMode) print("[LIVE_CONNECT] Attempting to connect...");
      _reconnectTimer?.cancel();
      _subscription?.cancel();
      _webSocket?.close();
      _webSocket = null;

      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      _webSocket = await WebSocket.connect(wsUrl.toString()).timeout(const Duration(seconds: 10));
      _isConnected = true;
      _isSessionRestored = false;

      if (kDebugMode) print("[LIVE_OPEN] WebSocket connected successfully.");

      if (_reconnectAttempts > 0) {
        onReconnectSuccess?.call();
      } else {
        onConnected?.call();
      }
      // Reconnect attempts should ONLY be reset when setup is fully complete, not just when socket opens.

      // Send Setup Payload
      final setupPayload = {
        'setup': {
          'model': model,
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

      if (kDebugMode) print("[LIVE_SETUP_SENT] Sending setup payload.");
      _sendPayload(setupPayload);
      _startWatchdog();

      _subscription = _webSocket!.listen(
        (data) {
          if (kDebugMode) print("[LIVE_PAYLOAD] $data");
          _resetWatchdog();
          _handleIncomingMessage(data);
        },
        onError: (err) {
          if (kDebugMode) print("[LIVE_ERROR] WebSocket error: $err");
          _triggerError("WebSocket error: $err");
          _handleDisconnect(apiKey, systemInstruction, tools, model);
        },
        onDone: () {
          if (kDebugMode) print("[LIVE_CLOSE] WebSocket closed. Code: ${_webSocket?.closeCode}, Reason: ${_webSocket?.closeReason}");
          _handleDisconnect(apiKey, systemInstruction, tools, model);
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

      if (json['setupComplete'] != null) {
        if (kDebugMode) print("[LIVE_SETUP_COMPLETE] Received setupComplete.");
        _reconnectAttempts = 0; // Truly connected and setup
        final setupComplete = json['setupComplete'];
        if (setupComplete['sessionId'] != null) {
          _sessionId = setupComplete['sessionId'];
          onSessionIdReceived?.call(_sessionId!);
        }
        _isSessionRestored = setupComplete['sessionResumption'] == true;
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
              if (kDebugMode) print("[LIVE_MESSAGE] Received text message");
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

  // Stability requirement: Watchdog timer - if no serverContent in 20 seconds, send empty nudge
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 20), () {
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
  void _handleDisconnect(String apiKey, String systemInstruction, List<Map<String, dynamic>> tools, String model) {
    if (!_isConnected) {
      return;
    }

    _isConnected = false;
    _resetWatchdog();
    _interruptionTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _webSocket?.close();
    onDisconnected?.call();

    // Do NOT reset _reconnectAttempts here, otherwise infinite loop if server drops immediately.
    _startReconnect(apiKey, systemInstruction, tools, model);
  }

  void _startReconnect(String apiKey, String systemInstruction, List<Map<String, dynamic>> tools, String model) {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      if (kDebugMode) print("[LIVE_RECONNECT] Attempt $_reconnectAttempts of $_maxReconnectAttempts");
      onReconnectStarted?.call();
      final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff: 2s, 4s, 6s
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () async {
        final success = await connect(apiKey: apiKey, systemInstruction: systemInstruction, tools: tools, model: model);
        if (!success) {
          _startReconnect(apiKey, systemInstruction, tools, model);
        }
      });
    } else {
      onReconnectFailed?.call("Max connection attempts reached. Switch to REST.");
    }
  }

  void _triggerError(String msg) {
    onError?.call(msg);
  }

  void disconnect() {
    _isConnected = false;
    _reconnectAttempts = 0;
    _resetWatchdog();
    _interruptionTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _webSocket?.close();
    _webSocket = null;
  }
}
