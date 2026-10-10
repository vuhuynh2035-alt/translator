import 'package:flutter_test/flutter_test.dart';
import 'package:translator/logic/clause_splitter.dart';

void main() {
  test('speaks the first sentence before the rest is finished', () {
    final splitter = ClauseSplitter();
    expect(splitter.add('Xin chào. Bạn khỏe'), ['Xin chào.']);
    expect(splitter.flush(), ['Bạn khỏe']);
  });

  test('holds a short fragment until it becomes a clause', () {
    final splitter = ClauseSplitter();
    expect(splitter.add('Xin chào, bạn'), isEmpty);
    expect(splitter.flush(), ['Xin chào, bạn']);
  });
}
