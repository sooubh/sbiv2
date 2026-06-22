import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';

/// [VoiceService] owns the microphone (STT) and the speaker (TTS).
///
/// Design constraints (Prompt 2B):
/// - Sequential only: listen → send text → speak. No barge-in / interruption.
/// - Agent MUST finish speaking before the mic is re-enabled.
/// - Pause button stops TTS mid-sentence; resume continues from the pause point
///   by re-speaking the same text from the beginning (flutter_tts limitation).
/// - If STT or TTS init fails the service emits VoiceStatus.error and the UI
///   falls back gracefully to text-only with a visible error banner.
class VoiceService {
  final Ref _ref;

  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _ttsReady = false;

  /// The text that TTS is currently speaking or last spoke. Used for resume.
  String? _lastSpokenText;

  VoiceService(this._ref);

  // ─── Initialisation ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    await _initStt();
    await _initTts();
  }

  Future<void> _initStt() async {
    try {
      _sttReady = await _stt.initialize(
        onError: (err) {
          if (kDebugMode) print('[VoiceService] STT error: $err');
          _ref.read(voiceStateProvider.notifier).setError(
                'Microphone error: ${err.errorMsg}. Voice paused, use text input.',
              );
        },
        onStatus: (status) {
          if (kDebugMode) print('[VoiceService] STT status: $status');
          // When the STT session auto-stops (silence or end-of-utterance),
          // finalize so we do not stay stuck in "listening".
          if (status == stt.SpeechToText.doneStatus ||
              status == stt.SpeechToText.notListeningStatus) {
            _onSttDone();
          }
        },
      );
      _ref.read(voiceStateProvider.notifier).setSttAvailable(_sttReady);
    } catch (e) {
      if (kDebugMode) print('[VoiceService] STT init failed: $e');
      _ref.read(voiceStateProvider.notifier).setSttAvailable(false);
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-IN'); // Hinglish / Indian English
      await _tts.setSpeechRate(0.48); // Natural conversation pace
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        _onTtsDone();
      });

      _tts.setErrorHandler((msg) {
        if (kDebugMode) print('[VoiceService] TTS error: $msg');
        _ref.read(voiceStateProvider.notifier).setError(
              'Speaker error: $msg. Voice paused, use text input.',
            );
      });

      _ttsReady = true;
      _ref.read(voiceStateProvider.notifier).setTtsAvailable(true);
    } catch (e) {
      if (kDebugMode) print('[VoiceService] TTS init failed: $e');
      _ref.read(voiceStateProvider.notifier).setTtsAvailable(false);
    }
  }

  // ─── STT: Listen ──────────────────────────────────────────────────────────

  /// Starts the microphone. Recognised text is forwarded to the AI coordinator.
  Future<void> startListening() async {
    final voiceNotifier = _ref.read(voiceStateProvider.notifier);
    final voiceState = _ref.read(voiceStateProvider);

    // Guard: do not start if voice is in error, or TTS is still speaking
    if (voiceState.status == VoiceStatus.error) return;
    if (voiceState.status == VoiceStatus.speaking) return;
    if (!_sttReady) {
      voiceNotifier.setError('Microphone not available. Use text input.');
      return;
    }

    voiceNotifier.setStatus(VoiceStatus.listening);

    try {
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognisedText = result.recognizedWords.trim();
            if (recognisedText.isNotEmpty) {
              _dispatchToAgent(recognisedText);
            }
          }
        },
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('[VoiceService] startListening error: $e');
      voiceNotifier.setError('Could not start microphone: $e');
    }
  }

  /// Cancels an active listening session without dispatching the partial text.
  Future<void> cancelListening() async {
    await _stt.cancel();
    final voiceNotifier = _ref.read(voiceStateProvider.notifier);
    if (_ref.read(voiceStateProvider).status == VoiceStatus.listening) {
      voiceNotifier.setStatus(VoiceStatus.idle);
    }
  }

  /// Called when STT session ends (either by silence or done status).
  void _onSttDone() {
    final voiceState = _ref.read(voiceStateProvider);
    if (voiceState.status == VoiceStatus.listening) {
      _ref.read(voiceStateProvider.notifier).setStatus(VoiceStatus.processing);
    }
  }

  // ─── TTS: Speak ───────────────────────────────────────────────────────────

  /// Speaks [text] using the platform TTS engine.
  ///
  /// Called by [AICoordinator] after every agent text response.
  /// No-op if TTS is unavailable or voice is in error.
  Future<void> speak(String text) async {
    final voiceState = _ref.read(voiceStateProvider);
    if (!_ttsReady) return;
    if (voiceState.status == VoiceStatus.error) return;

    _lastSpokenText = text;
    _ref.read(voiceStateProvider.notifier).setStatus(VoiceStatus.speaking);
    _ref.read(voiceStateProvider.notifier).setPaused(false);
    _ref.read(agentStateProvider.notifier).setSpeaking(true);

    await _tts.speak(text);
  }

  /// Pauses TTS. The mic stays blocked until the user explicitly resumes or
  /// TTS finishes.
  Future<void> pauseSpeaking() async {
    if (_ref.read(voiceStateProvider).status != VoiceStatus.speaking) return;
    await _tts.pause();
    _ref.read(voiceStateProvider.notifier).setPaused(true);
    _ref.read(agentStateProvider.notifier).setSpeaking(false);
  }

  /// Resumes paused TTS. On platforms where pause/resume is not supported
  /// (iOS), re-speaks from the beginning.
  Future<void> resumeSpeaking() async {
    final voiceState = _ref.read(voiceStateProvider);
    if (voiceState.status != VoiceStatus.speaking) return;
    if (!voiceState.isPaused) return;

    // flutter_tts resume is platform-dependent; always re-speak for safety.
    if (_lastSpokenText != null) {
      _ref.read(voiceStateProvider.notifier).setPaused(false);
      _ref.read(agentStateProvider.notifier).setSpeaking(true);
      await _tts.speak(_lastSpokenText!);
    }
  }

  /// Called when TTS naturally completes. Transitions back to idle and the mic
  /// is unlocked for the next user utterance.
  void _onTtsDone() {
    _ref.read(voiceStateProvider.notifier).setStatus(VoiceStatus.idle);
    _ref.read(voiceStateProvider.notifier).setPaused(false);
    _ref.read(agentStateProvider.notifier).setSpeaking(false);
  }

  /// Stops TTS immediately. Used when the user presses the stop/cancel button.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _ref.read(voiceStateProvider.notifier).setStatus(VoiceStatus.idle);
    _ref.read(voiceStateProvider.notifier).setPaused(false);
    _ref.read(agentStateProvider.notifier).setSpeaking(false);
  }

  // ─── Coordinator bridge ───────────────────────────────────────────────────

  void _dispatchToAgent(String text) {
    _ref.read(voiceStateProvider.notifier).setStatus(VoiceStatus.processing);
    _ref.read(aiCoordinatorProvider.notifier).sendMessage(text);
  }

  // ─── Teardown ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _stt.cancel();
    await _tts.stop();
  }
}

/// Riverpod provider for [VoiceService].
///
/// The service is kept alive as long as the [Ref] is alive (app session).
/// Initialisation is lazy-called from the first widget that reads this provider.
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
