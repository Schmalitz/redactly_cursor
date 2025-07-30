import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/settings_provider.dart';
import '../providers/placeholder_mapping_provider.dart';
import '../providers/text_state_provider.dart';
import '../models/placeholder_mapping.dart';

class MappingListWidget extends ConsumerWidget {
  const MappingListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappings = ref.watch(placeholderMappingProvider);
    final text = ref.watch(textInputProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord = ref.watch(wholeWordProvider);

    if (mappings.isEmpty) {
      return const Center(
          child:
          Text('Noch keine Platzhalter gesetzt.', textAlign: TextAlign.center));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final PlaceholderMapping m = mappings[index];
        final count = _countOccurrences(text, m.originalText,
            isCaseSensitive: isCaseSensitive, isWholeWord: isWholeWord);

        return Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: m.color,
                shape: BoxShape.circle,
              ),
            ),
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
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count×',
                style: const TextStyle(fontSize: 12),
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

  int _countOccurrences(String text, String substring,
      {required bool isCaseSensitive, required bool isWholeWord}) {
    if (substring.isEmpty) return 0;

    final pattern = isWholeWord
        ? '\\b${RegExp.escape(substring)}\\b'
        : RegExp.escape(substring);

    return RegExp(pattern, caseSensitive: isCaseSensitive)
        .allMatches(text)
        .length;
  }
}