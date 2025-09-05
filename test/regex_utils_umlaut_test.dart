import 'package:flutter_test/flutter_test.dart';
import 'package:redactly/utils/regex_utils.dart';

int matchCount({
  required String text,
  required String needle,
  required bool wholeWord,
  bool caseSensitive = true,
}) {
  final re = buildNeedleRegex(
    needle: needle,
    wholeWord: wholeWord,
    caseSensitive: caseSensitive,
  );
  return re.allMatches(text).length;
}

void main() {
  group('buildNeedleRegex – Umlaut-leading words (wholeWord=true)', () {
    test('matches word starting with Umlaut at start of string', () {
      final text = 'Öde und leer liegt das Land.';
      expect(
        matchCount(text: text, needle: 'Öde', wholeWord: true),
        1,
        reason: 'Öde am String-Anfang muss als ganzes Wort erkannt werden.',
      );
    });

    test('matches word starting with Umlaut after whitespace', () {
      final text = 'Es ist Öde hier.';
      expect(
        matchCount(text: text, needle: 'Öde', wholeWord: true),
        1,
        reason: 'Öde nach Leerzeichen muss matchen.',
      );
    });

    test('matches word starting with Umlaut after punctuation', () {
      final text = 'Naja. Öde ist es trotzdem.';
      expect(
        matchCount(text: text, needle: 'Öde', wholeWord: true),
        1,
        reason: 'Öde nach Punkt muss matchen.',
      );
    });

    test('matches reines Umlaut-Wort (nur Umlaut-Zeichen)', () {
      final text = 'Öööö äää';
      expect(
        matchCount(text: text, needle: 'Öööö', wholeWord: true),
        1,
        reason: 'Reine Umlaut-Sequenz am Anfang muss matchen.',
      );
      expect(
        matchCount(text: text, needle: 'äää', wholeWord: true),
        1,
        reason: 'Reine Umlaut-Sequenz nach Leerzeichen muss matchen.',
      );
    });

    test('still matches mixed words like Döner (regression)', () {
      final text = 'Döner, bitte zwei Döner!';
      expect(
        matchCount(text: text, needle: 'Döner', wholeWord: true),
        2,
        reason: 'Baseline sichert das bestehende Verhalten ab.',
      );
    });

    test('does NOT match inside longer words when wholeWord=true', () {
      final text = 'Ödehaft wirkt das.';
      expect(
        matchCount(text: text, needle: 'Öde', wholeWord: true),
        0,
        reason: 'Öde in Ödehaft ist kein Ganzwort-Match.',
      );
    });

    test('case-insensitive also works for Umlaut-leading words', () {
      final text = 'öde? ÖDE! Öde.';
      expect(
        matchCount(text: text, needle: 'Öde', wholeWord: true, caseSensitive: false),
        3,
      );
    });
  });
}
