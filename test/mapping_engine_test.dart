import 'package:flutter_test/flutter_test.dart';
import 'package:redactly/services/mapping_engine.dart';
import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/providers/mode_provider.dart';
import 'package:flutter/material.dart';

PlaceholderMapping mapItem(String orig, String ph, {bool caseSensitive = true, bool whole = true}) {
  return PlaceholderMapping(
    id: '1',
    originalText: orig,
    placeholder: ph,
    colorValue: Colors.red.value,
    isCaseSensitive: caseSensitive,
    isWholeWord: whole,
  );
}

void main() {
  group('MappingEngine', () {
    test('Anonymize replaces longest original first', () async {
      final text = 'Alice met AliceCorp.';
      final maps = [
        mapItem('Alice', '[A]'),
        mapItem('AliceCorp', '[AC]'),
      ];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.anonymize);
      expect(out, '[A] met [AC].');
    });

    test('Anonymize whole-word only', () async {
      final text = 'car cart carpet';
      final maps = [mapItem('car', '[C]', whole: true)];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.anonymize);
      expect(out, '[C] cart carpet');
    });

    test('Anonymize case-insensitive', () async {
      final text = 'Alice and ALICE';
      final maps = [mapItem('alice', '[A]', caseSensitive: false)];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.anonymize);
      expect(out, '[A] and [A]');
    });

    test('De-Anonymize exact placeholder match, longest first', () async {
      final text = 'Hello [NAME] from [COMPANY_INC]';
      final maps = [
        mapItem('Alice', '[NAME]'),
        mapItem('ACME Inc.', '[COMPANY_INC]'),
      ];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.deanonymize);
      expect(out, 'Hello Alice from ACME Inc.');
    });

    test('Unicode & diacritics handled safely', () async {
      final text = 'Jürgen works at München Labs.';
      final maps = [mapItem('München', '[CITY]'), mapItem('Jürgen', '[PERSON]')];
      final out = await applyMappingsIsolate(text: text, mappings: maps, mode: RedactMode.anonymize);
      expect(out, '[PERSON] works at [CITY] Labs.');
    });
  });
}
