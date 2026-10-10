class ClauseSplitter {
  final StringBuffer _buffer = StringBuffer();

  List<String> add(String token) {
    _buffer.write(token);
    return _drain(flush: false);
  }

  List<String> flush() => _drain(flush: true);

  List<String> _drain({required bool flush}) {
    final text = _buffer.toString();
    if (flush) {
      _buffer.clear();
      final trimmed = text.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    final matches = RegExp(r'.+?[.!?。！？,，、;；:：]+(?=\s|$)').allMatches(text);
    if (matches.isEmpty) return const [];
    final end = matches.last.end;
    final chunk = text.substring(0, end).trim();
    final sentence = RegExp(r'[.!?。！？]\s*$').hasMatch(chunk);
    if (!sentence && chunk.length < 24) return const [];
    _buffer
      ..clear()
      ..write(text.substring(end));
    return [chunk];
  }
}
