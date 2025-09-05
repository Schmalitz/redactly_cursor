import 'package:redactly/screens/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Öffnet ein nativer-Style Dialog mit dem OptionsPanel (JSON Export/Import).
Future<void> showOptionsDialog({
  required BuildContext context,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final maxW = 720.0; // genug Platz für zwei Buttons + Text
      final maxH = 480.0;

      return Dialog(
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: ProviderScope(  // übernimmt die vorhandenen Provider aus dem Tree
            parent: ProviderScope.containerOf(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Text('Options', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Body
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 8),
                      child: OptionsPanel(),
                    ),
                  ),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
