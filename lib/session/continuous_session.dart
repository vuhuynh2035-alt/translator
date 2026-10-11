import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../logic/clause_splitter.dart';
import '../logic/draft_translator.dart';
import '../logic/interpreter_prompt.dart';
import '../logic/segment_cursor.dart';
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

class Caption {
  const Caption({required this.source, required this.translation, required this.latencyMs});

  final String source;
  final String translation;
  final int latencyMs;
}

class ContinuousSession extends ChangeNotifier {
  ContinuousSession({
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
    draft = DraftTranslator(translate: _translatePlain, memory: this.memory);
  }

  final SettingsStore settings;
  final OfflineTranslator offline;
  final http.Client client;
  final SpeechListener listener;
  final SpeechSpeaker speaker;
  final AudioRoute audioRoute;
  final TranslationMemory memory;
  late final DraftTranslator draft;
  final cursor = SegmentCursor();
  final history = <Caption>[];
  final context = <DialogueTurn>[];
  final fullHistory = <DialogueTurn>[];

  bool running = false;
  String phase = 'Sẵn sàng';
  String livePartial = '';
  String liveTranslation = '';
  String? error;
  String? notice;
  int? lastLatencyMs;
  double sound = 0;

  Timer? _debounce;
  Future<void> _pipeline = Future<void>.value();
  bool _network = true;
  DateTime? _networkChecked;

  Future<void> start() async {
    if (running) return;
    error = null;
    notice = null;
    listener.onError = (message) {
      if (message.isEmpty) return;
      error = message;
      notifyListeners();
    };
    final ready = await listener.ensureReady();
    if (!ready) {
      error = 'Máy không khởi động được nhận dạng giọng nói.';
      notifyListeners();
      return;
    }
    running = true;
    phase = 'Đang nghe';
    notifyListeners();
    unawaited(_run());
  }

  Future<void> stop() async {
    running = false;
    _debounce?.cancel();
    final pending = cursor.peek(livePartial);
    await listener.cancel();
    cursor.reset();
    if (pending.trim().isNotEmpty) _enqueue(pending);
    await _pipeline;
    livePartial = '';
    phase = 'Sẵn sàng';
    notifyListeners();
  }

  Future<void> replay(String text) async {
    final current = settings.settings;
    if (!current.speaks) return;
    final target = AppLanguage.byCode(current.myLanguage);
    await audioRoute.apply(current.playback);
    await speaker.speak(text, target.ttsLocale, rate: current.ttsRate, pitch: current.ttsPitch);
  }

  void clear() {
    history.clear();
    context.clear();
    fullHistory.clear();
    notifyListeners();
  }

  String exportTranscript() {
    final buffer = StringBuffer();
    final current = settings.settings;
    buffer.writeln('Cuộc hội thoại Liên tục (${current.heardLanguage} -> ${current.myLanguage}):');
    buffer.writeln('Thời gian: ${DateTime.now().toLocal()}');
    buffer.writeln('--------------------------------------------------\n');
    for (final turn in fullHistory) {
      buffer.writeln('Nguồn: ${turn.source}');
      buffer.writeln('Dịch: ${turn.translation}\n');
    }
    return buffer.toString();
  }

  Future<void> _run() async {
    while (running) {
      var hadError = false;
      try {
        await _listenOnce();
        await listener.waitUntilIdle();
        if (!settings.settings.effectiveOverlap) await _pipeline;
      } catch (_) {
        hadError = true;
      }
      if (running) {
        if (hadError || error != null) {
          try {
            await listener.cancel();
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 600));
          await listener.ensureReady();
          error = null;
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    }
  }

  Future<void> _listenOnce() async {
    final current = settings.settings;
    final heard = AppLanguage.byCode(current.heardLanguage);
    phase = 'Đang nghe';
    notifyListeners();
    
    await audioRoute.release();
    
    Timer? silenceTimer;
    
    await listener.listen(
      localeId: heard.sttLocale,
      onDevice: current.engine == EngineMode.offline,
      pauseFor: const Duration(seconds: 10), // Let OS keep mic open, we manage silence manually
      listenFor: const Duration(seconds: 60),
      onLevel: _onLevel,
      onText: (text, isFinal) {
        if (!isFinal) {
          livePartial = text;
          _scheduleDraft(cursor.peek(text));
          for (final piece in cursor.take(fullText: text, flush: false)) {
            _enqueue(piece);
          }
          
          silenceTimer?.cancel();
          if (text.trim().isNotEmpty) {
            final silence = current.silenceMs.clamp(400, 1000);
            silenceTimer = Timer(Duration(milliseconds: silence), () {
              if (running) listener.stop();
            });
          }
        } else {
          silenceTimer?.cancel();
          _debounce?.cancel();
          for (final piece in cursor.take(fullText: text, flush: true)) {
            _enqueue(piece);
          }
          cursor.reset();
          livePartial = '';
        }
        notifyListeners();
      },
    );
    silenceTimer?.cancel();
  }

  void _onLevel(double level) {
    sound = level;
    notifyListeners();
  }

  void _scheduleDraft(String pending) {
    _debounce?.cancel();
    if (pending.trim().length < 6) return;
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _bindScope();
      draft.anticipate(pending);
    });
  }

