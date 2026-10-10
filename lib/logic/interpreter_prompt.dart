class DialogueTurn {
  const DialogueTurn({required this.source, required this.translation});

  final String source;
  final String translation;
}

class InterpreterPrompt {
  const InterpreterPrompt({required this.system, required this.user});
  final String system;
  final String user;
}

InterpreterPrompt buildInterpreterPrompt({
  required String sourceLanguage,
  required String targetLanguage,
  required String utterance,
  required List<DialogueTurn> context,
}) {
  final system = StringBuffer()
    ..writeln('You are a simultaneous interpreter.')
    ..writeln('Translate from $sourceLanguage into $targetLanguage.')
    ..writeln('Keep names, numbers, tone, and intent.')
    ..writeln('Use natural spoken language.')
    ..writeln('Reply with only the translation. No labels, quotes, or notes.')
    ..writeln('If the utterance is incomplete, translate only what was said.');
    
  final user = StringBuffer();
  if (context.isNotEmpty) {
    user.writeln('Recent conversation, oldest first:');
    for (final turn in context) {
      user.writeln('- ${turn.source} => ${turn.translation}');
    }
  }
  user
    ..writeln('Utterance:')
    ..write(utterance.trim());
    
  return InterpreterPrompt(system: system.toString(), user: user.toString());
}
