import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/placeholder_mapping_provider.dart';
import '../providers/text_state_provider.dart';
import '../providers/mode_provider.dart';
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
    final mode = ref.watch(redactModeProvider);
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

    // Modus-Wechsel: Textfeld zurücksetzen bei Wechsel zu deanonymize
    ref.listen<RedactMode>(redactModeProvider, (previous, next) {
      if (next == RedactMode.deanonymize) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.clear();
          ref.read(textInputProvider.notifier).state = '';
        });
      }
    });

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
                // Original / Anonymized
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == RedactMode.anonymize ? "Original Text" : "Anonymized Text",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                    textSelectionTheme: const TextSelectionThemeData(
                                      selectionColor: Colors.orangeAccent,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    onChanged: (value) => ref.read(textInputProvider.notifier).state = value,
                                    decoration: InputDecoration(
                                      hintText: mode == RedactMode.anonymize
                                          ? 'Paste your original text to be anonymized here'
                                          : 'Paste your anonymized text here',
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

                // Placeholder List + Toggle
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 16),
                        child: Text("Placeholders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: MappingListWidget(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Preview / Result
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == RedactMode.anonymize ? "Preview" : "Result",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Set Placeholder oder leerer Platzhalter
                    mode == RedactMode.anonymize
                        ? ElevatedButton(
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
                    )
                        : const SizedBox(width: 140), // exakt gleich breit wie der Button

                    // Copy Preview
                    ElevatedButton(
                      onPressed: () {
                        final raw = ref.read(textInputProvider);
                        final mappings = ref.read(placeholderMappingProvider);
                        final mode = ref.read(redactModeProvider);

                        String result = raw;

                        for (final m in mappings) {
                          result = mode == RedactMode.anonymize
                              ? result.replaceAll(m.originalText, m.placeholder)
                              : result.replaceAll(m.placeholder, m.originalText);
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

                // Modus-Umschalter (immer perfekt zentriert)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: mode == RedactMode.anonymize
                        ? Colors.purple.shade400
                        : Colors.deepPurple.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () {
                    ref.read(redactModeProvider.notifier).state =
                    mode == RedactMode.anonymize ? RedactMode.deanonymize : RedactMode.anonymize;
                  },
                  child: const Text(
                    'Redactly',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
