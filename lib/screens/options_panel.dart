import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anonymizer/providers/mode_provider.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:anonymizer/services/json_backup.dart';

class OptionsPanel extends ConsumerWidget {
  const OptionsPanel({super.key});

  Future<void> _exportToClipboard(BuildContext context, WidgetRef ref) async {
    final payload = BackupPayload(
      version: backupSchemaVersion,
      mode: redactModeToString(ref.read(redactModeProvider)),
      anonymizeInput: ref.read(anonymizeInputProvider),
      deanonymizeInput: ref.read(deanonymizeInputProvider),
      mappings: [...ref.read(placeholderMappingProvider)],
    );
    await Clipboard.setData(ClipboardData(text: encodeBackup(payload)));
    _toast(context, 'Exported JSON to clipboard');
  }

  Future<void> _importFromClipboard(BuildContext context, WidgetRef ref) async {
    final raw = (await Clipboard.getData('text/plain'))?.text ?? '';
    if (raw.trim().isEmpty) {
      _toast(context, 'Clipboard is empty');
      return;
    }
    try {
      final payload = decodeBackup(raw);
      ref.read(redactModeProvider.notifier).state = redactModeFromString(payload.mode);
      ref.read(anonymizeInputProvider.notifier).state = payload.anonymizeInput;
      ref.read(deanonymizeInputProvider.notifier).state = payload.deanonymizeInput;
      ref.read(placeholderMappingProvider.notifier).replaceAll(payload.mappings);
      _toast(context, 'Import successful');
    } catch (_) {
      _toast(context, 'Invalid JSON backup');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Options', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportToClipboard(context, ref),
                icon: const Icon(Icons.upload),
                label: const Text('Export JSON (Clipboard)'),
              ),
              OutlinedButton.icon(
                onPressed: () => _importFromClipboard(context, ref),
                icon: const Icon(Icons.download),
                label: const Text('Import JSON (Clipboard)'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Backup/Restore your session (placeholders, inputs, mode). Data stays on your device.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1200),
    ));
  }
}
