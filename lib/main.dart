import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/editor_screen/editor_screen.dart';

void main() {
  runApp(const RedactlyApp());
}

class RedactlyApp extends StatelessWidget {
  const RedactlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Redactly',
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
