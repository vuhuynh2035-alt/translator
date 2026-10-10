import 'package:flutter_tts/flutter_tts.dart';
import '../models/settings.dart';
import 'audio_route.dart';

class SpeechSpeaker {
  SpeechSpeaker({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<void> _chain = Future<void>.value();
  bool _configured = false;

  double? _lastRate;
  double? _lastPitch;

  Future<void> speak(String text, String locale, {double rate = 0.56, double pitch = 1.0, PlaybackTarget? target}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    final next = _chain.then((_) async {
      if (target != null) {
        await AudioRoute().apply(target);
      }
      await _ensure(rate, pitch);
      await _tts.setLanguage(locale);
      await _tts.speak(trimmed, focus: false);
    });
    _chain = next.catchError((_) {});
    return next;
  }

  Future<void> stop() async {
    await _tts.stop();
    _chain = Future<void>.value();
  }

  Future<void> _ensure(double rate, double pitch) async {
    if (!_configured) {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      _configured = true;
    }
    if (_lastRate != rate) {
      await _tts.setSpeechRate(rate);
      _lastRate = rate;
    }
    if (_lastPitch != pitch) {
      await _tts.setPitch(pitch);
      _lastPitch = pitch;
    }
  }
}
