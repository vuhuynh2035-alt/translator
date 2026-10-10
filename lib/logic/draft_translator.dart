import 'translation_memory.dart';

class DraftTranslator {
  DraftTranslator({required this.translate, TranslationMemory? memory}) : memory = memory ?? TranslationMemory();

  final Future<String> Function(String text) translate;
  final TranslationMemory memory;
  String scope = '';

  Future<void>? _flight;
  String? _queued;
  String? _queuedScope;
  String? _inflightText;
  String? _inflightScope;

  void anticipate(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 6) return;
    if (memory.lookup(trimmed, scope: scope) != null) return;
    _queued = trimmed;
    _queuedScope = scope;
    _flight ??= _pump();
  }

  bool isWorkingOn(String text) {
    final key = TranslationMemory.normalize(text);
    if (key.isEmpty || _flight == null) return false;
    if (_matches(_queued, _queuedScope, key)) return true;
    return _matches(_inflightText, _inflightScope, key);
  }

  bool _matches(String? candidate, String? candidateScope, String key) {
    return candidate != null && candidateScope == scope && TranslationMemory.normalize(candidate) == key;
  }

  Future<String> resolve(String text) async {
    final trimmed = text.trim();
    final activeScope = scope;
    while (true) {
      final cached = memory.lookup(trimmed, scope: activeScope);
      if (cached != null) return cached;
      final flight = _flight;
      if (flight == null) break;
      await flight;
    }
    final value = await translate(trimmed);
    memory.store(trimmed, value, scope: activeScope);
    return value;
  }

  Future<void> _pump() async {
    while (_queued != null) {
      final text = _queued!;
      final activeScope = _queuedScope ?? scope;
      _queued = null;
      _queuedScope = null;
      _inflightText = text;
      _inflightScope = activeScope;
      if (memory.lookup(text, scope: activeScope) != null) {
        _inflightText = null;
        _inflightScope = null;
        continue;
      }
      try {
        final value = await translate(text);
        memory.store(text, value, scope: activeScope);
      } catch (_) {
        // The explicit resolve call reports the failure.
      }
      _inflightText = null;
      _inflightScope = null;
    }
    _flight = null;
    if (_queued != null) _flight = _pump();
  }
}
