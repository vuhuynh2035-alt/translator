import '../../logic/interpreter_prompt.dart';
import '../../models/language.dart';

class TranslationException implements Exception {
  TranslationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TranslationRequest {
  const TranslationRequest({
    required this.text,
    required this.from,
    required this.to,
    required this.context,
  });

  final String text;
  final AppLanguage from;
  final AppLanguage to;
  final List<DialogueTurn> context;
}

abstract class TranslationEngine {
  Stream<String> translate(TranslationRequest request);
}
