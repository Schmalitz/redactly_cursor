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

  HighlightingTextController({
    required this.mappings,
    required this.isCaseSensitive,
    required this.isWholeWord,
    String? text,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
        TextStyle? style,
        required bool withComposing}) {
    final List<InlineSpan> children = [];
    final text = this.text;

    if (mappings.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final sortedMappings = [...mappings]
      ..sort((a, b) => b.originalText.length.compareTo(a.originalText.length));

    int lastMatchEnd = 0;

    final regexParts = sortedMappings.map((m) {
      final escapedText = RegExp.escape(m.originalText);
      return isWholeWord ? '\\b$escapedText\\b' : escapedText;
    }).where((p) => p.isNotEmpty);

    if (regexParts.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final regex = RegExp(regexParts.join('|'), caseSensitive: isCaseSensitive);
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final foundText = match.group(0)!;
      final mapping = sortedMappings.firstWhere((m) => isCaseSensitive
          ? m.originalText == foundText
          : m.originalText.toLowerCase() == foundText.toLowerCase());

      children.add(TextSpan(
        text: foundText,
        style: TextStyle(
          backgroundColor: mapping.color.withOpacity(0.4),
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return TextSpan(style: style, children: children);
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mappings = ref.watch(placeholderMappingProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord = ref.watch(wholeWordProvider);

    _controller.mappings = mappings;
    _controller.isCaseSensitive = isCaseSensitive;
    _controller.isWholeWord = isWholeWord;

    final text = ref.watch(textInputProvider);
    final mode = ref.watch(redactModeProvider);

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
                        const Text(
                          "Original Text",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
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
                                    onChanged: (value) => ref
                                        .read(textInputProvider.notifier)
                                        .state = value,
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