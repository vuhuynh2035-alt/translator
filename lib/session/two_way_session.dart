import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../logic/draft_translator.dart';
import '../logic/interpreter_prompt.dart';
import '../logic/translation_memory.dart';
import '../models/language.dart';
import '../models/settings.dart';
import '../services/audio_route.dart';
import '../services/settings_store.dart';
import '../services/speech_listener.dart';
import '../services/speech_speaker.dart';
import '../services/translation/offline_translator.dart';
import '../services/translation/online_translator.dart';
import '../services/translation/translation_engine.dart';

enum BoothSide { other, mine }

class TwoWaySession extends ChangeNotifier {
  TwoWaySession({
    required this.settings,
    required this.offline,
    required this.client,
    SpeechListener? listener,
    SpeechSpeaker? speaker,
    AudioRoute? audioRoute,
    TranslationMemory? memory,
  }) : listener = listener ?? SpeechListener(),
       speaker = speaker ?? SpeechSpeaker(),
       audioRoute = audioRoute ?? AudioRoute(),
       memory = memory ?? TranslationMemory() {
    draft = DraftTranslator(translate: _translateLive, memory: this.memory);
  }

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;
  final SpeechListener listener;
  final SpeechSpeaker speaker;
  final AudioRoute audioRoute;
  final TranslationMemory memory;
  late final DraftTranslator draft;
  final context = <DialogueTurn>[];
  final fullHistory = <DialogueTurn>[];

  BoothSide? listening;
  bool working = false;
  String live = '';
  String otherSaid = '';
  String forMe = '';
  String iSaid = '';
  String forThem = '';
  String status = 'Sẵn sàng';
  String? error;
  String? notice;
  int? latencyMs;
  double sound = 0;

  bool autoMode = false;
  PlaybackTarget topPlayback = PlaybackTarget.speaker;
  PlaybackTarget bottomPlayback = PlaybackTarget.headphones;

  Timer? _debounce;
  bool _closing = false;
  BoothSide _draftSide = BoothSide.other;
  bool _network = true;
  DateTime? _networkChecked;

  Future<void> replay(String text, AppLanguage target) async {
    final current = settings.settings;
    if (!current.speaks) return;
    await audioRoute.apply(current.playback);
    await speaker.speak(text, target.ttsLocale, rate: current.ttsRate, pitch: current.ttsPitch);
  }

  void clear() {
    context.clear();
    fullHistory.clear();
    notifyListeners();
  }

  String exportTranscript() {
    final buffer = StringBuffer();
    final current = settings.settings;
    buffer.writeln('Cuộc hội thoại Hai chiều (${current.heardLanguage} <-> ${current.myLanguage}):');
    buffer.writeln('Thời gian: ${DateTime.now().toLocal()}');
    buffer.writeln('--------------------------------------------------\n');
    for (final turn in fullHistory) {
      buffer.writeln('Nguồn: ${turn.source}');
      buffer.writeln('Dịch: ${turn.translation}\n');
    }
    return buffer.toString();
  }

  Future<void> toggle(BoothSide side) async {
    if (working) return;
    if (listening == side) {
      await _close();
      return;
    }
    if (listening != null) return;
    await _open(side);
  }

  Future<void> _open(BoothSide side) async {
    error = null;
    notice = null;
    listener.onError = (message) {
      if (message.isEmpty) return;
      error = message;
      if (listening != null) unawaited(_close());
      notifyListeners();
    };
    final ready = await listener.ensureReady();
    if (!ready) {
      error = 'Máy không khởi động được nhận dạng giọng nói.';
      notifyListeners();
      return;
    }
    final current = settings.settings;
    final language = side == BoothSide.other
        ? AppLanguage.byCode(current.heardLanguage)
        : AppLanguage.byCode(current.myLanguage);
    listening = side;
    _draftSide = side;
    live = '';
    status = side == BoothSide.other ? 'Đang nghe đối phương' : 'Đang nghe bạn';
    notifyListeners();
    await listener.listen(
      localeId: language.sttLocale,
      onDevice: current.engine == EngineMode.offline,
      pauseFor: const Duration(seconds: 8),
      listenFor: const Duration(seconds: 60),
      onLevel: (level) {
        sound = level;
        notifyListeners();
      },
      onText: (text, isFinal) {
        live = text;
        _scheduleDraft(text);
        notifyListeners();
        if (isFinal) unawaited(_close());
      },
    );
  }

