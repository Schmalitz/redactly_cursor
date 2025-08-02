import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/screens/editor_screen/widgets/mapping_list_widget.dart';
import 'package:anonymizer/screens/editor_screen/widgets/show_custom_placeholder_dialog.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';

class PlaceholderColumn extends ConsumerWidget {
  const PlaceholderColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: [
                const Text("Placeholders",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                const Spacer(),
                SizedBox(width: IconTheme.of(context).size ?? 24),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: MappingListWidget(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
