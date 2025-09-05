import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/providers/placeholder_mapping_provider.dart';
import 'package:redactly/providers/session_provider.dart';
import 'package:redactly/providers/settings_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';
import 'package:redactly/screens/action_bar.dart';
import 'package:redactly/screens/desktop_shell.dart';
import 'package:redactly/screens/editor_screen/highlighting_text_controller.dart';
import 'package:redactly/screens/editor_screen/widgets/original_text_column.dart';
import 'package:redactly/screens/editor_screen/widgets/placeholder_column.dart';
import 'package:redactly/screens/editor_screen/widgets/preview_column.dart';
import 'package:redactly/utils/regex_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final HighlightingTextController _controller;

  // ScrollController je Spalte
  final ScrollController _origScroll = ScrollController();
  final ScrollController _phScroll = ScrollController(); // vertikal PH
  final ScrollController _phHScroll = ScrollController(); // horizontal PH
  final ScrollController _prevScroll = ScrollController();

  // NEU: FocusNode für das Original-Textfeld (nur fürs Scrollen zur Fundstelle)
  final FocusNode _origFocus = FocusNode();

  // Wunschbreite der Inhalte in der Placeholder-Spalte
  static const double phContentWidth = 260;
  static const double phVisibleMaxWidth = 280;
  static const double phVisibleMinWidth = 120;
  static const double phPreferredFraction = 0.18;
  static const double phOuterLR = 6;

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
    _origFocus
        .dispose(); // NEU: FocusNode sauber entsorgen, sonst unverändert
    super.dispose();
  }

  // ---------- Suche/Ersetzen – Logik ----------

  RegExp _buildSearchRegex() {
    final query = ref.read(searchQueryProvider);
    final whole = ref.read(wholeWordProvider);
    final cs = ref.read(caseSensitiveProvider);
    if (query.isEmpty) {
      return RegExp(r'(?!x)x'); // match nothing
    }
    return whole
        ? buildNeedleRegex(needle: query, wholeWord: true, caseSensitive: cs)
        : RegExp(RegExp.escape(query), caseSensitive: cs);
  }

  String _getActiveText() {
    final mode = ref.read(redactModeProvider);
    return (mode == RedactMode.anonymize)
        ? ref.read(anonymizeInputProvider)
        : ref.read(deanonymizeInputProvider);
  }

  void _setActiveText(String t) {
    final mode = ref.read(redactModeProvider);
    if (mode == RedactMode.anonymize) {
      ref.read(anonymizeInputProvider.notifier).state = t;
    } else {
      ref.read(deanonymizeInputProvider.notifier).state = t;
    }
  }

  List<RegExpMatch> _allMatches(String text) {
    final re = _buildSearchRegex();
    return re.allMatches(text).toList();
  }

  void _resetSearchIndex() {
    ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
  }

  void _onFindNext() {
    final text = _getActiveText();
    final matches = _allMatches(text);
    if (matches.isEmpty) {
      _resetSearchIndex();
      return;
    }
    final current = ref.read(activeSearchMatchIndexProvider);
    final next = (current + 1) % matches.length;
    ref.read(activeSearchMatchIndexProvider.notifier).state = next;

    final m = matches[next];

    // NEU: Fokussieren & Caret (collapsed) setzen -> Editor scrollt sicher zur Stelle
    _origFocus.requestFocus();
    _controller.selection = TextSelection.collapsed(offset: m.start);
    // nach dem Frame ans Ende setzen, falls Start knapp am Rand lag (stabileres Scrollen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.selection = TextSelection.collapsed(offset: m.end);
      }
    });
  }

  void _onReplace() {
    final text = _getActiveText();
    final matches = _allMatches(text);
    final idx = ref.read(activeSearchMatchIndexProvider);
    if (idx < 0 || idx >= matches.length) return;

    final repl = ref.read(replaceQueryProvider);
    final m = matches[idx];

    final newText = text.replaceRange(m.start, m.end, repl);
    _setActiveText(newText);

    _resetSearchIndex();
    _onFindNext();
  }

  void _onReplaceAll() {
    final text = _getActiveText();
    final re = _buildSearchRegex();
    final repl = ref.read(replaceQueryProvider);

    final newText = text.replaceAll(re, repl);
    _setActiveText(newText);

    _resetSearchIndex();
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(redactModeProvider);

    // Query/Flags ändern → aktiven Index zurücksetzen (Riverpod-legal im build)
    ref.listen<String>(searchQueryProvider, (prev, next) => _resetSearchIndex());
    ref.listen<bool>(wholeWordProvider, (prev, next) => _resetSearchIndex());
    ref.listen<bool>(caseSensitiveProvider, (prev, next) => _resetSearchIndex());

    // Relevanten Input in den Controller spiegeln
    ref.listen<String>(
      (mode == RedactMode.anonymize)
          ? anonymizeInputProvider
          : deanonymizeInputProvider,
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

    // Moduswechsel → Textquelle wechseln
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
    _controller.mappings = ref.watch(placeholderMappingProvider);
    _controller.isCaseSensitiveForSearch = ref.watch(caseSensitiveProvider);
    _controller.isWholeWordForSearch = ref.watch(wholeWordProvider);
    _controller.searchQuery = ref.watch(searchQueryProvider);
    _controller.activeSearchMatchIndex =
        ref.watch(activeSearchMatchIndexProvider);
    _controller.highlightPlaceholders = (mode == RedactMode.deanonymize);

    // Aktiven Input → Controller syncen (kontrolliert)
    final activeInput = (mode == RedactMode.anonymize)
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
                    // Input
                    Expanded(
                      flex: 2,
                      child: OriginalTextColumn(
                        controller: _controller,
                        scrollController: _origScroll,
                        focusNode: _origFocus, // NEU
                        onFindNext: _onFindNext,
                        onReplace: _onReplace,
                        onReplaceAll: _onReplaceAll,
                      ),
                    ),
                    // Placeholders
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
          ActionBar(controller: _controller),
        ],
      ),
    );
  }
}
