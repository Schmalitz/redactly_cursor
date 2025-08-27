import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/providers/settings_provider.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/models/placeholder_mapping.dart';

class MappingListWidget extends ConsumerWidget {
  const MappingListWidget({super.key, this.controller});
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mappings        = ref.watch(placeholderMappingProvider);
    final text            = ref.watch(textInputProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord     = ref.watch(wholeWordProvider);

    if (mappings.isEmpty) {
      return const Center(
        child: Text('Noch keine Platzhalter gesetzt.', textAlign: TextAlign.center),
      );
    }

    // Rechter Gutter, damit die vertikale Scrollbar keine Inhalte überdeckt.
    return ListView.separated(
      controller: controller,
      primary: false,
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
      itemCount: mappings.length,
      separatorBuilder: (_, __) => const Divider(height: 10),
      itemBuilder: (context, index) {
        final m = mappings[index];
        final count = _countOccurrences(
          text, m.originalText,
          isCaseSensitive: isCaseSensitive, isWholeWord: isWholeWord,
        );
        return _MappingTile(mapping: m, count: count);
      },
    );
  }

  int _countOccurrences(
      String text,
      String substring, {
        required bool isCaseSensitive,
        required bool isWholeWord,
      }) {
    if (substring.isEmpty) return 0;
    final pattern = isWholeWord ? '\\b${RegExp.escape(substring)}\\b' : RegExp.escape(substring);
    return RegExp(pattern, caseSensitive: isCaseSensitive).allMatches(text).length;
  }
}

class _MappingTile extends ConsumerWidget {
  const _MappingTile({required this.mapping, required this.count});
  final PlaceholderMapping mapping;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // “eine Stufe größer”, weiterhin kompakt
    const titleStyle       = TextStyle(fontWeight: FontWeight.w600, fontSize: 15, height: 1.2);
    const placeholderStyle = TextStyle(fontSize: 14, height: 1.2, color: Colors.black87);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // dot + trailing mittig zur Zweizeile
      children: [
        // Farbpill
        Container(
          width: 10, height: 10,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: mapping.color, shape: BoxShape.circle),
        ),

        // Titel + Placeholder (immer 1 Zeile, mit Ellipsis + Tooltip)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: mapping.originalText,
                waitDuration: const Duration(milliseconds: 300),
                child: Text(
                  mapping.originalText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              const SizedBox(height: 2),
              Tooltip(
                message: mapping.placeholder,
                waitDuration: const Duration(milliseconds: 300),
                child: Text(
                  mapping.placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: placeholderStyle,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Trailing kompakt: Badge + Delete IN EINER ZEILE (nie umbrechen)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count×', style: const TextStyle(fontSize: 12, height: 1.0)),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove',
              onPressed: () =>
                  ref.read(placeholderMappingProvider.notifier).removeMapping(mapping.id),
            ),
          ],
        ),
      ],
    );
  }
}
