import 'package:flutter_test/flutter_test.dart';
import 'package:anonymizer/services/mapping_engine.dart';
import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/providers/mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:anonymizer/services/json_backup.dart';

PlaceholderMapping mapItem(String id, String orig, String ph, {bool cs = true, bool whole = true, Color color = Colors.red}) {
  return PlaceholderMapping(
    id: id,
    originalText: orig,
    placeholder: ph,
    colorValue: color.value,
    isCaseSensitive: cs,
    isWholeWord: whole,
  );
}

void main() {
  group('Core workflow – anonymize/deanonymize & backup', () {
    test('anonymize respects longest-first, whole-word & case flags', () async {
      final text = 'Alice met AliceCorp. Öde und öde.';
      final maps = [
        mapItem('1','Alice',     '[A]'),
        mapItem('2','AliceCorp', '[AC]'),
        mapItem('3','Öde',       '[DULL]', cs:false, whole:true),
      ];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.anonymize);
      expect(out, '[A] met [AC]. [DULL] und [DULL].');
    });

    test('deanonymize exact placeholder matches, longest-first', () async {
      final text = 'Hello [NAME] from [COMPANY_INC]';
      final maps = [
        mapItem('1','Alice',    '[NAME]'),
        mapItem('2','ACME Inc.','[COMPANY_INC]'),
      ];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.deanonymize);
      expect(out, 'Hello Alice from ACME Inc.');
    });

    test('backup round-trip (encode/decode)', () {
      final payload = BackupPayload(
        version: backupSchemaVersion,
        mode: 'anonymize',
        anonymizeInput: 'A A',
        deanonymizeInput: '[A] [A]',
        mappings: [
          mapItem('1','Alice','[A]'),
        ],
      );
      final json = encodeBackup(payload);
      final parsed = decodeBackup(json);
      expect(parsed.version, backupSchemaVersion);
      expect(parsed.mode, 'anonymize');
      expect(parsed.anonymizeInput, 'A A');
      expect(parsed.mappings.single.originalText, 'Alice');
    });
  });
}
