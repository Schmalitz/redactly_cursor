import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/screens/editor_screen/editor_screen.dart';
import 'package:anonymizer/screens/editor_screen/widgets/search_panel.dart';

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

    final inputColor = Colors.white;
    final borderColor = Colors.grey.shade400;
    const contentPadding = EdgeInsets.all(12.0);
    final inputDecoration = BoxDecoration(
      color: inputColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Original Text",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              IconButton(
                icon: Icon(Icons.search, color: isSearchPanelVisible ? Theme.of(context).primaryColor : null),
                onPressed: () {
                  ref.read(searchPanelVisibleProvider.notifier).state = !isSearchPanelVisible;
                },
              )
            ],
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
              padding: contentPadding,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: const TextSelectionThemeData(
                        selectionColor: Colors.amber,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      onChanged: (value) {
                        ref.read(textInputProvider.notifier).state = value;
                        ref.read(activeSearchMatchIndexProvider.notifier).state = -1;
                      },
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
    );
  }
}
