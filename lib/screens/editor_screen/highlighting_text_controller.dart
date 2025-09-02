import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/utils/regex_utils.dart';
import 'package:flutter/material.dart';

class HighlightingTextController extends TextEditingController {
  List<PlaceholderMapping> mappings;
  bool isCaseSensitiveForSearch;
  bool isWholeWordForSearch;
  String searchQuery;
  int activeSearchMatchIndex;
  bool highlightPlaceholders;

  HighlightingTextController({
    required this.mappings,
    required this.isCaseSensitiveForSearch,
    required this.isWholeWordForSearch,
    required this.searchQuery,
    required this.activeSearchMatchIndex,
    this.highlightPlaceholders = false,
    String? text,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (text.isEmpty) return TextSpan(text: '', style: style);

    final spans = <InlineSpan>[];
    int lastMatchEnd = 0;
    final all = <_MatchResult>[];

    // Mapping-Highlighting
    for (final mapping in mappings) {
      final needle = highlightPlaceholders ? mapping.placeholder : mapping.originalText;
      if (needle.isEmpty) continue;

      final regex = (highlightPlaceholders || !mapping.isWholeWord)
          ? RegExp(RegExp.escape(needle),
          caseSensitive: highlightPlaceholders ? true : mapping.isCaseSensitive)
          : buildNeedleRegex(
        needle: needle,
        wholeWord: true,
        caseSensitive: highlightPlaceholders ? true : mapping.isCaseSensitive,
      );

      for (final m in regex.allMatches(text)) {
        all.add(_MatchResult(m, _MatchType.placeholder, mapping: mapping));
      }
    }

    // Suche-Highlighting
    if (searchQuery.isNotEmpty) {
      final regex = isWholeWordForSearch
          ? buildNeedleRegex(
        needle: searchQuery,
        wholeWord: true,
        caseSensitive: isCaseSensitiveForSearch,
      )
          : RegExp(RegExp.escape(searchQuery), caseSensitive: isCaseSensitiveForSearch);
      for (final m in regex.allMatches(text)) {
        all.add(_MatchResult(m, _MatchType.search));
      }
    }

    // Sortieren + Überlappungen ausdünnen
    all.sort((a, b) => a.match.start.compareTo(b.match.start));
    final filtered = <_MatchResult>[];
    int cursor = -1;
    for (final r in all) {
      if (r.match.start >= cursor) {
        filtered.add(r);
        cursor = r.match.end;
      }
    }

    // Spans aufbauen
    int searchCounter = 0;
    for (final r in filtered) {
      final m = r.match;
      if (m.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, m.start)));
      }

      if (r.type == _MatchType.placeholder && r.mapping != null) {
        spans.add(TextSpan(
          text: m.group(0)!,
          style: TextStyle(backgroundColor: r.mapping!.color.withOpacity(0.4)),
        ));
      } else if (r.type == _MatchType.search) {
        final isActive = searchCounter == activeSearchMatchIndex;
        spans.add(TextSpan(
          text: m.group(0)!,
          style: TextStyle(
            backgroundColor: isActive ? Colors.pinkAccent : Colors.pink.shade100,
          ),
        ));
        searchCounter++;
      }

      lastMatchEnd = m.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return TextSpan(style: style, children: spans);
  }
}

enum _MatchType { placeholder, search }

class _MatchResult {
  final RegExpMatch match;
  final _MatchType type;
  final PlaceholderMapping? mapping;
  _MatchResult(this.match, this.type, {this.mapping});
}
