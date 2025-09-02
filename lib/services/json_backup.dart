import 'dart:convert';
import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/providers/mode_provider.dart';

/// Dateiformat-Version für künftige Migrationen
const backupSchemaVersion = 1;

/// Daten, die wir als Session sichern wollen
class BackupPayload {
  final int version;
  final String mode;              // "anonymize" | "deanonymize"
  final String anonymizeInput;
  final String deanonymizeInput;
  final List<PlaceholderMapping> mappings;

  BackupPayload({
    required this.version,
    required this.mode,
    required this.anonymizeInput,
    required this.deanonymizeInput,
    required this.mappings,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'mode': mode,
    'anonymizeInput': anonymizeInput,
    'deanonymizeInput': deanonymizeInput,
    'mappings': mappings.map((m) => _mapToJson(m)).toList(),
  };

  static BackupPayload fromJson(Map<String, dynamic> json) {
    final v = (json['version'] as num?)?.toInt() ?? 1;
    final mode = (json['mode'] as String?) ?? 'anonymize';
    final a = (json['anonymizeInput'] as String?) ?? '';
    final d = (json['deanonymizeInput'] as String?) ?? '';
    final list = (json['mappings'] as List?) ?? const [];
    final mappings = list.map((e) => _mapFromJson(e as Map<String, dynamic>)).toList();
    return BackupPayload(
      version: v,
      mode: mode,
      anonymizeInput: a,
      deanonymizeInput: d,
      mappings: mappings,
    );
  }

  static Map<String, dynamic> _mapToJson(PlaceholderMapping m) => {
    'id': m.id,
    'originalText': m.originalText,
    'placeholder': m.placeholder,
    'colorValue': m.colorValue,
    'isCaseSensitive': m.isCaseSensitive,
    'isWholeWord': m.isWholeWord,
  };

  static PlaceholderMapping _mapFromJson(Map<String, dynamic> j) {
    return PlaceholderMapping(
      id: (j['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      originalText: (j['originalText'] as String?) ?? '',
      placeholder: (j['placeholder'] as String?) ?? '',
      colorValue: (j['colorValue'] as num?)?.toInt() ?? 0xFFB39DDB, // fallback
      isCaseSensitive: j['isCaseSensitive'] == true,
      isWholeWord: j['isWholeWord'] != false,
    );
  }
}

/// Helper: serialize/deserialize
String encodeBackup(BackupPayload payload) => const JsonEncoder.withIndent('  ').convert(payload.toJson());
BackupPayload decodeBackup(String s) => BackupPayload.fromJson(jsonDecode(s) as Map<String, dynamic>);

/// Helper: Modus-String
String redactModeToString(RedactMode m) => m == RedactMode.anonymize ? 'anonymize' : 'deanonymize';
RedactMode redactModeFromString(String s) => s == 'deanonymize' ? RedactMode.deanonymize : RedactMode.anonymize;
