import 'dart:io' show Platform;

import 'package:redactly/models/placeholder_delimiter.dart';
import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/models/placeholder_type.dart';
import 'package:redactly/models/session_props.dart';
import 'package:redactly/models/session_title_mode.dart';
import 'package:redactly/services/migration.dart';
import 'package:redactly/models/session.dart';
import 'package:redactly/screens/editor_screen/editor_screen.dart';
import 'package:redactly/services/global_error_handling.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Desktop only
import 'package:window_manager/window_manager.dart';

void main() {
  // ALLES in die Guarded-Zone verlagern
  GlobalErrorHandling.runWithGuards(() async {
    WidgetsFlutterBinding.ensureInitialized();
    GlobalErrorHandling.init();

    // Desktop-Windowing nur auf Desktop-Plattformen
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        minimumSize: Size(900, 600),
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
        await windowManager.show();
        await windowManager.focus();
      });
    }

    // Hive initialisieren (defensiv)
    await Hive.initFlutter();
    Hive
      ..registerAdapter(SessionAdapter())
      ..registerAdapter(SessionTitleModeAdapter())
      ..registerAdapter(PlaceholderMappingAdapter())
      ..registerAdapter(PlaceholderDelimiterAdapter())
      ..registerAdapter(PlaceholderTypeAdapter())
      ..registerAdapter(SessionPropsAdapter());

    try {
      await Hive.openBox<Session>('sessions');
      final box = Hive.box<Session>('sessions');
      try {
        await migrateSessions(box);
      } catch (e) {
        // Fallback: Migration überspringen, App dennoch startbar halten
        // (Fehler landet im globalen Handler-Dialog)
        debugPrint('Migration failed: $e');
      }
    } catch (e) {
      // Falls Box beschädigt ist: neu anlegen
      await Hive.deleteBoxFromDisk('sessions');
      await Hive.openBox<Session>('sessions');
    }

    // runApp *in derselben Zone*
    runApp(
      ProviderScope(
        child: RedactlyApp(
          navigatorKey: GlobalErrorHandling.navigatorKey,
        ),
      ),
    );
  });
}

class RedactlyApp extends StatelessWidget {
  const RedactlyApp({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Colors.yellowAccent,
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Redactly',
      theme: theme,
      home: const EditorScreen(),
    );
  }
}
