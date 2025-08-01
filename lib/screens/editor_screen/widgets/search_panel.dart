import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/settings_provider.dart';

class SearchPanel extends ConsumerWidget {
  final VoidCallback onFindNext;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;

  const SearchPanel({
    super.key,
    required this.onFindNext,
    required this.onReplace,
    required this.onReplaceAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final replaceQuery = ref.watch(replaceQueryProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: searchQuery)
                    ..selection =
                        TextSelection.collapsed(offset: searchQuery.length),
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).state = value,
                  decoration: const InputDecoration(
                      hintText: 'Search for...',
                      isDense: true,
                      border: InputBorder.none),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: replaceQuery)
                    ..selection =
                        TextSelection.collapsed(offset: replaceQuery.length),
                  onChanged: (value) =>
                      ref.read(replaceQueryProvider.notifier).state = value,
                  decoration: const InputDecoration(
                      hintText: 'Replace with...',
                      isDense: true,
                      border: InputBorder.none),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onFindNext, child: const Text('Find Next')),
              TextButton(onPressed: onReplace, child: const Text('Replace')),
              TextButton(
                  onPressed: onReplaceAll, child: const Text('Replace All')),
            ],
          ),
        ],
      ),
    );
  }
}