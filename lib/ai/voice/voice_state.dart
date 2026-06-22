import 'package:flutter_riverpod/flutter_riverpod.dart';

/// States the voice interaction layer can be in.
enum VoiceStatus {
  /// Microphone is off, TTS is not speaking. Default/ready state.
  idle,

  /// Microphone is recording user speech.
  listening,

  /// STT recognised speech; waiting for agent to respond. Not a UI-blocking
  /// state – the agent's AgentStatus handles thinking/executing feedback.
  processing,

  /// TTS is actively speaking the agent's response.
  speaking,

  /// A non-recoverable voice error occurred. App falls back to text-only.
  error,
}

class VoiceState {
  final VoiceStatus status;

  /// True when STT was initialised successfully (microphone available).
  final bool sttAvailable;

  /// True when TTS engine is ready.
  final bool ttsAvailable;

  /// True when the user explicitly paused TTS mid-speech.
  final bool isPaused;

  /// Human-readable error description, only set when status == error.
  final String? error;

  const VoiceState({
    required this.status,
    required this.sttAvailable,
    required this.ttsAvailable,
    required this.isPaused,
    this.error,
  });

  VoiceState copyWith({
    VoiceStatus? status,
    bool? sttAvailable,
    bool? ttsAvailable,
    bool? isPaused,
    String? error,
  }) {
    return VoiceState(
      status: status ?? this.status,
      sttAvailable: sttAvailable ?? this.sttAvailable,
      ttsAvailable: ttsAvailable ?? this.ttsAvailable,
      isPaused: isPaused ?? this.isPaused,
      error: error,
    );
  }
}

class VoiceStateNotifier extends StateNotifier<VoiceState> {
  VoiceStateNotifier()
      : super(const VoiceState(
          status: VoiceStatus.idle,
          sttAvailable: false,
          ttsAvailable: false,
          isPaused: false,
        ));

  void setStatus(VoiceStatus status) {
    // Preserve error state unless explicitly cleared by a new successful action
    if (state.status == VoiceStatus.error && status != VoiceStatus.idle) {
      return;
    }
    state = state.copyWith(status: status, error: null);
  }

  void setSttAvailable(bool available) {
    state = state.copyWith(sttAvailable: available);
  }

  void setTtsAvailable(bool available) {
    state = state.copyWith(ttsAvailable: available);
  }

  void setPaused(bool paused) {
    state = state.copyWith(isPaused: paused);
  }

  void setError(String err) {
    state = state.copyWith(status: VoiceStatus.error, error: err);
  }

  /// Clears the error and returns to idle so the user can try again.
  void clearError() {
    state = state.copyWith(status: VoiceStatus.idle, error: null);
  }
}

final voiceStateProvider =
    StateNotifierProvider<VoiceStateNotifier, VoiceState>((ref) {
  return VoiceStateNotifier();
});
