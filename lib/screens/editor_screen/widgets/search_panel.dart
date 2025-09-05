import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/settings_provider.dart';

class SearchPanel extends ConsumerStatefulWidget {
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
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  late final TextEditingController _searchC;
  late final TextEditingController _replaceC;

  @override
  void initState() {
    super.initState();
    _searchC  = TextEditingController(text: ref.read(searchQueryProvider));
    _replaceC = TextEditingController(text: ref.read(replaceQueryProvider));
  }

  @override
  void dispose() {
    _searchC.dispose();
    _replaceC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep controllers in sync with provider changes
    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (_searchC.text != next) {
        final sel = _searchC.selection;
        _searchC.value = TextEditingValue(text: next, selection: sel);
      }
    });
    ref.listen<String>(replaceQueryProvider, (prev, next) {
      if (_replaceC.text != next) {
        final sel = _replaceC.selection;
        _replaceC.value = TextEditingValue(text: next, selection: sel);
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchC,
                  onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                  onSubmitted: (_) => widget.onFindNext(),
                  decoration: const InputDecoration(
                    hintText: 'Search for...',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _replaceC,
                  onChanged: (v) => ref.read(replaceQueryProvider.notifier).state = v,
                  decoration: const InputDecoration(
                    hintText: 'Replace with...',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: widget.onFindNext,   child: const Text('Find Next')),
              TextButton(onPressed: widget.onReplace,    child: const Text('Replace')),
              TextButton(onPressed: widget.onReplaceAll, child: const Text('Replace All')),
            ],
          ),
        ],
      ),
    );
  }
}
