import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/screens/editor_screen/widgets/preview_text_widget.dart';
import 'package:redactly/theme/app_colors.dart';

class PreviewColumn extends ConsumerWidget {
  const PreviewColumn({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasClients = scrollController.hasClients;
    final mode = ref.watch(redactModeProvider);

    final previewDecoration = BoxDecoration(
      color: theme.cPreview,
      border: Border.all(color: theme.cStroke),
      borderRadius: BorderRadius.circular(12),
    );

    final headerLabel =
    (mode == RedactMode.anonymize) ? 'Placeholdered Output' : 'Edited Output';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(label: headerLabel),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: previewDecoration,
              padding: const EdgeInsets.all(12),
              child: (hasClients
                  ? Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                interactive: true,
                child: PrimaryScrollController(
                  controller: scrollController,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    primary: false,
                    child: const SizedBox(
                      width: double.infinity,
                      child: PreviewTextWidget(),
                    ),
                  ),
                ),
              )
                  : PrimaryScrollController(
                controller: scrollController,
                child: SingleChildScrollView(
                  controller: scrollController,
                  primary: false,
                  child: const SizedBox(
                    width: double.infinity,
                    child: PreviewTextWidget(),
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        const SizedBox(width: 28),
      ],
    );
  }
}
