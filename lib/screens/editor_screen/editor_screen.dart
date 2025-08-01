import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/providers/placeholder_mapping_provider.dart';
import 'package:redactly/providers/session_provider.dart';
import 'package:redactly/providers/settings_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';
import 'package:redactly/screens/editor_screen/widgets/action_bar.dart';
import 'package:redactly/screens/editor_screen/widgets/original_text_column.dart';
import 'package:redactly/screens/editor_screen/widgets/placeholder_column.dart';
import 'package:redactly/screens/editor_screen/widgets/preview_column.dart';
import 'package:redactly/screens/editor_screen/widgets/session_sidebar.dart';

class HighlightingTextController extends TextEditingController {
  List<PlaceholderMapping> mappings;
  bool isCaseSensitive;
  bool isWholeWord;
  String searchQuery;
  int activeSearchMatchIndex;

  HighlightingTextController({
    required this.mappings,
    required this.isCaseSensitive,
    required this.isWholeWord,
    required this.searchQuery,
    required this.activeSearchMatchIndex,
    String? text,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
        TextStyle? style,
        required bool withComposing}) {
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final spans = <InlineSpan>[];
    int lastMatchEnd = 0;

    final placeholderPattern = mappings.isNotEmpty
        ? mappings
        .map((m) =>
    isWholeWord ? '\\b${RegExp.escape(m.originalText)}\\b' : RegExp.escape(m.originalText))
        .where((p) => p.isNotEmpty)
        .join('|')
        : null;

    final searchPattern = searchQuery.isNotEmpty
        ? (isWholeWord
        ? '\\b${RegExp.escape(searchQuery)}\\b'
        : RegExp.escape(searchQuery))
        : null;

    if (placeholderPattern == null && searchPattern == null) {
      return TextSpan(text: text, style: style);
    }

    final hasPlaceholderPattern = placeholderPattern != null && placeholderPattern.isNotEmpty;
    final hasSearchPattern = searchPattern != null && searchPattern.isNotEmpty;

    final combinedPattern = [
      if (hasPlaceholderPattern) '($placeholderPattern)',
      if (hasSearchPattern) '($searchPattern)',
    ].join('|');

    final regex = RegExp(combinedPattern, caseSensitive: isCaseSensitive);
    final matches = regex.allMatches(text);

    int searchMatchCounter = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      String? matchedText;
      bool isSearchMatch = false;
      bool isPlaceholderMatch = false;

      if (hasPlaceholderPattern && hasSearchPattern) {
        if (match.group(1) != null) {
          matchedText = match.group(1);
          isPlaceholderMatch = true;
        } else {
          matchedText = match.group(2);
          isSearchMatch = true;
        }
      } else if (hasPlaceholderPattern) {
        matchedText = match.group(1);
        isPlaceholderMatch = true;
      } else if (hasSearchPattern) {
        matchedText = match.group(1);
        isSearchMatch = true;
      }

      if (matchedText == null) continue;

      if (isPlaceholderMatch) {
        final mapping = mappings.firstWhere(
                (m) => isCaseSensitive
                ? m.originalText == matchedText
                : m.originalText.toLowerCase() == matchedText!.toLowerCase(),
            orElse: () => PlaceholderMapping(id: '', originalText: '', placeholder: '', color: Colors.transparent)
        );
        if (mapping.id.isNotEmpty) {
          spans.add(TextSpan(
            text: matchedText,
            style: TextStyle(backgroundColor: mapping.color.withOpacity(0.4)),
          ));
        } else {
          spans.add(TextSpan(text: matchedText));
        }
      } else if (isSearchMatch) {
        final bool isActive = searchMatchCounter == activeSearchMatchIndex;
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(backgroundColor: isActive ? Colors.pinkAccent : Colors.pink.shade100),
        ));
        searchMatchCounter++;
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return TextSpan(style: style, children: spans);
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final HighlightingTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HighlightingTextController(
      mappings: ref.read(placeholderMappingProvider),
      text: ref.read(textInputProvider),
      isCaseSensitive: ref.read(caseSensitiveProvider),
      isWholeWord: ref.read(wholeWordProvider),
      searchQuery: ref.read(searchQueryProvider),
      activeSearchMatchIndex: ref.read(activeSearchMatchIndexProvider),
    );
    // Erstellt eine erste leere Session beim Start der App
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(sessionProvider).isEmpty) {
        ref.read(sessionProvider.notifier).createNewSession();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<RegExpMatch> _getSearchMatches() {
    final query = ref.read(searchQueryProvider);
    final isCaseSensitive = ref.read(caseSensitiveProvider);
    final isWholeWord = ref.read(wholeWordProvider);

    if (query.isEmpty) return [];

    final pattern = isWholeWord ? '\\b${RegExp.escape(query)}\\b' : RegExp.escape(query);
    final regex = RegExp(pattern, caseSensitive: isCaseSensitive);
    return regex.allMatches(_controller.text).toList();
  }

  void _findAndActivateFirstMatch() {
    final matches = _getSearchMatches();
    if (matches.isNotEmpty) {
      ref.read(activeSearchMatchIndexProvider.notifier).state = 0;
      final firstMatch = matches[0];
      _controller.selection = TextSelection(baseOffset: firstMatch.start, extentOffset: firstMatch.end);
    } else {
      ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
    }
  }

  void _findNext() {
    final matches = _getSearchMatches();
    if (matches.isEmpty) return;

    final currentIndex = ref.read(activeSearchMatchIndexProvider);
    int nextIndex = currentIndex + 1;
    if (nextIndex >= matches.length) {
      nextIndex = 0;
    }

    ref.read(activeSearchMatchIndexProvider.notifier).state = nextIndex;
    final nextMatch = matches[nextIndex];
    _controller.selection = TextSelection(baseOffset: nextMatch.start, extentOffset: nextMatch.end);
  }

  void _replace() {
    final matches = _getSearchMatches();
    final activeIndex = ref.read(activeSearchMatchIndexProvider);

    if (matches.isEmpty || activeIndex < 0 || activeIndex >= matches.length) {
      _findNext();
      return;
    }

    final match = matches[activeIndex];
    final replaceWith = ref.read(replaceQueryProvider);

    final newText = _controller.text.replaceRange(match.start, match.end, replaceWith);

    ref.read(textInputProvider.notifier).state = newText;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newMatches = _getSearchMatches();
      if (newMatches.isEmpty) {
        ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
        return;
      }

      int nextIndex = newMatches.indexWhere((m) => m.start >= match.start);

      if (nextIndex == -1) {
        nextIndex = 0;
      }

      ref.read(activeSearchMatchIndexProvider.notifier).state = nextIndex;
      final nextMatch = newMatches[nextIndex];
      _controller.selection = TextSelection(baseOffset: nextMatch.start, extentOffset: nextMatch.end);
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
    final mappings = ref.watch(placeholderMappingProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord = ref.watch(wholeWordProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final activeSearchIndex = ref.watch(activeSearchMatchIndexProvider);

    _controller.mappings = mappings;
    _controller.isCaseSensitive = isCaseSensitive;
    _controller.isWholeWord = isWholeWord;
    _controller.searchQuery = searchQuery;
    _controller.activeSearchMatchIndex = activeSearchIndex;

    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (next.isNotEmpty) {
        _findAndActivateFirstMatch();
      } else {
        ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
      }
    });

    ref.listen<String>(textInputProvider, (previous, next) {
      if (_controller.text != next) {
        final selection = _controller.selection;
        _controller.text = next;
        if (selection.start <= next.length && selection.end <= next.length) {
          _controller.selection = selection;
        }
      }
    });

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SessionSidebar(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OriginalTextColumn(
                        controller: _controller,
                        onFindNext: _findNext,
                        onReplace: _replace,
                        onReplaceAll: _replaceAll,
                      ),
                      const PlaceholderColumn(),
                      const PreviewColumn(),
                    ],
                  ),
                ),
                ActionBar(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}