import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/providers/mode_provider.dart';
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

    // <-- HIER: je nach Modus entweder nach OriginalText ODER Placeholder suchen
    for (final mapping in mappings) {
      final needle = highlightPlaceholders ? mapping.placeholder : mapping.originalText;
      if (needle.isEmpty) continue;

      final pattern = (highlightPlaceholders || !mapping.isWholeWord)
          ? RegExp.escape(needle)                           // Placeholder immer exakt
          : '\\b${RegExp.escape(needle)}\\b';               // Whole-Word bei Klartext

      final regex = RegExp(
        pattern,
        caseSensitive: highlightPlaceholders ? true : mapping.isCaseSensitive,
      );

      for (final m in regex.allMatches(text)) {
        all.add(_MatchResult(m, _MatchType.placeholder, mapping: mapping));
      }
    }

    // (Suche bleibt wie bei dir)
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
  static const double phContentWidth      = 260;
  static const double phVisibleMaxWidth   = 280;
  static const double phVisibleMinWidth   = 120;
  static const double phPreferredFraction = 0.18;
  static const double phOuterLR           = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).initialize();
    });

    final mode = ref.read(redactModeProvider);
    final initialText = mode == RedactMode.anonymize
        ? ref.read(anonymizeInputProvider)
        : ref.read(deanonymizeInputProvider);

    _controller = HighlightingTextController(
      mappings: ref.read(placeholderMappingProvider),
      text: initialText,
      isCaseSensitiveForSearch: ref.read(caseSensitiveProvider),
      isWholeWordForSearch: ref.read(wholeWordProvider),
      searchQuery: ref.read(searchQueryProvider),
      activeSearchMatchIndex: ref.read(activeSearchMatchIndexProvider),
      highlightPlaceholders: mode == RedactMode.deanonymize, // wichtig
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
    final mode = ref.watch(redactModeProvider);

    // Wenn sich der aktuell relevante Input ändert -> Controller nachziehen
    ref.listen<String>(
      (mode == RedactMode.anonymize) ? anonymizeInputProvider : deanonymizeInputProvider,
          (prev, next) {
        if (_controller.text == next) return;
        final oldSel = _controller.selection;
        final clamped = oldSel.extentOffset.clamp(0, next.length);
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: clamped),
          composing: TextRange.empty,
        );
      },
    );

    // Beim Moduswechsel: Controller hart auf den jeweils anderen Provider setzen
    ref.listen<RedactMode>(redactModeProvider, (prev, next) {
      final nextText = (next == RedactMode.anonymize)
          ? ref.read(anonymizeInputProvider)
          : ref.read(deanonymizeInputProvider);
      _controller.value = TextEditingValue(
        text: nextText,
        selection: const TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
    });

    // Controller-Flags & Mappings aktualisieren
    _controller.mappings                 = ref.watch(placeholderMappingProvider);
    _controller.isCaseSensitiveForSearch = ref.watch(caseSensitiveProvider);
    _controller.isWholeWordForSearch     = ref.watch(wholeWordProvider);
    _controller.searchQuery              = ref.watch(searchQueryProvider);
    _controller.activeSearchMatchIndex   = ref.watch(activeSearchMatchIndexProvider);
    _controller.highlightPlaceholders    = (mode == RedactMode.deanonymize);

    // Aktiven Input beobachten und kontrolliert in den Controller spiegeln
    final activeInput = mode == RedactMode.anonymize
        ? ref.watch(anonymizeInputProvider)
        : ref.watch(deanonymizeInputProvider);

    if (_controller.text != activeInput) {
      final oldSel = _controller.selection;
      final offset = oldSel.extentOffset.clamp(0, activeInput.length);
      _controller.value = TextEditingValue(
        text: activeInput,
        selection: TextSelection.collapsed(offset: offset),
        composing: TextRange.empty,
      );
    }

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
                    // Input (Modus-sensitiv, aber UI bleibt gleich)
                    Expanded(
                      flex: 2,
                      child: OriginalTextColumn(
                        controller: _controller,
                        scrollController: _origScroll,
                        onFindNext: () {},
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

                    // Preview (Anonymize: forward; De-Anonymize: reverse)
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
