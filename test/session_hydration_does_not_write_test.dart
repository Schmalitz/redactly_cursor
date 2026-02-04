import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:redactly/models/session.dart';
import 'package:redactly/models/session_props.dart';
import 'package:redactly/models/session_title_mode.dart';
import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/models/placeholder_delimiter.dart';
import 'package:redactly/models/placeholder_type.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/session_provider.dart';

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

  test('hydration must not write back to Hive before first user edit', () async {
    final box = Hive.box<Session>('sessions');

    final session = Session(
      id: 's1',
      title: 'S1',
      titleMode: SessionTitleMode.auto,
      originalInput: 'Original',
      placeholderedInput: 'Placeholdered',
      mappings: const <PlaceholderMapping>[],
      createdAt: DateTime(2024, 1, 1),
      props: const SessionProps(),
    );

    await box.put(session.id, session);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(sessionProvider.notifier);

    final before = box.get('s1')!.updatedAt;

    notifier.initialize();

    // Give any queued debounce a chance (should be none due to _hydrated guard)
    await Future<void>.delayed(const Duration(seconds: 1));

    final after = box.get('s1')!.updatedAt;

    expect(after, equals(before));
  });
}
