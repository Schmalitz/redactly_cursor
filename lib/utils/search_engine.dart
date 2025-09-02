import 'package:anonymizer/utils/regex_utils.dart';

/// Kleine, UI-freie Hilfsklasse für Suche/Ersetzen-Flows.
/// Damit sichern wir die Logik mit `dart test` ab (ohne Flutter-UI).
class SearchEngine {
  static RegExp build({
    required String query,
    required bool wholeWord,
    required bool caseSensitive,
  }) {
    if (query.isEmpty) return RegExp(r'(?!x)x'); // match nothing
    return wholeWord
        ? buildNeedleRegex(needle: query, wholeWord: true, caseSensitive: caseSensitive)
        : RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
  }

  static List<RegExpMatch> matches(String text, RegExp re) =>
      re.allMatches(text).toList();

  static int nextIndex(int current, int total) =>
      total == 0 ? -1 : (current + 1) % total;

  static String replaceActive({
    required String text,
    required List<RegExpMatch> matches,
    required int index,
    required String replacement,
  }) {
    if (index < 0 || index >= matches.length) return text;
    final m = matches[index];
    return text.replaceRange(m.start, m.end, replacement);
  }

  static String replaceAll({
    required String text,
    required RegExp re,
    required String replacement,
  }) =>
      text.replaceAll(re, replacement);
}
