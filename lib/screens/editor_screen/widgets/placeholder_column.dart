import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/screens/editor_screen/widgets/mapping_list_widget.dart';

class PlaceholderColumn extends ConsumerWidget {
  const PlaceholderColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: _Header(),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: MappingListWidget(),
            ),
          ),
          SizedBox(height: 8),
          // AddCustomPlaceholder-Button wurde in die ActionBar verlegt
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "Placeholders",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const Spacer(),
        SizedBox(width: IconTheme.of(context).size ?? 24),
      ],
    );
  }
}
