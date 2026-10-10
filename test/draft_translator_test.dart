import 'package:flutter_test/flutter_test.dart';
import 'package:translator/logic/draft_translator.dart';
import 'package:translator/logic/translation_memory.dart';

void main() {
  test('memory matches text ignoring case and spacing', () {
    final memory = TranslationMemory();
    memory.store('  Hello   there ', 'Xin chào', scope: 'en>vi');
    expect(memory.lookup('hello there', scope: 'en>vi'), 'Xin chào');
    expect(memory.lookup('hello there', scope: 'vi>en'), isNull);
  });

  test('resolve waits for a translation that was started early', () async {
    final draft = DraftTranslator(
      translate: (text) {
        return Future<String>.delayed(const Duration(milliseconds: 20), () => 'dịch $text');
      },
    );
    draft.scope = 'en>vi';
    draft.anticipate('hello there');
    expect(draft.isWorkingOn('hello there'), isTrue);
    expect(await draft.resolve('hello there'), 'dịch hello there');
  });
}
