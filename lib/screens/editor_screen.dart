import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/placeholder_mapping_provider.dart';
import '../providers/text_state_provider.dart';
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

    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Original Text
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Original Text", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                    textSelectionTheme: const TextSelectionThemeData(
                                      selectionColor: Colors.orangeAccent, // kräftiges Gelb
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    onChanged: (value) =>
                                    ref.read(textInputProvider.notifier).state = value,
                                    decoration: const InputDecoration(
                                      hintText: 'Paste your text here',
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(fontSize: 16),
                                    textAlignVertical: TextAlignVertical.top,
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
                // Placeholder List
                const Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16, top: 16),
                        child: Text("Placeholders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: MappingListWidget()),
                    ],
                  ),
                ),
                // Preview
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Preview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: previewDecoration,
                            padding: contentPadding,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                primary: true,
                                child: Container(
                                  width: double.infinity,
                                  child: const PreviewTextWidget(),
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
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    final selection = _controller.selection;
                    if (!selection.isCollapsed) {
                      final selectedText = _controller.text.substring(selection.start, selection.end);
                      if (selectedText.trim().isNotEmpty) {
                        ref.read(placeholderMappingProvider.notifier).addMapping(selectedText.trim());
                      }
                    }
                  },
                  child: const Text('Set Placeholder'),
                ),
                const Spacer(),
                const Text(
                  'Redactly',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final previewText = ref.read(textInputProvider);
                    final mappings = ref.read(placeholderMappingProvider);
                    String result = previewText;
                    for (final m in mappings) {
                      result = result.replaceAll(m.originalText, m.placeholder);
                    }
                    Clipboard.setData(ClipboardData(text: result));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: const Text('Copy Preview'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
