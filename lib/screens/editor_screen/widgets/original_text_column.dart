import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/providers/settings_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';
import 'package:redactly/screens/editor_screen/highlighting_text_controller.dart';
import 'package:redactly/screens/editor_screen/widgets/search_panel.dart';
import 'package:redactly/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OriginalTextColumn extends ConsumerStatefulWidget {
  final HighlightingTextController controller;
  final ScrollController scrollController; // wird von außen übergeben (EditorScreen)
  final FocusNode focusNode; // NEU: für Scroll-to-match per Caret-Fokus
  final VoidCallback onFindNext;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;

  const OriginalTextColumn({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode, // NEU
    required this.onFindNext,
    required this.onReplace,
    required this.onReplaceAll,
  });

  @override
  ConsumerState<OriginalTextColumn> createState() => _OriginalTextColumnState();
}

class _OriginalTextColumnState extends ConsumerState<OriginalTextColumn> {
  ScrollController get _ctrl => widget.scrollController;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(redactModeProvider);
    final isSearchPanelVisible = ref.watch(searchPanelVisibleProvider);
    final theme = Theme.of(context);

    final hasClients = _ctrl.hasClients;
    if (!hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ctrl.hasClients) setState(() {});
      });
    }

    final inputDecoration = BoxDecoration(
      color: theme.cEditor,
      border: Border.all(color: theme.cStroke),
      borderRadius: BorderRadius.circular(12),
    );

    final editor = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode, // NEU
      scrollController: _ctrl,
      maxLines: null,
      onChanged: (value) {
        if (mode == RedactMode.anonymize) {
          ref.read(anonymizeInputProvider.notifier).state = value;
        } else {
          ref.read(deanonymizeInputProvider.notifier).state = value;
        }
        ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
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
    );

    final headerLabel =
    (mode == RedactMode.anonymize) ? 'Original Input' : 'Placeholdered Input';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: headerLabel,
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
              onFindNext: widget.onFindNext,
              onReplace: widget.onReplace,
              onReplaceAll: widget.onReplaceAll,
            ),

          const SizedBox(height: 8),

          Expanded(
            child: Container(
              decoration: inputDecoration,
              clipBehavior: Clip.antiAlias, // bleibt: visuelles Clipping innerhalb der Rundung
              padding: const EdgeInsets.all(12),
              child: Theme(
                data: theme.copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionColor: Color(0xFFFF9800),
                  ),
                ),
                child: hasClients
                    ? Scrollbar(
                  controller: _ctrl,
                  thumbVisibility: true,
                  interactive: true,
                  child: editor,
                )
                    : editor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge;

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
