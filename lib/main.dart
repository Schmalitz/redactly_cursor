import 'package:anonymizer/models/placeholder_delimiter.dart';
import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/models/placeholder_type.dart';
import 'package:anonymizer/models/session_props.dart';
import 'package:anonymizer/models/session_title_mode.dart';
import 'package:anonymizer/services/migration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:anonymizer/models/session.dart';
import 'screens/editor_screen/editor_screen.dart';

// NEU:
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(900, 600),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // NEU: native Ampelknöpfe vollständig ausblenden
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.show();
    await windowManager.focus();
  });

  // Hive initialisieren
  await Hive.initFlutter();

  Hive.registerAdapter(SessionAdapter());
  Hive.registerAdapter(SessionTitleModeAdapter());
  Hive.registerAdapter(PlaceholderMappingAdapter());
  Hive.registerAdapter(PlaceholderDelimiterAdapter());
  Hive.registerAdapter(PlaceholderTypeAdapter());
  Hive.registerAdapter(SessionPropsAdapter());

  // await Hive.deleteBoxFromDisk('sessions');

  // Die "Box" öffnen, in der unsere Sessions gespeichert werden.
  await Hive.openBox<Session>('sessions');

  final box = Hive.box<Session>('sessions');
  await migrateSessions(box);

  runApp(const AnonymizerApp());
}

class AnonymizerApp extends StatelessWidget {
  const AnonymizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Anonymizer',
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF9F9F9),
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Colors.yellowAccent,
          ),
        ),
        home: const EditorScreen(),
      ),
    );
  }
}
