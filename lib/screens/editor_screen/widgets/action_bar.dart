import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/providers/placeholder_mapping_provider.dart';
import 'package:redactly/providers/settings_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';

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
                            ref.read(caseSensitiveProvider.notifier).state = value;
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildStyledCheckbox(
                          label: 'Whole Word',
                          value: isWholeWord,
                          onChanged: (value) {
                            ref.read(wholeWordProvider.notifier).state = value;
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
                          final selectedText = controller.text.substring(selection.start, selection.end);
                          if (selectedText.trim().isNotEmpty) {
                            ref.read(placeholderMappingProvider.notifier).addMapping(selectedText.trim(), isCaseSensitive);
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      foregroundColor: mode == RedactMode.anonymize ? Colors.white : Colors.purple,
                      backgroundColor: mode == RedactMode.anonymize ? Colors.deepPurple.shade400 : Colors.transparent,
                      side: BorderSide(color: mode == RedactMode.anonymize ? Colors.transparent : Colors.purple.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final newMode = mode == RedactMode.anonymize ? RedactMode.deanonymize : RedactMode.anonymize;
                    ref.read(redactModeProvider.notifier).state = newMode;
                    if (newMode == RedactMode.deanonymize) {
                      controller.clear();
                      ref.read(textInputProvider.notifier).state = '';
                    }
                  },
                  child: Text(mode == RedactMode.anonymize ? 'Anonymize' : 'De-Anonymize'),
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
                    final mappings = ref.read(placeholderMappingProvider);
                    final currentMode = ref.read(redactModeProvider);
                    final isWhole = ref.read(wholeWordProvider);
                    final isCase = ref.read(caseSensitiveProvider);
                    String result = raw;
                    for (final m in mappings) {
                      final pattern = isWhole ? '\\b${RegExp.escape(m.originalText)}\\b' : RegExp.escape(m.originalText);

                      if (currentMode == RedactMode.anonymize) {
                        result = result.replaceAll(RegExp(pattern, caseSensitive: isCase), m.placeholder);
                      } else {
                        result = result.replaceAll(m.placeholder, m.originalText);
                      }
                    }
                    Clipboard.setData(ClipboardData(text: result));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
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
                color: value ? Colors.deepPurple.shade50 : Colors.transparent,
                border: Border.all(
                  color: value ? Colors.deepPurple.shade300 : Colors.grey.shade400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: value ? Icon(Icons.check, size: 14, color: Colors.deepPurple.shade400) : null,
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