import 'package:flutter/foundation.dart';

/// Unicode-"Wortzeichen": ASCII + Latin-1 + Latin Extended-A/B.
/// Enthält u.a. ÄÖÜäöüß usw.
const String kWordCharClass =
    r'A-Za-z0-9_'                  // ASCII
    r'\u00C0-\u00D6'              // À-Ö
    r'\u00D8-\u00F6'              // Ø-ö
    r'\u00F8-\u00FF'              // ø-ÿ
    r'\u0100-\u017F'              // Latin Extended-A
    r'\u0180-\u024F';             // Latin Extended-B

/// Baut ein Regex für einen Literal-Needle.
/// - Bei wholeWord=true: nutzt Lookaround mit obiger Wortzeichenklasse.
/// - Bei wholeWord=false: reiner Literal-Match.
/// `caseSensitive` wird am RegExp gesetzt (nicht in der Pattern-String).
RegExp buildNeedleRegex({
  required String needle,
  required bool wholeWord,
  required bool caseSensitive,
}) {
  final escaped = RegExp.escape(needle);
  final pattern = wholeWord
      ? r'(?<![' + kWordCharClass + r'])' + escaped + r'(?![' + kWordCharClass + r'])'
      : escaped;
  return RegExp(pattern, caseSensitive: caseSensitive);
}

/// Variante, die *immer* exakt (literal) matcht – z.B. für Placeholder.
/// Für Placeholder ist wholeWord gewöhnlich irrelevant.
RegExp buildPlaceholderRegex(String placeholder) {
  return RegExp(RegExp.escape(placeholder), caseSensitive: true);
}
