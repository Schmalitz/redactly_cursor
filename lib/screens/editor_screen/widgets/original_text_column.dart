import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/screens/editor_screen/editor_screen.dart';
import 'package:anonymizer/screens/editor_screen/widgets/search_panel.dart';
import 'package:anonymizer/theme/app_colors.dart';

class OriginalTextColumn extends ConsumerWidget {
  final HighlightingTextController controller;
  final VoidCallback onFindNext;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;

  const OriginalTextColumn({
    super.key,
    required this.controller,
    required this.onFindNext,
    required this.onReplace,
    required this.onReplaceAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(redactModeProvider);
    final isSearchPanelVisible = ref.watch(searchPanelVisibleProvider);
    final theme = Theme.of(context);

    final inputDecoration = BoxDecoration(
      color: theme.cEditor,
      border: Border.all(color: theme.cStroke),
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      // top: 8, damit die Header-Linie exakt mit „New Session“ fluchtet
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Original Text',
            trailing: IconButton(
              tooltip: isSearchPanelVisible ? 'Hide search' : 'Show search',
              onPressed: () => ref
                  .read(searchPanelVisibleProvider.notifier)
                  .state = !isSearchPanelVisible,
              icon: Icon(
                Icons.search,
                size: 20,
                color: isSearchPanelVisible ? theme.cPrimary : null,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
            ),
          ),

          if (isSearchPanelVisible)
            SearchPanel(
              onFindNext: onFindNext,
              onReplace: onReplace,
              onReplaceAll: onReplaceAll,
            ),

          const SizedBox(height: 8),

          Expanded(
            child: Container(
              decoration: inputDecoration,
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Theme(
                    data: theme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        selectionColor: theme.cSelection,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      onChanged: (value) {
                        ref.read(textInputProvider.notifier).state = value;
                        ref
                            .read(activeSearchMatchIndexProvider.notifier)
                            .state = -1;
                      },
                      decoration: InputDecoration(
                        hintText: mode == RedactMode.anonymize
                            ? 'Paste your original text...'
                            : 'Paste your anonymized text...',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge; // 14pt, w600 (AppTheme)

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: textStyle),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
