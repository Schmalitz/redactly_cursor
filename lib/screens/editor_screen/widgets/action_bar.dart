import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/screens/editor_screen/widgets/show_custom_placeholder_dialog.dart';
import 'package:anonymizer/theme/app_buttons.dart';
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

    return Padding(
      // kompakter
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48, // kompakte Höhe
        child: Row(
          children: [
            // LINKS: Set Placeholder → Checkboxes
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (mode == RedactMode.anonymize) ...[
                        AppButton.solid(
                          onPressed: () {
                            final sel = controller.selection;
                            if (!sel.isCollapsed) {
                              final s = controller.text.substring(sel.start, sel.end).trim();
                              if (s.isNotEmpty) {
                                ref.read(placeholderMappingProvider.notifier).addMapping(s);
                              }
                            }
                          },
                          label: 'Set Placeholder',
                          leadingIcon: Icons.bookmark_add_outlined,
                        ),
                        const SizedBox(width: 12),
                        _buildStyledCheckbox(
                          label: 'Match Case',
                          value: isCaseSensitive,
                          onChanged: (v) =>
                          ref.read(caseSensitiveProvider.notifier).state = v!,
                        ),
                        const SizedBox(width: 12),
                        _buildStyledCheckbox(
                          label: 'Whole Word',
                          value: isWholeWord,
                          onChanged: (v) =>
                          ref.read(wholeWordProvider.notifier).state = v!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // MITTE: Custom Placeholder exakt zentriert (eigene Spalte)
            Expanded(
              flex: 2,
              child: Center(
                child: mode == RedactMode.anonymize
                    ? AppButton.outline(
                  onPressed: () async {
                    final result = await showCustomPlaceholderDialog(context: context);
                    if (result != null) {
                      ref.read(placeholderMappingProvider.notifier).addCustomMapping(
                        originalText: result.originalText,
                        placeholder: result.placeholder,
                      );
                    }
                  },
                  label: 'Custom Placeholder',
                  leadingIcon: Icons.add,
                )
                    : const SizedBox.shrink(),
              ),
            ),

            // RECHTS: Copy Preview (unverändert, rechtsbündig)
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppButton.solid(
                    onPressed: () {
                      final raw = ref.read(textInputProvider);
                      final mappings = [...ref.read(placeholderMappingProvider)];
                      String result = raw;

                      if (ref.read(redactModeProvider) == RedactMode.anonymize) {
                        mappings.sort((a, b) => b.originalText.length.compareTo(a.originalText.length));
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
                        mappings.sort((a, b) => b.placeholder.length.compareTo(a.placeholder.length));
                        for (final m in mappings) {
                          if (m.placeholder.isEmpty) continue;
                          final pattern = RegExp(RegExp.escape(m.placeholder));
                          result = result.replaceAll(pattern, m.originalText);
                        }
                      }

                      Clipboard.setData(ClipboardData(text: result));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    label: 'Copy Preview',
                    leadingIcon: Icons.copy_all,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        // etwas dichter
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
            const Text(
              // kompaktere Typo
              '',
            ),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
