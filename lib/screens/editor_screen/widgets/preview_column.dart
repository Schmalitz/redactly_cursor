import 'package:flutter/material.dart';
import 'package:anonymizer/screens/editor_screen/widgets/preview_text_widget.dart';

class PreviewColumn extends StatelessWidget {
  const PreviewColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final previewColor = Colors.grey.shade200;
    final borderColor = Colors.grey.shade400;
    const contentPadding = EdgeInsets.all(12.0);

    final previewDecoration = BoxDecoration(
      color: previewColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Preview",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const Spacer(),
              SizedBox(width: IconTheme.of(context).size ?? 24),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: previewDecoration,
              padding: contentPadding,
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
