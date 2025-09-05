import 'package:hive/hive.dart';
import 'package:redactly/models/session.dart';
import 'package:redactly/models/session_props.dart';

Future<void> migrateSessions(Box<Session> box) async {
  for (final session in box.values) {
    final v = session.schemaVersion;

    // V1 -> V2: legacy → aktuelle Struktur
    if (v < 2) {
      // Stelle sicher, dass props nicht null ist
      session.props = session.props ?? const SessionProps();

      session.schemaVersion = 2;
      await session.save();
    }

    // V2 -> V3: future-proof Beispiel
    if (session.schemaVersion < 3) {
      // evtl. Defaults setzen
      session.schemaVersion = 3;
      await session.save();
    }
  }
}