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
  final String connectionStatus; // "connected", "disconnected", "connecting", "REST_ACTIVE"
  final String? lastToolName;
  final String? lastAgentMessage;
  final String? lastError;
  final bool isSpeaking;
  final bool isExecutingTool;
  final String? lastWarning;
  final String transportType; // "live", "rest", "simulated"
  final String webSocketStatus; // "connected", "disconnected", "connecting", "error"
  final String restStatus; // "active", "inactive", "error"
  final String decisionSource; // "Gemini Live", "Gemini REST", "Local Rule Engine"
  final String? sessionId;

  AgentState({
    required this.status,
    required this.mode,
    required this.connectionStatus,
    this.lastToolName,
    this.lastAgentMessage,
    this.lastError,
    required this.isSpeaking,
    required this.isExecutingTool,
    this.lastWarning,
    required this.transportType,
    required this.webSocketStatus,
    required this.restStatus,
    required this.decisionSource,
    this.sessionId,
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
    String? lastWarning,
    String? transportType,
    String? webSocketStatus,
    String? restStatus,
    String? decisionSource,
    String? sessionId,
  }) {
    return AgentState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastToolName: lastToolName ?? this.lastToolName,
      lastAgentMessage: lastAgentMessage ?? this.lastAgentMessage,
      lastError: lastError != null ? (lastError.isEmpty ? null : lastError) : this.lastError,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isExecutingTool: isExecutingTool ?? this.isExecutingTool,
      lastWarning: lastWarning ?? this.lastWarning,
      transportType: transportType ?? this.transportType,
      webSocketStatus: webSocketStatus ?? this.webSocketStatus,
      restStatus: restStatus ?? this.restStatus,
      decisionSource: decisionSource ?? this.decisionSource,
      sessionId: sessionId != null ? (sessionId.isEmpty ? null : sessionId) : this.sessionId,
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
          lastWarning: null,
          transportType: "simulated",
          webSocketStatus: "disconnected",
          restStatus: "inactive",
          decisionSource: "Local Rule Engine",
          sessionId: null,
        ));

  void setStatus(AgentStatus status) {
    if (status == AgentStatus.idle) {
      // Transition to idle is blocked if current status is error
      if (state.status == AgentStatus.error) {
        return;
      }
      // Reconnecting state is only allowed to transition to idle if the connection is established
      if (state.status == AgentStatus.reconnecting && 
          state.connectionStatus != "connected" && 
          state.connectionStatus != "REST_ACTIVE") {
        return;
      }
      
      // Clear error on a successful transition to idle
      state = state.copyWith(
        status: AgentStatus.idle,
        isExecutingTool: false,
        lastError: "",
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
      lastWarning: null,
      transportType: "simulated",
      webSocketStatus: "disconnected",
      restStatus: "inactive",
      decisionSource: "Local Rule Engine",
      sessionId: null,
    );
  }

  void setMode(AgentMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setConnectionStatus(String connectionStatus) {
    state = state.copyWith(connectionStatus: connectionStatus);
  }

  void recoverToRest(String warning) {
    state = state.copyWith(
      status: AgentStatus.idle,
      connectionStatus: "REST_ACTIVE",
      lastError: "",
      lastWarning: warning,
      isExecutingTool: false,
    );
  }

  void updateTransportInfo({
    required String transportType,
    required String webSocketStatus,
    required String restStatus,
    required String decisionSource,
  }) {
    state = state.copyWith(
      transportType: transportType,
      webSocketStatus: webSocketStatus,
      restStatus: restStatus,
      decisionSource: decisionSource,
    );
  }

  void setSessionId(String? sessionId) {
    state = state.copyWith(sessionId: sessionId ?? "");
  }

  void startToolCall(String name) {
    state = state.copyWith(
      status: AgentStatus.executing,
      isExecutingTool: true,
      lastToolName: name,
      lastError: "",
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
        lastError: "",
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
