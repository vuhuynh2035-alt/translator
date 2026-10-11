import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

class SpeechListener {
  SpeechListener({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  Completer<void>? _done;
  void Function(String message)? onError;

  Future<bool> ensureReady() {
    return _speech.initialize(
      onError: (error) {
        onError?.call(_friendly(error.errorMsg));
        _finish();
      },
      onStatus: (status) {
        if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
          _finish();
        }
      },
      finalTimeout: const Duration(milliseconds: 450),
    );
  }

  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required Duration pauseFor,
    required Duration listenFor,
    required void Function(String text, bool isFinal) onText,
    void Function(double level)? onLevel,
  }) async {
    try {
      await _speech.cancel();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 200));

    _done = Completer<void>();
    final started = await _speech.listen(
      onResult: (result) => onText(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onLevel,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        onDevice: onDevice,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        cancelOnError: false,
        pauseFor: pauseFor,
        listenFor: listenFor,
        localeId: localeId,
      ),
    );
    if (!started) {
      _finish();
      throw Exception('Không thể khởi động micro');
    }
  }

  Future<void> waitUntilIdle() async {
    final done = _done;
    if (done != null) {
      try {
        await done.future.timeout(const Duration(seconds: 45));
      } catch (_) {
        _finish();
      }
    }
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();

  void _finish() {
    final done = _done;
    if (done != null && !done.isCompleted) done.complete();
  }

  static String _friendly(String code) {
    switch (code) {
      case 'error_permission':
        return 'Chưa được phép dùng micro hoặc nhận dạng giọng nói.';
      case 'error_network':
      case 'error_network_timeout':
        return 'Nhận dạng giọng nói cần mạng trên máy này. Hãy bật mạng hoặc tải gói ngôn ngữ ngoại tuyến của hệ thống.';
      case 'error_language_unavailable':
      case 'error_language_not_supported':
        return 'Máy chưa có gói nhận dạng cho ngôn ngữ này.';
      case 'error_no_match':
      case 'error_speech_timeout':
        return '';
      default:
        return 'Lỗi nghe: $code';
    }
  }
}
