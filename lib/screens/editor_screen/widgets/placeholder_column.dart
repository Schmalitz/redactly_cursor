import 'package:flutter/material.dart';
import 'package:anonymizer/screens/editor_screen/widgets/mapping_list_widget.dart';

class PlaceholderColumn extends StatelessWidget {
  const PlaceholderColumn({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
