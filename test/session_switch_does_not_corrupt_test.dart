import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:redactly/models/session.dart';
import 'package:redactly/models/session_props.dart';
import 'package:redactly/models/session_title_mode.dart';
import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/models/placeholder_delimiter.dart';
import 'package:redactly/models/placeholder_type.dart';

import 'package:redactly/providers/session_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('redactly_hive_test_');
    Hive
      ..init(tempDir.path)
      ..registerAdapter(SessionAdapter())
      ..registerAdapter(SessionTitleModeAdapter())
      ..registerAdapter(PlaceholderMappingAdapter())
      ..registerAdapter(PlaceholderDelimiterAdapter())
      ..registerAdapter(PlaceholderTypeAdapter())
      ..registerAdapter(SessionPropsAdapter());

    await Hive.openBox<Session>('sessions');
  });

  tearDownAll(() async {
    try {
      await Hive.box<Session>('sessions').close();
    } catch (_) {}
    try {
      await Hive.close();
    } catch (_) {}
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  tearDown(() async {
    await Hive.box<Session>('sessions').clear();
  });

  test('pending save must not overwrite other session when switching', () async {
    final box = Hive.box<Session>('sessions');

    final sessionA = Session(
      id: 'session-A',
      title: 'Session A',
      titleMode: SessionTitleMode.auto,
      originalInput: 'Original A',
      placeholderedInput: 'Placeholdered A',
      mappings: const <PlaceholderMapping>[],
      createdAt: DateTime(2024, 1, 1),
      props: const SessionProps(),
    );

    final sessionB = Session(
      id: 'session-B',
      title: 'Session B',
      titleMode: SessionTitleMode.auto,
      originalInput: 'Original B',
      placeholderedInput: 'Placeholdered B',
      mappings: const <PlaceholderMapping>[],
      createdAt: DateTime(2024, 1, 2),
      props: const SessionProps(),
    );

    await box.put(sessionA.id, sessionA);
    await box.put(sessionB.id, sessionB);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // SessionNotifier wird konstruiert und braucht initialize() (normalerweise im UI initState).
    final notifier = container.read(sessionProvider.notifier);
    notifier.initialize();

    // Neueste Session (B) sollte aktiv sein.
    expect(container.read(activeSessionIdProvider), equals('session-B'));

    // User edit in B (triggert scheduleSave via ref.listen).
    const editedTextForB = 'Edited B content';
    container.read(anonymizeInputProvider.notifier).state = editedTextForB;

    // Sofort Session wechseln (kritischer Fall: debounce-save darf A nicht überschreiben).
    notifier.loadSession('session-A');

    expect(container.read(activeSessionIdProvider), equals('session-A'));

    // Über Debounce-Zeit warten (Timer im SessionNotifier).
    await Future<void>.delayed(const Duration(seconds: 1));

    final storedA = box.get('session-A')!;
    final storedB = box.get('session-B')!;

    // Wichtigster Invariant: A darf nicht überschrieben werden.
    expect(storedA.originalInput, equals('Original A'));

    // Optional (je nach gewünschter Semantik):
    // Wenn du willst, dass B-Edit "trotz Switch" gespeichert wird, muss das Produktverhalten
    // das auch garantieren (z.B. save-before-switch). Dann kannst du diese Zeile aktiv lassen.
    // expect(storedB.originalInput, equals(editedTextForB));

    // Aktuell ist es völlig okay, hier erstmal nur sicherzustellen, dass A nicht korrupt wird.
    // (Ob B gespeichert wird, ist eine separate Produktentscheidung.)
    expect(storedB.originalInput, anyOf(equals('Original B'), equals(editedTextForB)));
  });
}
