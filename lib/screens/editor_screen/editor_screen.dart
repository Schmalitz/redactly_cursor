import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/screens/action_bar.dart';
import 'package:anonymizer/screens/desktop_shell.dart';
import 'package:anonymizer/screens/editor_screen/widgets/original_text_column.dart';
import 'package:anonymizer/screens/editor_screen/widgets/placeholder_column.dart';
import 'package:anonymizer/screens/editor_screen/widgets/preview_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------- HighlightingTextController & helpers ----------
class HighlightingTextController extends TextEditingController {
  List<PlaceholderMapping> mappings;
  bool isCaseSensitiveForSearch;
  bool isWholeWordForSearch;
  String searchQuery;
  int activeSearchMatchIndex;

  HighlightingTextController({
    required this.mappings,
    required this.isCaseSensitiveForSearch,
    required this.isWholeWordForSearch,
    required this.searchQuery,
    required this.activeSearchMatchIndex,
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

    for (final mapping in mappings) {
      if (mapping.originalText.isEmpty) continue;
      final pattern = mapping.isWholeWord
          ? '\\b${RegExp.escape(mapping.originalText)}\\b'
          : RegExp.escape(mapping.originalText);
      final regex = RegExp(pattern, caseSensitive: mapping.isCaseSensitive);
      for (final m in regex.allMatches(text)) {
        all.add(_MatchResult(m, _MatchType.placeholder, mapping: mapping));
      }
    }

    if (searchQuery.isNotEmpty) {
      final pattern = isWholeWordForSearch
          ? '\\b${RegExp.escape(searchQuery)}\\b'
          : RegExp.escape(searchQuery);
      final regex = RegExp(pattern, caseSensitive: isCaseSensitiveForSearch);
      for (final m in regex.allMatches(text)) {
        all.add(_MatchResult(m, _MatchType.search));
      }
    }

    all.sort((a, b) => a.match.start.compareTo(b.match.start));

    final filtered = <_MatchResult>[];
    int cursor = -1;
    for (final r in all) {
      if (r.match.start >= cursor) {
        filtered.add(r);
        cursor = r.match.end;
      }
    }

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

// --------------------------- EditorScreen ---------------------------
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final HighlightingTextController _controller;

  // ScrollController je Spalte
  final ScrollController _origScroll = ScrollController();
  final ScrollController _phScroll   = ScrollController(); // vertikal PH
  final ScrollController _phHScroll  = ScrollController(); // horizontal PH
  final ScrollController _prevScroll = ScrollController();

  // Wunschbreite der Inhalte in der Placeholder-Spalte (bleibt konstant)
  static const double phContentWidth    = 280; // Innen
  static const double phVisibleMaxWidth = 300; // Außen-Viewport max
  static const double phOuterLR         = 6;   // Außenabstand links/rechts

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).initialize();
    });

    _controller = HighlightingTextController(
      mappings: ref.read(placeholderMappingProvider),
      text: ref.read(textInputProvider),
      isCaseSensitiveForSearch: ref.read(caseSensitiveProvider),
      isWholeWordForSearch: ref.read(wholeWordProvider),
      searchQuery: ref.read(searchQueryProvider),
      activeSearchMatchIndex: ref.read(activeSearchMatchIndexProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _origScroll.dispose();
    _phScroll.dispose();
    _phHScroll.dispose();
    _prevScroll.dispose();
    super.dispose();
  }

  // --- Search helpers ---
  List<RegExpMatch> _getSearchMatches() {
    final query = ref.read(searchQueryProvider);
    final isCaseSensitive = ref.read(caseSensitiveProvider);
    final isWholeWord = ref.read(wholeWordProvider);
    if (query.isEmpty) return [];
    final pattern = isWholeWord ? '\\b${RegExp.escape(query)}\\b' : RegExp.escape(query);
    return RegExp(pattern, caseSensitive: isCaseSensitive).allMatches(_controller.text).toList();
  }

  void _findAndActivateFirstMatch() {
    final matches = _getSearchMatches();
    if (matches.isNotEmpty) {
      ref.read(activeSearchMatchIndexProvider.notifier).state = 0;
      final first = matches[0];
      _controller.selection = TextSelection(baseOffset: first.start, extentOffset: first.end);
    } else {
      ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
    }
  }

  void _findNext() {
    final matches = _getSearchMatches();
    if (matches.isEmpty) return;
    final current = ref.read(activeSearchMatchIndexProvider);
    int next = current + 1;
    if (next >= matches.length) next = 0;
    ref.read(activeSearchMatchIndexProvider.notifier).state = next;
    final m = matches[next];
    _controller.selection = TextSelection(baseOffset: m.start, extentOffset: m.end);
  }

  void _replace() {
    final matches = _getSearchMatches();
    final idx = ref.read(activeSearchMatchIndexProvider);
    if (matches.isEmpty || idx < 0 || idx >= matches.length) {
      _findNext();
      return;
    }
    final m = matches[idx];
    final replaceWith = ref.read(replaceQueryProvider);
    final newText = _controller.text.replaceRange(m.start, m.end, replaceWith);
    ref.read(textInputProvider.notifier).state = newText;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newMatches = _getSearchMatches();
      if (newMatches.isEmpty) {
        ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
        return;
      }
      int nextIndex = newMatches.indexWhere((x) => x.start >= m.start);
      if (nextIndex == -1) nextIndex = 0;
      ref.read(activeSearchMatchIndexProvider.notifier).state = nextIndex;
      final nm = newMatches[nextIndex];
      _controller.selection = TextSelection(baseOffset: nm.start, extentOffset: nm.end);
    });
  }

  void _replaceAll() {
    final query = ref.read(searchQueryProvider);
    final replaceWith = ref.read(replaceQueryProvider);
    final isCaseSensitive = ref.read(caseSensitiveProvider);
    final isWholeWord = ref.read(wholeWordProvider);
    if (query.isEmpty) return;
    final pattern = isWholeWord ? '\\b${RegExp.escape(query)}\\b' : RegExp.escape(query);
    final regex = RegExp(pattern, caseSensitive: isCaseSensitive);
    final newText = _controller.text.replaceAll(regex, replaceWith);
    ref.read(textInputProvider.notifier).state = newText;
    ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
  }

  @override
  Widget build(BuildContext context) {
    _controller.mappings                 = ref.watch(placeholderMappingProvider);
    _controller.isCaseSensitiveForSearch = ref.watch(caseSensitiveProvider);
    _controller.isWholeWordForSearch     = ref.watch(wholeWordProvider);
    _controller.searchQuery              = ref.watch(searchQueryProvider);
    _controller.activeSearchMatchIndex   = ref.watch(activeSearchMatchIndexProvider);

    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (next.isNotEmpty) {
        _findAndActivateFirstMatch();
      } else {
        ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
      }
    });

    ref.listen<String>(textInputProvider, (prev, next) {
      if (_controller.text != next) {
        final sel = _controller.selection;
        _controller.text = next;
        if (sel.start <= next.length && sel.end <= next.length) {
          _controller.selection = sel;
        }
      }
    });

    return DesktopShell(
      titleBarHeight: 60,
      sidebarWidth: 260,
      collapsedWidth: 0,
      editor: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original
                Expanded(
                  flex: 2,
                  child: OriginalTextColumn(
                    controller: _controller,
                    onFindNext: _findNext,
                    onReplace: _replace,
                    onReplaceAll: _replaceAll,
                  ),
                ),

                // Placeholders – nimmt Platz, aber nie mehr als _phMaxVisibleWidth.
                // Bei Unterschreitung der _phContentWidth scrollt die Spalte horizontal.
                Flexible(
                  fit: FlexFit.loose,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // sichtbare Außenbreite auf sinnvollen Max-Wert kappen
                      final double outerWidth = constraints.maxWidth < phVisibleMaxWidth
                          ? constraints.maxWidth
                          : phVisibleMaxWidth;

                      return SizedBox(
                        width: outerWidth, // ← sichtbare (responsive) Breite
                        child: PlaceholderColumn(
                          verticalController: _phScroll,
                          horizontalController: _phHScroll,
                          contentWidth: phContentWidth, // ← feste Innenbreite
                          outerPaddingLR: phOuterLR,    // ← Außenabstand feinjustieren
                        ),
                      );
                    },
                  ),
                ),

                // Preview
                Expanded(
                  flex: 2,
                  child: PreviewColumn(scrollController: _prevScroll),
                ),
              ],
            ),
          ),

          // ActionBar bleibt unten
          ActionBar(controller: _controller),
        ],
      ),
    );
  }
}
