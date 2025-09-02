import 'package:flutter_test/flutter_test.dart';
import 'package:anonymizer/utils/regex_utils.dart';

int count(String t, String n, {bool whole = true, bool cs = true}) =>
    buildNeedleRegex(needle: n, wholeWord: whole, caseSensitive: cs).allMatches(t).length;

void main() {
  group('Scope – supported scripts', () {
    test('Latin (with diacritics) supported', () {
      expect(count('Málaga Öde Jürgen', 'Öde'), 1);
      expect(count('Jürgen', 'Jürgen'), 1);
    });

    test('Cyrillic literal works but boundaries are Latin-based (documented)', () {
      expect(count('Русский текст', 'Русский'), 1,
          reason: 'Literal findet es; Wortgrenzen-Definition ist latin-basiert.');
    });

    test('Greek similar note', () {
      expect(count('Ελλάδα', 'Ελλάδα'), 1);
    });
  });
}