  void _scheduleDraft(String text) {
    _debounce?.cancel();
    if (text.trim().length < 6) return;
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _bindScope();
      draft.anticipate(text);
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    final side = listening;
    listening = null;
    working = true;
    status = 'Đang dịch';
    _debounce?.cancel();
    notifyListeners();
    try {
      await listener.stop();
      await listener.waitUntilIdle().timeout(const Duration(seconds: 2));
    } catch (_) {}
    final text = live.trim();
    if (side != null) {
      _draftSide = side;
      _bindScope();
    }
    if (side == null || text.isEmpty) {
      live = '';
      working = false;
      _closing = false;
      status = 'Sẵn sàng';
      notifyListeners();
      return;
    }
    final started = Stopwatch()..start();
    final current = settings.settings;
    final to = side == BoothSide.other
        ? AppLanguage.byCode(current.myLanguage)
        : AppLanguage.byCode(current.heardLanguage);
    final route = side == BoothSide.other ? topPlayback : bottomPlayback;
    try {
      final translation = await draft.resolve(text);
      latencyMs = started.elapsedMilliseconds;
      if (side == BoothSide.other) {
        otherSaid = text;
        forMe = translation;
      } else {
        iSaid = text;
        forThem = translation;
      }
      final turn = DialogueTurn(source: text, translation: translation);
      context.add(turn);
      if (context.length > 6) context.removeAt(0);
      fullHistory.add(turn);
      live = '';
      status = current.speaks ? 'Đang phát' : 'Đã dịch';
      notifyListeners();
      if (current.speaks && translation.trim().isNotEmpty) {
        await speaker.speak(translation, to.ttsLocale, rate: current.ttsRate, pitch: current.ttsPitch, target: route);
      }
    } catch (caught) {
      error = caught is TranslationException ? caught.message : 'Không dịch được.';
    } finally {
      working = false;
      _closing = false;
      status = 'Sẵn sàng';
      notifyListeners();
      
      if (autoMode && side != null && text.isNotEmpty) {
        final nextSide = side == BoothSide.other ? BoothSide.mine : BoothSide.other;
        unawaited(_open(nextSide));
      }
    }
  }

  Future<String> _translateLive(String text) {
    final current = settings.settings;
    final from = _draftSide == BoothSide.other
        ? AppLanguage.byCode(current.heardLanguage)
        : AppLanguage.byCode(current.myLanguage);
    final to = _draftSide == BoothSide.other
        ? AppLanguage.byCode(current.myLanguage)
        : AppLanguage.byCode(current.heardLanguage);
    return _translate(from, to, text);
  }

  Future<String> _translate(AppLanguage from, AppLanguage to, String text) async {
    final cached = memory.lookup(text, scope: '${from.code}>${to.code}');
    if (cached != null) return cached;
    final engine = await _engine();
    final buffer = StringBuffer();
    await for (final token in engine.translate(
      TranslationRequest(text: text, from: from, to: to, context: List<DialogueTurn>.from(context)),
    )) {
      buffer.write(token);
    }
    final translation = buffer.toString().trim();
    memory.store(text, translation, scope: '${from.code}>${to.code}');
    return translation;
  }

  void _bindScope() {
    final current = settings.settings;
    final from = _draftSide == BoothSide.other ? current.heardLanguage : current.myLanguage;
    final to = _draftSide == BoothSide.other ? current.myLanguage : current.heardLanguage;
    draft.scope = '$from>$to';
  }

  Future<TranslationEngine> _engine() async {
    final current = settings.settings;
    if (current.engine == EngineMode.offline || !await _hasNetwork()) {
      if (current.engine == EngineMode.online) notice = 'Không có mạng. Đang dùng bản dịch trên máy.';
      return OfflineEngine(offline);
    }
    return OnlineTranslator(client: client, settings: () => settings.settings);
  }

  Future<bool> _hasNetwork() async {
    final now = DateTime.now();
    if (_networkChecked != null && now.difference(_networkChecked!) < const Duration(seconds: 3)) {
      return _network;
    }
    try {
      final results = await Connectivity().checkConnectivity();
      _network = results.any((item) => item != ConnectivityResult.none);
    } catch (_) {
      _network = true;
    }
    _networkChecked = now;
    return _network;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    listener.cancel();
    speaker.stop();
    super.dispose();
  }
}
