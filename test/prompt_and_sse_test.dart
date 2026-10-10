import 'package:flutter_test/flutter_test.dart';
import 'package:translator/logic/interpreter_prompt.dart';
import 'package:translator/logic/sse_text.dart';

void main() {
  test('prompt carries conversation context and the new utterance', () {
    final prompt = buildInterpreterPrompt(
      sourceLanguage: 'English',
      targetLanguage: 'Tiếng Việt',
      utterance: 'Where is the station?',
      context: const [DialogueTurn(source: 'Hello', translation: 'Xin chào')],
    );
    expect(prompt, contains('English'));
    expect(prompt, contains('Tiếng Việt'));
    expect(prompt, contains('Hello => Xin chào'));
    expect(prompt, contains('Where is the station?'));
    expect(prompt, contains('only the translation'));
  });

  test('reads streamed Gemini and OpenAI deltas', () {
    expect(
      textFromGeminiEvent({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Xin '},
                {'text': 'chào'},
              ],
            },
          },
        ],
      }),
      'Xin chào',
    );
    expect(
      textFromOpenAiEvent({
        'choices': [
          {
            'delta': {'content': 'Xin chào'},
          },
        ],
      }),
      'Xin chào',
    );
    expect(errorMessageFromBody({'error': {'message': 'bad key'}}), 'bad key');
  });
}
