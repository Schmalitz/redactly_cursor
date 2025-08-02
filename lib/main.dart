import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/models/session_title_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:anonymizer/models/session.dart';
import 'screens/editor_screen/editor_screen.dart';

void main() async {
  // Sicherstellen, dass die Flutter-Bindungen initialisiert sind.
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialisieren
  await Hive.initFlutter();

  // Die generierten Adapter registrieren
  Hive.registerAdapter(SessionAdapter());
  Hive.registerAdapter(SessionTitleModeAdapter());
  Hive.registerAdapter(PlaceholderMappingAdapter());

  // await Hive.deleteBoxFromDisk('sessions');

  // Die "Box" öffnen, in der unsere Sessions gespeichert werden.
  await Hive.openBox<Session>('sessions');

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
