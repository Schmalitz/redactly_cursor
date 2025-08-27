import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/screens/editor_screen/widgets/mapping_list_widget.dart';

class PlaceholderColumn extends ConsumerWidget {
  const PlaceholderColumn({
    super.key,
    required this.verticalController,
    required this.horizontalController,
    required this.contentWidth,
    this.outerPaddingLR = 6, // <- Außenabstand links/rechts fein justierbar
  });

  final ScrollController verticalController;
  final ScrollController horizontalController;
  final double contentWidth;
  final double outerPaddingLR;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      // Außenabstand der Mittelsäule – hier drehst du links/rechts eng!
      padding: EdgeInsets.fromLTRB(outerPaddingLR, 8, outerPaddingLR, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 8),

          // Außen: H-Scrollbar nur bei Bedarf (wenn Viewport < contentWidth)
          Expanded(
            child: Scrollbar(
              controller: horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notif) =>
              notif.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  // ← feste Innenbreite der Spalte (keine Align-Breite mehr!)
                  width: contentWidth,
                  child: Scrollbar(
                    controller: verticalController,
                    thumbVisibility: true,
                    child: MappingListWidget(controller: verticalController),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: const [
        Expanded(child: Text('Placeholders')),
        SizedBox(width: 28), // Platzhalter rechts
      ],
    );
  }
}
