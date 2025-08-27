import 'package:flutter/material.dart';
import 'package:anonymizer/screens/editor_screen/widgets/preview_text_widget.dart';
import 'package:anonymizer/theme/app_colors.dart';

class PreviewColumn extends StatelessWidget {
  const PreviewColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final previewDecoration = BoxDecoration(
      color: theme.cPreview,
      border: Border.all(color: theme.cStroke),
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      // top auf 8 vereinheitlicht
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: previewDecoration,
              padding: const EdgeInsets.all(12),
              child: const Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  primary: true,
                  child: SizedBox(
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
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge; // 14pt, w600

    return Row(
      children: const [
        // gleiche Typo wie in den anderen Spalten
        _HeaderLabel(text: 'Preview'),
        Spacer(),
        // Platzhalter für (optionale) Icons rechts
        SizedBox(width: 28),
      ],
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}