  void _bindScope() {
    final current = settings.settings;
    draft.scope = '${current.heardLanguage}>${current.myLanguage}';
  }

  void _enqueue(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _pipeline = _pipeline.then((_) => _consume(trimmed));
  }

  Future<void> _consume(String source) async {
    final started = Stopwatch()..start();
    var spoke = false;
    _bindScope();
    try {
      if (memory.lookup(source, scope: draft.scope) != null || draft.isWorkingOn(source)) {
        final translation = await draft.resolve(source);
        await _presentReady(source, translation, started, () => spoke = true);
        return;
      }
      await _presentStream(source, started, () => spoke = true);
    } catch (caught) {
      if (!spoke && settings.settings.engine == EngineMode.online) {
        try {
          notice = 'AI không trả lời kịp. Đang dùng bản dịch trên máy.';
          final translation = await _collect(OfflineEngine(offline), source);
          await _presentReady(source, translation, started, () => spoke = true);
          return;
        } catch (_) {}
      }
      error = caught is TranslationException ? caught.message : 'Không dịch được câu vừa nghe.';
      notifyListeners();
    }
  }

  Future<void> _presentReady(String source, String translation, Stopwatch started, void Function() onSpoke) async {
    final clean = translation.trim();
    if (clean.isEmpty) return;
    _remember(source, clean, started.elapsedMilliseconds);
    final spoken = _speak(clean);
    if (!settings.settings.effectiveOverlap) {
      await spoken;
      onSpoke();
    } else {
      unawaited(spoken.then((_) => onSpoke()));
    }
  }

  Future<void> _presentStream(String source, Stopwatch started, void Function() onSpoke) async {
    final engine = await _engine();
    final request = _request(source);
    final buffer = StringBuffer();
    final splitter = ClauseSplitter();
    var marked = false;
    var voiced = false;
    Future<void>? tail;
    await for (final token in engine.translate(request)) {
      buffer.write(token);
      liveTranslation = buffer.toString().trim();
      if (!marked) {
        marked = true;
        lastLatencyMs = started.elapsedMilliseconds;
        phase = 'Đang dịch';
      }
      if (settings.settings.speaks) {
        for (final clause in splitter.add(token)) {
          tail = _speak(clause);
          if (!voiced) {
            voiced = true;
            onSpoke();
          }
        }
      }
      notifyListeners();
    }
    if (settings.settings.speaks) {
      for (final clause in splitter.flush()) {
        tail = _speak(clause);
        if (!voiced) {
          voiced = true;
          onSpoke();
        }
      }
    }
    final clean = buffer.toString().trim();
    if (clean.isEmpty) return;
    memory.store(source, clean, scope: draft.scope);
    _remember(source, clean, lastLatencyMs ?? started.elapsedMilliseconds);
    if (!settings.settings.effectiveOverlap && tail != null) await tail;
  }

  void _remember(String source, String translation, int latency) {
    lastLatencyMs = latency;
    liveTranslation = translation;
    history.add(Caption(source: source, translation: translation, latencyMs: latency));
    if (history.length > 30) history.removeAt(0);
    final turn = DialogueTurn(source: source, translation: translation);
    context.add(turn);
    if (context.length > 6) context.removeAt(0);
    fullHistory.add(turn);
    phase = settings.settings.speaks ? 'Đang nói' : 'Đã dịch';
    if (running && !settings.settings.speaks) phase = 'Đang nghe';
    notifyListeners();
  }

  Future<void> _speak(String text) async {
    final current = settings.settings;
    if (!current.speaks) return;
    final target = AppLanguage.byCode(current.myLanguage);
    await audioRoute.apply(current.playback);
    phase = 'Đang nói';
    notifyListeners();
    try {
      await speaker.speak(text, target.ttsLocale, rate: current.ttsRate, pitch: current.ttsPitch);
    } finally {
      await audioRoute.release();
      if (running) {
        phase = 'Đang nghe';
        notifyListeners();
      }
    }
  }

  Future<String> _translatePlain(String text) => _collect(null, text);

  Future<String> _collect(TranslationEngine? engine, String text) async {
    final active = engine ?? await _engine();
    final buffer = StringBuffer();
    await for (final token in active.translate(_request(text))) {
      buffer.write(token);
    }
    return buffer.toString().trim();
  }

  Future<TranslationEngine> _engine() async {
    final current = settings.settings;
    if (current.engine == EngineMode.offline || !await _hasNetwork()) {
      if (current.engine == EngineMode.online) {
        notice = 'Không có mạng. Đang dùng bản dịch trên máy.';
      }
      return OfflineEngine(offline);
    }
    return OnlineTranslator(client: client, settings: () => settings.settings);
  }

  TranslationRequest _request(String text) {
    final current = settings.settings;
    return TranslationRequest(
      text: text,
      from: AppLanguage.byCode(current.heardLanguage),
      to: AppLanguage.byCode(current.myLanguage),
      context: List<DialogueTurn>.from(context),
    );
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
    running = false;
    _debounce?.cancel();
    listener.cancel();
    speaker.stop();
    super.dispose();
  }
}
