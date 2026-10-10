String? textFromGeminiEvent(Map<String, dynamic> json) {
  final candidates = json['candidates'];
  if (candidates is! List || candidates.isEmpty) return null;
  final first = candidates.first;
  if (first is! Map) return null;
  final content = first['content'];
  if (content is! Map) return null;
  final parts = content['parts'];
  if (parts is! List) return null;
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part is Map && part['text'] is String) buffer.write(part['text']);
  }
  final text = buffer.toString();
  return text.isEmpty ? null : text;
}

String? textFromOpenAiEvent(Map<String, dynamic> json) {
  final choices = json['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final first = choices.first;
  if (first is! Map) return null;
  final delta = first['delta'];
  if (delta is! Map) return null;
  final content = delta['content'];
  return content is String && content.isNotEmpty ? content : null;
}

String? errorMessageFromBody(Map<String, dynamic> json) {
  final error = json['error'];
  if (error is Map && error['message'] is String) return error['message'] as String;
  if (json['message'] is String) return json['message'] as String;
  return null;
}
