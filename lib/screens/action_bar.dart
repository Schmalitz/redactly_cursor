import 'dart:async'; // NEU: für Hover-Grace-Timer

import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/providers/placeholder_mapping_provider.dart';
import 'package:redactly/providers/settings_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';
import 'package:redactly/screens/editor_screen/widgets/show_custom_placeholder_dialog.dart';
import 'package:redactly/theme/app_buttons.dart';
import 'package:redactly/utils/regex_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// NEU: zentraler, abgesicherter Clipboard-Service
import 'package:redactly/services/clipboard_service.dart';

class ActionBar extends ConsumerWidget {
  final TextEditingController controller;

  const ActionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(redactModeProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord = ref.watch(wholeWordProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            // LINKS
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (mode == RedactMode.anonymize)
                        AppButton.solid(
                          onPressed: () {
                            final sel = controller.selection;
                            if (!sel.isCollapsed) {
                              final s = controller.text
                                  .substring(sel.start, sel.end)
                                  .trim();
                              if (s.isNotEmpty) {
                                ref
                                    .read(placeholderMappingProvider.notifier)
                                    .addMapping(s);
                              }
                            }
                          },
                          label: 'Set Placeholder',
                          leadingIcon: Icons.bookmark_add_outlined,
                        ),
                      if (mode == RedactMode.anonymize)
                        _checkboxGroup(context, ref, isCaseSensitive, isWholeWord),
                    ],
                  ),
                ),
              ),
            ),

            // MITTE
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

            // RECHTS – Copy Preview
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppButton.solid(
                    onPressed: () async {
                      final raw = (ref.read(redactModeProvider) == RedactMode.anonymize)
                          ? ref.read(anonymizeInputProvider)
                          : ref.read(deanonymizeInputProvider);

                      final mappings = [...ref.read(placeholderMappingProvider)];
                      String result = raw;

                      if (ref.read(redactModeProvider) == RedactMode.anonymize) {
                        mappings.sort((a, b) => b.originalText.length.compareTo(a.originalText.length));
                        for (final m in mappings) {
                          if (m.originalText.isEmpty) continue;
                          final re = m.isWholeWord
                              ? buildNeedleRegex(
                            needle: m.originalText,
                            wholeWord: true,
                            caseSensitive: m.isCaseSensitive,
                          )
                              : RegExp(RegExp.escape(m.originalText), caseSensitive: m.isCaseSensitive);
                          result = result.replaceAll(re, m.placeholder);
                        }
                      } else {
                        mappings.sort((a, b) => b.placeholder.length.compareTo(a.placeholder.length));
                        for (final m in mappings) {
                          if (m.placeholder.isEmpty) continue;
                          final pattern = RegExp(RegExp.escape(m.placeholder));
                          result = result.replaceAll(pattern, m.originalText);
                        }
                      }

                      // NEU: abgesichertes Kopieren inkl. SnackBar
                      await ClipboardService.copyText(context, result);
                    },
                    label: 'Copy Output',
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

  Widget _checkboxGroup(
      BuildContext context,
      WidgetRef ref,
      bool isCaseSensitive,
      bool isWholeWord,
      ) {
    final w = MediaQuery.sizeOf(context).width;
    // Etwas früher in den Burger-Modus gehen, um jede Zwischen-Umbrechphase zu vermeiden.
    final bool compact = w < 1400;

    // Kompakt: Burger-Menü (öffnet auf Hover)
    if (compact) {
      return _OptionsBurger(
        isCaseSensitive: isCaseSensitive,
        isWholeWord: isWholeWord,
        onToggleCase: (v) => ref.read(caseSensitiveProvider.notifier).state = v,
        onToggleWhole: (v) => ref.read(wholeWordProvider.notifier).state = v,
      );
    }

    // Nicht kompakt: fixe Row (kein Wrap → kein kurzzeitiger Umbruchzustand)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStyledCheckbox(
          label: 'Match Case',
          value: isCaseSensitive,
          onChanged: (v) => ref.read(caseSensitiveProvider.notifier).state = v!,
        ),
        const SizedBox(width: 8),
        _buildStyledCheckbox(
          label: 'Whole Word',
          value: isWholeWord,
          onChanged: (v) => ref.read(wholeWordProvider.notifier).state = v!,
        ),
      ],
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
              child: value ? Icon(Icons.check, size: 14, color: Colors.deepPurple.shade400) : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
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

// NEU: Widget-Deklaration, die in deinem _checkboxGroup() verwendet wird
class _OptionsBurger extends StatefulWidget {
  const _OptionsBurger({
    required this.isCaseSensitive,
    required this.isWholeWord,
    required this.onToggleCase,
    required this.onToggleWhole,
  });

  final bool isCaseSensitive;
  final bool isWholeWord;
  final ValueChanged<bool> onToggleCase;
  final ValueChanged<bool> onToggleWhole;

  @override
  State<_OptionsBurger> createState() => _OptionsBurgerState();
}

// FIXED: State inkl. stabiler Hover-Logik und ohne Tooltip-Overlay
class _OptionsBurgerState extends State<_OptionsBurger> {
  Timer? _closeTimer;
  late MenuController _controller; // vom builder gesetzt

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 300), () {
      if (_controller.isOpen) _controller.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      // Menüeinträge – gesamte Liste in MouseRegion, um Timer zu canceln
      menuChildren: [
        MouseRegion(
          onEnter: (_) => _closeTimer?.cancel(),
          onExit: (_) => _scheduleClose(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuItemButton(
                leadingIcon: Icon(
                  widget.isCaseSensitive
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                onPressed: () => widget.onToggleCase(!widget.isCaseSensitive),
                child: const Text('Match Case'),
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  widget.isWholeWord
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                onPressed: () => widget.onToggleWhole(!widget.isWholeWord),
                child: const Text('Whole Word'),
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) {
        _controller = controller; // hier einmal referenzieren
        return MouseRegion(
          onEnter: (_) {
            _closeTimer?.cancel();
            if (!_controller.isOpen) _controller.open();
          },
          onExit: (_) => _scheduleClose(),
          child: IconButton(
            icon: const Icon(Icons.more_horiz),
            // kein Tooltip → überdeckt nichts
            onPressed: () {
              _closeTimer?.cancel();
              _controller.isOpen ? _controller.close() : _controller.open();
            },
            splashRadius: 18,
          ),
        );
      },
    );
  }
}
