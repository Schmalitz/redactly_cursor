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

  // Wunschbreite der Inhalte in der Placeholder-Spalte
  static const double phContentWidth     = 260;
  static const double phVisibleMaxWidth  = 280;
  static const double phVisibleMinWidth  = 120;
  static const double phPreferredFraction = 0.18;
  static const double phOuterLR          = 6;

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

  @override
  Widget build(BuildContext context) {
    _controller.mappings                 = ref.watch(placeholderMappingProvider);
    _controller.isCaseSensitiveForSearch = ref.watch(caseSensitiveProvider);
    _controller.isWholeWordForSearch     = ref.watch(wholeWordProvider);
    _controller.searchQuery              = ref.watch(searchQueryProvider);
    _controller.activeSearchMatchIndex   = ref.watch(activeSearchMatchIndexProvider);

    final isEmpty = ref.watch(placeholderMappingProvider).isEmpty;

    return DesktopShell(
      titleBarHeight: 60,
      sidebarWidth: 260,
      collapsedWidth: 0,
      editor: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final total = constraints.maxWidth;
                final preferred = total * phPreferredFraction;
                final phVisibleWidth = preferred
                    .clamp(phVisibleMinWidth, phVisibleMaxWidth)
                    .toDouble();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original
                    Expanded(
                      flex: 2,
                      child: OriginalTextColumn(
                        controller: _controller,
                        scrollController: _origScroll,
                        onFindNext: () {}, // deine Logik bleibt
                        onReplace: () {},
                        onReplaceAll: () {},
                      ),
                    ),

                    // Placeholders – responsive Min/Max
                    SizedBox(
                      width: phVisibleWidth,
                      child: PlaceholderColumn(
                        verticalController: _phScroll,
                        horizontalController: _phHScroll,
                        contentWidth: phContentWidth,
                        outerPaddingLR: phOuterLR,
                        isEmpty: isEmpty,
                      ),
                    ),

                    // Preview
                    Expanded(
                      flex: 2,
                      child: PreviewColumn(scrollController: _prevScroll),
                    ),
                  ],
                );
              },
            ),
          ),

          // ActionBar bleibt
          ActionBar(controller: _controller),
        ],
      ),
    );
  }
}
