import 'package:flutter_test/flutter_test.dart';
import 'package:anonymizer/utils/search_engine.dart';

void main() {
  group('SearchEngine', () {
    test('find + wrap-around', () {
      final re = SearchEngine.build(query: 'Öde', wholeWord: true, caseSensitive: true);
      final ms = SearchEngine.matches('Öde x Öde', re);
      expect(ms.length, 2);
      expect(SearchEngine.nextIndex(-1, ms.length), 0);
      expect(SearchEngine.nextIndex(0, ms.length), 1);
      expect(SearchEngine.nextIndex(1, ms.length), 0);
    });

    test('replace active', () {
      final text = 'Öde und Öde';
      final re = SearchEngine.build(query: 'Öde', wholeWord: true, caseSensitive: true);
      final ms = SearchEngine.matches(text, re);
      final t2 = SearchEngine.replaceActive(
        text: text, matches: ms, index: 0, replacement: 'X',
      );
      expect(t2, 'X und Öde');
    });

    test('replace all', () {
      final text = 'Öde. Öde! Öde?';
      final re = SearchEngine.build(query: 'Öde', wholeWord: true, caseSensitive: true);
      final t2 = SearchEngine.replaceAll(text: text, re: re, replacement: 'X');
      expect(t2, 'X. X! X?');
    });

    test('case-insensitive & combining diacritics', () {
      final text = 'O\u0308de ÖDE öde'; // decomposed + uppercase + lowercase
      final re = SearchEngine.build(query: 'Öde', wholeWord: true, caseSensitive: false);
      final ms = SearchEngine.matches(text, re);
      expect(ms.length, 3);
    });
  });
}
