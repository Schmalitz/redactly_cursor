import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/screens/editor_screen/widgets/mapping_list_widget.dart';

class PlaceholderColumn extends ConsumerWidget {
  const PlaceholderColumn({
    super.key,
    required this.verticalController,
    required this.horizontalController,
    required this.contentWidth,
    this.outerPaddingLR = 6,
    this.isEmpty = false,
  });

  final ScrollController verticalController;
  final ScrollController horizontalController;
  final double contentWidth;
  final double outerPaddingLR;
  final bool isEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasH = horizontalController.hasClients;
    final hasV = verticalController.hasClients;

    Widget body;
    if (isEmpty) {
      body = SizedBox(
        width: contentWidth,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Noch keine Platzhalter gesetzt.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      body = (hasH
          ? Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        interactive: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        child: PrimaryScrollController(
          controller: horizontalController,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            primary: false,
            child: SizedBox(
              width: contentWidth,
              child: (hasV
                  ? Scrollbar(
                controller: verticalController,
                thumbVisibility: true,
                interactive: true,
                child: MappingListWidget(controller: verticalController),
              )
                  : MappingListWidget(controller: verticalController)),
            ),
          ),
        ),
      )
          : PrimaryScrollController(
        controller: horizontalController,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          primary: false,
          child: SizedBox(
            width: contentWidth,
            child: (hasV
                ? Scrollbar(
              controller: verticalController,
              thumbVisibility: true,
              interactive: true,
              child: MappingListWidget(controller: verticalController),
            )
                : MappingListWidget(controller: verticalController)),
          ),
        ),
      ));
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(outerPaddingLR, 8, outerPaddingLR, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 8),
          Expanded(child: body),
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
    return Row(
      children: const [
        // Einzeilig, kein Softwrap, Ellipsis statt Umbruch
        Expanded(
          child: Text(
            'Placeholders',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 28),
      ],
    );
  }
}
