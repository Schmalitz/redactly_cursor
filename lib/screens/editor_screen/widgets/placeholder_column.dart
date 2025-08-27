import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/screens/editor_screen/widgets/mapping_list_widget.dart';

class PlaceholderColumn extends ConsumerWidget {
  const PlaceholderColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      // top auf 8 vereinheitlicht
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Header(),
          SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: MappingListWidget(),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge; // 14pt, w600

    return Row(
      children: [
        Text('Placeholders', style: style),
        const Spacer(),
        // Platzhalter für (optionale) Aktions-Icons – gleiche Breite wie ein IconButton
        const SizedBox(width: 28),
      ],
    );
  }
}
