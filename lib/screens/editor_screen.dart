import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/models/placeholder_mapping.dart';

import '../providers/placeholder_mapping_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/text_state_provider.dart';
import '../providers/mode_provider.dart';
import '../widgets/mapping_list_widget.dart';
import '../widgets/preview_text_widget.dart';

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
    final matchEndPosition = match.end;

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
    final isSearchPanelVisible = ref.watch(searchPanelVisibleProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final activeSearchIndex = ref.watch(activeSearchMatchIndexProvider);

    _controller.mappings = mappings;
    _controller.isCaseSensitive = isCaseSensitive;
    _controller.isWholeWord = isWholeWord;
    _controller.searchQuery = searchQuery;
    _controller.activeSearchMatchIndex = activeSearchIndex;

    final text = ref.watch(textInputProvider);
    final mode = ref.watch(redactModeProvider);

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

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final previewColor = Colors.grey.shade200;
    final inputColor = Colors.white;
    final borderColor = Colors.grey.shade400;

    const contentPadding = EdgeInsets.all(12.0);
    final inputDecoration = BoxDecoration(
      color: inputColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(12),
    );
    final previewDecoration = BoxDecoration(
      color: previewColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(12),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Original Text",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            IconButton(
                              icon: Icon(Icons.search, color: isSearchPanelVisible ? Theme.of(context).primaryColor : null),
                              onPressed: () {
                                ref.read(searchPanelVisibleProvider.notifier).state = !isSearchPanelVisible;
                              },
                            )
                          ],
                        ),
                        if (isSearchPanelVisible) _buildSearchPanel(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: inputDecoration,
                            padding: contentPadding,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    textSelectionTheme:
                                    const TextSelectionThemeData(
                                      selectionColor: Colors.amber,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    onChanged: (value) {
                                      ref.read(textInputProvider.notifier).state = value;
                                      ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
                                    },
                                    decoration: InputDecoration(
                                      hintText: mode == RedactMode.anonymize
                                          ? 'Paste your original text...'
                                          : 'Paste your anonymized text...',
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16, height: 1.5),
                                    keyboardType: TextInputType.multiline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("Placeholders",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ),
                        const SizedBox(height: 8),
                        const Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: MappingListWidget(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Preview",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: previewDecoration,
                            padding: contentPadding,
                            child: const Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                primary: true,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: PreviewTextWidget(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (mode == RedactMode.anonymize)
                          Row(
                            children: [
                              _buildStyledCheckbox(
                                label: 'Match Case',
                                value: isCaseSensitive,
                                onChanged: (value) {
                                  ref
                                      .read(caseSensitiveProvider.notifier)
                                      .state = value;
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildStyledCheckbox(
                                label: 'Whole Word',
                                value: isWholeWord,
                                onChanged: (value) {
                                  ref.read(wholeWordProvider.notifier).state =
                                      value;
                                },
                              ),
                            ],
                          )
                        else
                          const SizedBox(),
                        if (mode == RedactMode.anonymize)
                          ElevatedButton(
                            style: buttonStyle,
                            onPressed: () {
                              final selection = _controller.selection;
                              if (!selection.isCollapsed) {
                                final selectedText = _controller.text.substring(
                                    selection.start, selection.end);
                                if (selectedText.trim().isNotEmpty) {
                                  ref
                                      .read(placeholderMappingProvider.notifier)
                                      .addMapping(
                                      selectedText.trim(), isCaseSensitive);
                                }
                              }
                            },
                            child: const Text('Set Placeholder'),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            foregroundColor: mode == RedactMode.anonymize
                                ? Colors.purple
                                : Colors.white,
                            backgroundColor: mode == RedactMode.anonymize
                                ? Colors.transparent
                                : Colors.deepPurple.shade400,
                            side: BorderSide(
                                color: mode == RedactMode.anonymize
                                    ? Colors.purple.shade200
                                    : Colors.transparent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final newMode = mode == RedactMode.anonymize
                              ? RedactMode.deanonymize
                              : RedactMode.anonymize;
                          ref.read(redactModeProvider.notifier).state = newMode;
                          if (newMode == RedactMode.deanonymize) {
                            _controller.clear();
                            ref.read(textInputProvider.notifier).state = '';
                          }
                        },
                        child: Text(mode == RedactMode.anonymize
                            ? 'Anonymize'
                            : 'De-Anonymize'),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: buttonStyle,
                        onPressed: () {
                          final raw = ref.read(textInputProvider);
                          final mappings =
                          ref.read(placeholderMappingProvider);
                          final currentMode = ref.read(redactModeProvider);
                          String result = raw;
                          for (final m in mappings) {
                            final pattern = isWholeWord
                                ? '\\b${RegExp.escape(m.originalText)}\\b'
                                : RegExp.escape(m.originalText);

                            if (currentMode == RedactMode.anonymize) {
                              result = result.replaceAll(
                                  RegExp(pattern,
                                      caseSensitive: isCaseSensitive),
                                  m.placeholder);
                            } else {
                              result = result.replaceAll(
                                  m.placeholder, m.originalText);
                            }
                          }
                          Clipboard.setData(ClipboardData(text: result));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard')),
                          );
                        },
                        child: const Text('Copy Preview'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    final searchQuery = ref.watch(searchQueryProvider);
    final replaceQuery = ref.watch(replaceQueryProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: searchQuery)
                    ..selection =
                    TextSelection.collapsed(offset: searchQuery.length),
                  onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
                  decoration: const InputDecoration(
                      hintText: 'Search for...',
                      isDense: true,
                      border: InputBorder.none),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: replaceQuery)
                    ..selection =
                    TextSelection.collapsed(offset: replaceQuery.length),
                  onChanged: (value) =>
                  ref.read(replaceQueryProvider.notifier).state = value,
                  decoration: const InputDecoration(
                      hintText: 'Replace with...',
                      isDense: true,
                      border: InputBorder.none),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _findNext, child: const Text('Find Next')),
              TextButton(onPressed: _replace, child: const Text('Replace')),
              TextButton(
                  onPressed: _replaceAll, child: const Text('Replace All')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyledCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color:
                value ? Colors.deepPurple.shade50 : Colors.transparent,
                border: Border.all(
                  color: value
                      ? Colors.deepPurple.shade300
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: value
                  ? Icon(Icons.check,
                  size: 14, color: Colors.deepPurple.shade400)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}