class SegmentCursor {
  String _covered = '';

  String get covered => _covered;

  void reset() => _covered = '';

  String peek(String fullText) => _split(fullText).rest;

  List<String> take({required String fullText, required bool flush}) {
    final split = _split(fullText);
    if (split.rewritten) _covered = '';
    final rest = split.rest;
    if (rest.isEmpty) return const [];
    if (flush) {
      _covered = _normalize(fullText);
      return [rest];
    }
    final pieces = _readyPieces(rest);
    if (pieces.isEmpty) return const [];
    final addition = pieces.join(' ');
    final next = _covered.isEmpty ? addition : '$_covered $addition';
    _covered = _normalize(next);
    return pieces;
  }

  _Split _split(String fullText) {
    final full = _normalize(fullText);
    if (full.isEmpty) return const _Split('', false);
    final covered = _normalize(_covered);
    if (covered.isEmpty) return _Split(full, false);
    if (full.startsWith(covered)) {
      return _Split(full.substring(covered.length).trim(), false);
    }
    return _Split(full, true);
  }

  List<String> _readyPieces(String rest) {
    final sentence = RegExp(r'.+?[.!?。！？]+(?=\s|$)');
    final pieces = <String>[];
    for (final match in sentence.allMatches(rest)) {
      final piece = match.group(0)!.trim();
      if (piece.isNotEmpty) pieces.add(piece);
    }
    if (pieces.isNotEmpty) return pieces;
    if (rest.length < 80) return const [];
    final commas = RegExp(r'[,，、;；]');
    var end = -1;
    for (final match in commas.allMatches(rest)) {
      if (match.end >= 24) end = match.end;
    }
    if (end < 0) return const [];
    return [rest.substring(0, end).trim()];
  }

  static String _normalize(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _Split {
  const _Split(this.rest, this.rewritten);

  final String rest;
  final bool rewritten;
}
