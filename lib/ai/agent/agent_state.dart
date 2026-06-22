import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AgentStatus {
  idle,
  listening,
  thinking,
  executing,
  speaking,
  reconnecting,
  error,
}

enum AgentMode {
  onboarding,
  banking,
}

class AgentState {
  final AgentStatus status;
  final AgentMode mode;
  final String connectionStatus; // "connected", "disconnected", "connecting"
  final String? lastToolName;
  final String? lastAgentMessage;
  final String? lastError;
  final bool isSpeaking;
  final bool isExecutingTool;

  AgentState({
    required this.status,
    required this.mode,
    required this.connectionStatus,
    this.lastToolName,
    this.lastAgentMessage,
    this.lastError,
    required this.isSpeaking,
    required this.isExecutingTool,
  });

  AgentState copyWith({
    AgentStatus? status,
    AgentMode? mode,
    String? connectionStatus,
    String? lastToolName,
    String? lastAgentMessage,
    String? lastError,
    bool? isSpeaking,
    bool? isExecutingTool,
  }) {
    return AgentState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastToolName: lastToolName ?? this.lastToolName,
      lastAgentMessage: lastAgentMessage ?? this.lastAgentMessage,
      lastError: lastError ?? this.lastError,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isExecutingTool: isExecutingTool ?? this.isExecutingTool,
    );
  }
}

class AgentStateNotifier extends StateNotifier<AgentState> {
  AgentStateNotifier()
      : super(AgentState(
          status: AgentStatus.idle,
          mode: AgentMode.onboarding,
          connectionStatus: "disconnected",
          isSpeaking: false,
          isExecutingTool: false,
        ));

  void setStatus(AgentStatus status) {
    if (status == AgentStatus.idle) {
      // Transition to idle is blocked if current status is error
      if (state.status == AgentStatus.error) {
        return;
      }
      // Reconnecting state is only allowed to transition to idle if the connection is established
      if (state.status == AgentStatus.reconnecting && state.connectionStatus != "connected") {
        return;
      }
      
      // Clear error on a successful transition to idle
      state = state.copyWith(
        status: AgentStatus.idle,
        isExecutingTool: false,
        lastError: null,
      );
      return;
    }

    state = state.copyWith(
      status: status,
      isExecutingTool: status == AgentStatus.executing,
    );
  }

  void reset() {
    state = AgentState(
      status: AgentStatus.idle,
      mode: state.mode,
      connectionStatus: "disconnected",
      isSpeaking: false,
      isExecutingTool: false,
      lastToolName: null,
      lastAgentMessage: null,
      lastError: null,
    );
  }

  void setMode(AgentMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setConnectionStatus(String connectionStatus) {
    state = state.copyWith(connectionStatus: connectionStatus);
  }

  void startToolCall(String name) {
    state = state.copyWith(
      status: AgentStatus.executing,
      isExecutingTool: true,
      lastToolName: name,
      lastError: null,
    );
  }

  void endToolCall({String? error}) {
    if (error != null) {
      state = state.copyWith(
        status: AgentStatus.error,
        isExecutingTool: false,
        lastError: error,
      );
    } else {
      state = state.copyWith(
        status: AgentStatus.idle,
        isExecutingTool: false,
        lastError: null,
      );
    }
  }

  void setSpeaking(bool speaking) {
    if (speaking) {
      state = state.copyWith(
        status: AgentStatus.speaking,
        isSpeaking: true,
      );
    } else {
      // Only transition back to idle if we are speaking
      if (state.status == AgentStatus.speaking) {
        setStatus(AgentStatus.idle);
      }
      state = state.copyWith(isSpeaking: false);
    }
  }

  void setLastAgentMessage(String msg) {
    state = state.copyWith(lastAgentMessage: msg);
  }

  void setError(String err) {
    state = state.copyWith(
      status: AgentStatus.error,
      lastError: err,
    );
  }
}

final agentStateProvider = StateNotifierProvider<AgentStateNotifier, AgentState>((ref) {
  return AgentStateNotifier();
});
