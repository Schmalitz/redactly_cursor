import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/session_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/screens/desktop_shell.dart';
import 'package:anonymizer/screens/editor_screen/widgets/action_bar.dart';
import 'package:anonymizer/screens/editor_screen/widgets/original_text_column.dart';
import 'package:anonymizer/screens/editor_screen/widgets/placeholder_column.dart';
import 'package:anonymizer/screens/editor_screen/widgets/preview_column.dart';
import 'package:anonymizer/screens/widgets/header_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// HighlightingTextController and its helper classes remain unchanged
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
  TextSpan buildTextSpan(
      {required BuildContext context,
        TextStyle? style,
        required bool withComposing}) {
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;
    List<_MatchResult> allMatches = [];

    for (final mapping in mappings) {
      if (mapping.originalText.isEmpty) continue;
      final pattern = mapping.isWholeWord
          ? '\\b${RegExp.escape(mapping.originalText)}\\b'
          : RegExp.escape(mapping.originalText);
      final regex = RegExp(pattern, caseSensitive: mapping.isCaseSensitive);
      regex.allMatches(text).forEach((match) {
        allMatches.add(_MatchResult(match, _MatchType.placeholder, mapping: mapping));
      });
    }

    if (searchQuery.isNotEmpty) {
      final pattern = isWholeWordForSearch
          ? '\\b${RegExp.escape(searchQuery)}\\b'
          : RegExp.escape(searchQuery);
      final regex = RegExp(pattern, caseSensitive: isCaseSensitiveForSearch);
      regex.allMatches(text).forEach((match) {
        allMatches.add(_MatchResult(match, _MatchType.search));
      });
    }

    allMatches.sort((a, b) => a.match.start.compareTo(b.match.start));

    List<_MatchResult> filteredMatches = [];
    int currentPos = -1;
    for (final res in allMatches) {
      if (res.match.start >= currentPos) {
        filteredMatches.add(res);
        currentPos = res.match.end;
      }
    }

    int searchMatchCounter = 0;

    for (final result in filteredMatches) {
      final match = result.match;
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      if (result.type == _MatchType.placeholder && result.mapping != null) {
        spans.add(TextSpan(
          text: match.group(0)!,
          style: TextStyle(backgroundColor: result.mapping!.color.withOpacity(0.4)),
        ));
      } else if (result.type == _MatchType.search) {
        final isActive = searchMatchCounter == activeSearchMatchIndex;
        spans.add(TextSpan(
          text: match.group(0)!,
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

enum _MatchType { placeholder, search }

class _MatchResult {
  final RegExpMatch match;
  final _MatchType type;
  final PlaceholderMapping? mapping;

  _MatchResult(this.match, this.type, {this.mapping});
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

    // THIS IS THE KEY FIX:
    // We wait until the first frame is rendered, then initialize the session.
    // This ensures all providers are ready before we start using them.
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
    super.dispose();
  }

  // The rest of the file remains the same...
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
    _controller.mappings = ref.watch(placeholderMappingProvider);
    _controller.isCaseSensitiveForSearch = ref.watch(caseSensitiveProvider);
    _controller.isWholeWordForSearch = ref.watch(wholeWordProvider);
    _controller.searchQuery = ref.watch(searchQueryProvider);
    _controller.activeSearchMatchIndex = ref.watch(activeSearchMatchIndexProvider);

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

    return DesktopShell(
      titleBarHeight: 60,
      sidebarWidth: 260,
      collapsedWidth: 0,
      editor: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: OriginalTextColumn(
                          controller: _controller,
                          onFindNext: _findNext,
                          onReplace: _replace,
                          onReplaceAll: _replaceAll,
                        ),
                      ),
                      const Expanded(flex: 1, child: PlaceholderColumn()),
                      const Expanded(flex: 2, child: PreviewColumn()),
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
