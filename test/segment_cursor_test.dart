import 'package:flutter_test/flutter_test.dart';
import 'package:translator/logic/segment_cursor.dart';

void main() {
  test('emits a finished sentence and keeps the tail', () {
    final cursor = SegmentCursor();
    expect(cursor.take(fullText: 'Hello there', flush: false), isEmpty);
    expect(cursor.take(fullText: 'Hello there. How are', flush: false), ['Hello there.']);
    expect(cursor.peek('Hello there. How are'), 'How are');
  });

  test('does not repeat a sentence that was already emitted', () {
    final cursor = SegmentCursor();
    cursor.take(fullText: 'Hello there. How are', flush: false);
    expect(cursor.take(fullText: 'Hello there. How are you?', flush: false), ['How are you?']);
    expect(cursor.take(fullText: 'Hello there. How are you?', flush: true), isEmpty);
  });

  test('flush sends the unfinished tail once', () {
    final cursor = SegmentCursor();
    cursor.take(fullText: 'Xin chào. Tôi đang', flush: false);
    expect(cursor.take(fullText: 'Xin chào. Tôi đang nói', flush: true), ['Tôi đang nói']);
  });

  test('a long clause can break on a comma', () {
    final cursor = SegmentCursor();
    const text = 'This is a fairly long spoken clause without a period, and then more words follow after it';
    expect(cursor.take(fullText: text, flush: false), [
      'This is a fairly long spoken clause without a period,',
    ]);
  });
}
