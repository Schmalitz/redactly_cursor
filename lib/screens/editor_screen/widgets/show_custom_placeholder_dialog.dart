import 'package:flutter/material.dart';

class CustomPlaceholderResult {
  final String originalText;
  final String placeholder;

  CustomPlaceholderResult({required this.originalText, required this.placeholder});
}

Future<CustomPlaceholderResult?> showCustomPlaceholderDialog({
  required BuildContext context,
}) {
  final TextEditingController originalController = TextEditingController();
  final TextEditingController placeholderController = TextEditingController();

  return showDialog<CustomPlaceholderResult>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Custom Placeholder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: originalController,
            decoration: const InputDecoration(labelText: 'Original Text'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: placeholderController,
            decoration: const InputDecoration(labelText: 'Placeholder (e.g. [PERSON1])'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final original = originalController.text.trim();
            final placeholder = placeholderController.text.trim();
            if (original.isNotEmpty && placeholder.isNotEmpty) {
              Navigator.of(context).pop(CustomPlaceholderResult(
                originalText: original,
                placeholder: placeholder,
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
