import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/screens/editor_screen/widgets/show_custom_placeholder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionBar extends ConsumerWidget {
  final TextEditingController controller;

  const ActionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(redactModeProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord = ref.watch(wholeWordProvider);

    final buttonStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LINKS: mit OriginalText spaltenbündig (Match Case / Whole Word) + Set Placeholder rechtsbündig
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
                            ref.read(caseSensitiveProvider.notifier).state = value!;
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildStyledCheckbox(
                          label: 'Whole Word',
                          value: isWholeWord,
                          onChanged: (value) {
                            ref.read(wholeWordProvider.notifier).state = value!;
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
                        final selection = controller.selection;
                        if (!selection.isCollapsed) {
                          final selectedText =
                          controller.text.substring(selection.start, selection.end);
                          if (selectedText.trim().isNotEmpty) {
                            ref
                                .read(placeholderMappingProvider.notifier)
                                .addMapping(selectedText.trim());
                          }
                        }
                      },
                      child: const Text('Set Placeholder'),
                    ),
                ],
              ),
            ),
          ),

          // MITTE: exakt zentriert unter PlaceholderColumn → Add Custom Placeholder
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await showCustomPlaceholderDialog(context: context);
                    if (result != null) {
                      ref.read(placeholderMappingProvider.notifier).addCustomMapping(
                        originalText: result.originalText,
                        placeholder: result.placeholder,
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Placeholder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),

          // RECHTS: mit Preview spaltenbündig – unverändert
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
                    final mappings = [...ref.read(placeholderMappingProvider)];

                    String result = raw;

                    if (ref.read(redactModeProvider) == RedactMode.anonymize) {
                      mappings.sort(
                              (a, b) => b.originalText.length.compareTo(a.originalText.length));
                      for (final m in mappings) {
                        if (m.originalText.isEmpty) continue;
                        final pattern = m.isWholeWord
                            ? '\\b${RegExp.escape(m.originalText)}\\b'
                            : RegExp.escape(m.originalText);
                        result = result.replaceAll(
                          RegExp(pattern, caseSensitive: m.isCaseSensitive),
                          m.placeholder,
                        );
                      }
                    } else {
                      mappings.sort(
                              (a, b) => b.placeholder.length.compareTo(a.placeholder.length));
                      for (final m in mappings) {
                        if (m.placeholder.isEmpty) continue;
                        final pattern = RegExp(RegExp.escape(m.placeholder));
                        result = result.replaceAll(pattern, m.originalText);
                      }
                    }

                    Clipboard.setData(ClipboardData(text: result));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(milliseconds: 1200),
                        action: SnackBarAction(label: 'Close', onPressed: () {}),
                      ),
                    );
                  },
                  child: const Text('Copy Preview'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
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
                color: value ? Colors.deepPurple.shade50 : Colors.transparent,
                border: Border.all(
                  color: value ? Colors.deepPurple.shade300 : Colors.grey.shade400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: value
                  ? Icon(Icons.check, size: 14, color: Colors.deepPurple.shade400)
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
