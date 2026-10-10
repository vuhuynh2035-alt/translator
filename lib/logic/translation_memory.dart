class TranslationMemory {
  final _entries = <String, String>{};
  static const _limit = 40;

  static String normalize(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  void store(String source, String translation, {String scope = ''}) {
    final key = _key(source, scope);
    final value = translation.trim();
    if (key.isEmpty || value.isEmpty) return;
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > _limit) {
      _entries.remove(_entries.keys.first);
    }
  }

  String? lookup(String source, {String scope = ''}) {
    final key = _key(source, scope);
    if (key.isEmpty) return null;
    return _entries[key];
  }

  static String _key(String source, String scope) {
    final text = normalize(source);
    if (text.isEmpty) return '';
    return '$scope|$text';
  }
}
