import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/placeholder_mapping_provider.dart';
import '../models/placeholder_mapping.dart';

class MappingListWidget extends ConsumerWidget {
  const MappingListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappings = ref.watch(placeholderMappingProvider);

    if (mappings.isEmpty) {
      return const Center(child: Text('Noch keine Platzhalter gesetzt.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final PlaceholderMapping m = mappings[index];

        return Row(
          children: [
            // Farbpunktsymbol
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: m.color,
                shape: BoxShape.circle,
              ),
            ),
            // Mapping-Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.originalText,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(m.placeholder, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                ref
                    .read(placeholderMappingProvider.notifier)
                    .removeMapping(m.id);
              },
            )
          ],
        );
      },
    );
  }
}
