import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_isAvailable) return true;
    _isAvailable = await _speech.initialize(
      onError: (val) => print('Speech onError: $val'),
      onStatus: (val) => print('Speech onStatus: $val'),
    );
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String words) onResult,
    Duration duration = const Duration(seconds: 15),
  }) async {
    final ready = await initialize();
    if (!ready) return;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: 'it_IT',
      listenFor: duration,
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
