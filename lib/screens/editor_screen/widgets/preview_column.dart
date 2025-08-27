import 'package:flutter/material.dart';
import 'package:anonymizer/screens/editor_screen/widgets/preview_text_widget.dart';
import 'package:anonymizer/theme/app_colors.dart';

class PreviewColumn extends StatelessWidget {
  const PreviewColumn({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final previewDecoration = BoxDecoration(
      color: theme.cPreview,
      border: Border.all(color: theme.cStroke),
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: previewDecoration,
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                controller: scrollController, // gekoppelt
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: scrollController, // derselbe Controller
                  primary: false,
                  child: const SizedBox(
                    width: double.infinity,
                    child: PreviewTextWidget(),
                  ),
                ),
              ),
            ),
          ),
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
        Text('Preview'),
        Spacer(),
        SizedBox(width: 28),
      ],
    );
  }
}
