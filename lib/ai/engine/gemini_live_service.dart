import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

class GeminiLiveService {
  LiveSession? _session;
  GoogleGenAI? _genAI;
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
      if (kDebugMode) print("[LIVE_CONNECT] Attempting to connect...");
      disconnect();

      _genAI = GoogleGenAI(apiKey: apiKey);

      final List<Tool> parsedTools = tools.map((t) => Tool.fromJson(t)).toList();

      _session = await _genAI!.live.connect(
        LiveConnectParameters(
          model: model,
          systemInstruction: Content(parts: [Part(text: systemInstruction)]),
          config: GenerationConfig(
            responseModalities: [Modality.TEXT],
          ),
          tools: parsedTools.isNotEmpty ? parsedTools : null,
          sessionResumption: _sessionId != null
              ? SessionResumptionConfig(handle: _sessionId!)
              : null,
          callbacks: LiveCallbacks(
            onOpen: () {
              if (kDebugMode) print("[LIVE_OPEN] WebSocket connected successfully.");
              _isConnected = true;
              onConnected?.call();
            },
            onMessage: (LiveServerMessage message) {
              if (message.setupComplete != null) {
                if (kDebugMode) print("[LIVE_SETUP_COMPLETE] Received setupComplete.");
                // Note: The package may handle session restoration status internally
              }

              if (message.sessionResumptionUpdate != null) {
                final newHandle = message.sessionResumptionUpdate!.newHandle;
                if (newHandle != null) {
                  _sessionId = newHandle;
                  onSessionIdReceived?.call(_sessionId!);
                }
              }

              if (message.text != null && message.text!.isNotEmpty) {
                if (kDebugMode) print("[LIVE_MESSAGE] Received text message");
                onMessageReceived?.call(message.text!);
              }

              if (message.toolCall != null && message.toolCall!.functionCalls != null) {
                for (final call in message.toolCall!.functionCalls!) {
                  if (call.id != null && call.name != null) {
                    _pendingToolCalls[call.id!] = call.name!;
                    onToolCallReceived?.call(call.name!, call.args ?? {}, call.id!);
                  }
                }
              }
            },
            onError: (e, s) {
              if (kDebugMode) print("[LIVE_ERROR] WebSocket error: $e");
              _triggerError("WebSocket error: $e");
              _handleDisconnect();
            },
            onClose: (code, reason) {
              if (kDebugMode) print("[LIVE_CLOSE] WebSocket closed. Code: $code, Reason: $reason");
              _handleDisconnect();
            },
          ),
        ),
      );

      return true;
    } catch (e) {
      _triggerError("Failed to connect: $e");
      return false;
    }
  }

  void sendMessage(String text) {
    if (!_isConnected || _session == null) {
      _triggerError("Cannot send message. WebSocket is not connected.");
      return;
    }
    _session!.sendText(text);
  }

  void sendToolResponse(String callId, Map<String, dynamic> output) {
    if (!_isConnected || _session == null) return;
    final name = _pendingToolCalls.remove(callId) ?? '';
    _session!.sendFunctionResponse(
      id: callId,
      name: name,
      response: output,
    );
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
    _session?.close();
    _session = null;
  }
}

