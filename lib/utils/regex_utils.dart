import 'package:flutter/foundation.dart';

/// Unicode-"Wortzeichen": ASCII + Latin-1 + Latin Extended-A/B + Combining Diacritics.
/// Deckt u. a. ÄÖÜäöüß sowie kombinierende Zeichen ab.
const String kWordCharClass =
    r'A-Za-z0-9_'                  // ASCII
    r'\u00C0-\u00D6'              // À-Ö
    r'\u00D8-\u00F6'              // Ø-ö
    r'\u00F8-\u00FF'              // ø-ÿ
    r'\u0100-\u017F'              // Latin Extended-A
    r'\u0180-\u024F'              // Latin Extended-B
    r'\u0300-\u036F';             // Combining Diacritical Marks

// Mapping für Umlaut-Diakritikum (Trema, U+0308)
const _diaeresisPrecomposedByBase = <String, String>{
  'A': 'Ä', 'a': 'ä',
  'E': 'Ë', 'e': 'ë',
  'I': 'Ï', 'i': 'ï',
  'O': 'Ö', 'o': 'ö',
  'U': 'Ü', 'u': 'ü',
  'Y': 'Ÿ', 'y': 'ÿ',
};
const _diaeresisBaseByPrecomposed = <String, String>{
  'Ä': 'A', 'ä': 'a',
  'Ë': 'E', 'ë': 'e',
  'Ï': 'I', 'ï': 'i',
  'Ö': 'O', 'ö': 'o',
  'Ü': 'U', 'ü': 'u',
  'Ÿ': 'Y', 'ÿ': 'y',
};

/// Baut einen Literal-Pattern-String, der **precomposed** (Ä) und **decomposed**
/// (A + \u0308) Varianten gleichermaßen matcht. Alle nicht betroffenen Zeichen
/// werden sicher escaped.
String _needleToLiteralWithDiaeresisVariants(String s) {
  final buf = StringBuffer();
  int i = 0;
  while (i < s.length) {
    final ch = s[i];

    // Fall 1: decomposed (Base + U+0308)
    if (i + 1 < s.length && s.codeUnitAt(i + 1) == 0x0308) {
      final base = ch;
      final pre = _diaeresisPrecomposedByBase[base];
      if (pre != null) {
        // (?:Ä|A\u0308)
        buf.write('(?:${RegExp.escape(pre)}|${RegExp.escape(base)}\u0308)');
        i += 2;
        continue;
      }
    }

    // Fall 2: precomposed (Ä)
    final baseForPre = _diaeresisBaseByPrecomposed[ch];
    if (baseForPre != null) {
      // (?:Ä|A\u0308)
      buf.write('(?:${RegExp.escape(ch)}|${RegExp.escape(baseForPre)}\u0308)');
      i += 1;
      continue;
    }

    // Sonst: normales Literal
    buf.write(RegExp.escape(ch));
    i += 1;
  }
  return buf.toString();
}

/// Ganzwort-Match mit sicherem String-/Zeilengrenzen-Fallback:
/// - Anfang: (^|(?<![WORD]))
/// - Ende:   ($|(?![WORD]))
RegExp buildNeedleRegex({
  required String needle,
  required bool wholeWord,
  required bool caseSensitive,
}) {
  final literal = _needleToLiteralWithDiaeresisVariants(needle);
  if (!wholeWord) {
    return RegExp(literal, caseSensitive: caseSensitive);
  }
  final pattern =
      r'(^|(?<![' + kWordCharClass + r']))' + literal + r'($|(?![' + kWordCharClass + r']))';
  return RegExp(pattern, caseSensitive: caseSensitive);
}

/// Placeholder immer exakt (literal)
RegExp buildPlaceholderRegex(String placeholder) {
  return RegExp(RegExp.escape(placeholder), caseSensitive: true);
}
