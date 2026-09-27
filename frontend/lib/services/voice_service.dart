import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps the on-device speech recognizer used by the voice-input popup.
/// Recognition (and the resulting transcript) happens fully on-device via
/// the OS speech APIs; only the final text is sent to the backend.
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (e) => print('Speech error: $e'),
      onStatus: (s) => print('Speech status: $s'),
    );
    return _initialized;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
    );
  }

  Future<void> stopListening() => _speech.stop();

  void cancel() => _speech.cancel();
}
