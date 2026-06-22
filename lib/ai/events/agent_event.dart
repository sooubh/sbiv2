import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AgentEventType {
  connected,
  disconnected,
  reconnectStarted,
  reconnectSuccess,
  reconnectFailed,
  toolStarted,
  toolCompleted,
  toolFailed,
  sessionRestored,
  error,
}

class AgentEvent {
  final AgentEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AgentEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata,
  });
}

class AgentEventNotifier extends StateNotifier<List<AgentEvent>> {
  AgentEventNotifier() : super([]);

  void emit(AgentEventType type, String message, {Map<String, dynamic>? metadata}) {
    final event = AgentEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    final list = [...state, event];
    // Keep it compact
    if (list.length > 100) {
      list.removeAt(0);
    }
    state = list;
  }

  void clear() {
    state = [];
  }
}

final agentEventProvider = StateNotifierProvider<AgentEventNotifier, List<AgentEvent>>((ref) {
  return AgentEventNotifier();
});
