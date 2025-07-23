import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/models/placeholder_mapping.dart';
import '../providers/text_state_provider.dart';
import '../providers/placeholder_mapping_provider.dart';
import '../widgets/mapping_list_widget.dart';
import '../widgets/preview_text_widget.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final text = ref.watch(textInputProvider);
    final mappings = ref.watch(placeholderMappingProvider);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    final textSpans = _buildHighlightedText(text, mappings);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('Redactly'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Originaltext", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Hintergrund mit Highlights
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    color: Colors.black,
                                  ),
                                  children: textSpans,
                                ),
                              ),
                            ),
                          ),
                          // Unsichtbares Eingabefeld darüber
                          TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            onChanged: (value) =>
                            ref.read(textInputProvider.notifier).state = value,
                            decoration: const InputDecoration(
                              hintText: 'Füge hier deinen Text ein',
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.all(12),
                              filled: true,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                            ),
                            cursorColor: Colors.deepPurple,
                            style: const TextStyle(
                              color: Colors.transparent,
                              height: 1.3,
                            ),
                            selectionControls: materialTextSelectionControls,
                            enableInteractiveSelection: true,
                            mouseCursor: SystemMouseCursors.text,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final selection = _controller.selection;
                      if (!selection.isCollapsed) {
                        final selectedText = _controller.text.substring(
                          selection.start,
                          selection.end,
                        );
                        if (selectedText.trim().isNotEmpty) {
                          ref
                              .read(placeholderMappingProvider.notifier)
                              .addMapping(selectedText.trim());
                        }
                      }
                    },
                    child: const Text('Platzhalter setzen'),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(),
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 16),
                  child: Text("Platzhalter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: MappingListWidget()),
              ],
            ),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 4,
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Vorschau", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Expanded(child: PreviewTextWidget()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(String fullText, List<PlaceholderMapping> mappings) {
    final spans = <TextSpan>[];
    int currentIndex = 0;

    final matches = <_MatchInfo>[];

    for (final mapping in mappings) {
      final index = fullText.indexOf(mapping.originalText, 0);
      if (index >= 0) {
        matches.add(_MatchInfo(index, mapping.originalText.length, mapping));
      }
    }

    matches.sort((a, b) => a.start.compareTo(b.start));

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: fullText.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: fullText.substring(match.start, match.start + match.length),
        style: TextStyle(backgroundColor: match.mapping.color),
      ));
      currentIndex = match.start + match.length;
    }

    if (currentIndex < fullText.length) {
      spans.add(TextSpan(text: fullText.substring(currentIndex)));
    }

    return spans;
  }
}

class _MatchInfo {
  final int start;
  final int length;
  final PlaceholderMapping mapping;

  _MatchInfo(this.start, this.length, this.mapping);
}
