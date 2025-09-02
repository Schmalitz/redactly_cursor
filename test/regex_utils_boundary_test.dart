import 'package:flutter_test/flutter_test.dart';
import 'package:anonymizer/utils/regex_utils.dart';

int count(String t, String n, {bool whole = true, bool cs = true}) =>
    buildNeedleRegex(needle: n, wholeWord: whole, caseSensitive: cs).allMatches(t).length;

void main() {
  group('Boundary – punctuation & line edges', () {
    test('Klammern', () {
      expect(count('(Öde)', 'Öde'), 1);
      expect(count('[(Öde)]', 'Öde'), 1);
    });

    test('Anführungszeichen', () {
      expect(count('„Öde“', 'Öde'), 1);
      expect(count('"Öde"', 'Öde'), 1);
      expect(count("‚Öde‘", 'Öde'), 1);
    });

    test('Zeilenanfang/-ende', () {
      expect(count('Öde\nnoch was', 'Öde'), 1);
      expect(count('was\nÖde', 'Öde'), 1);
      expect(count('was\nÖde\n', 'Öde'), 1);
    });

    test('Interpunktion ohne false positives', () {
      expect(count('Öde, Öde. Öde! Öde?', 'Öde'), 4);
      expect(count('Ödehaft', 'Öde'), 0);
      expect(count('Das ist nicht-Öde', 'Öde'), 1); // Bindestrich trennt
    });

    test('Combining diacritics (robustness)', () {
      final combining = 'O\u0308de'; // "Ö" als O + combining diaeresis
      expect(count('$combining und leer', 'Öde', cs: false), 1);
    });
  });
}
