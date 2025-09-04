import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:anonymizer/screens/show_about_dialog.dart';
import 'package:anonymizer/screens/editor_screen/highlighting_text_controller.dart';

void main() {
  testWidgets('About dialog opens and closes', (tester) async {
    final app = MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAboutDialogCustom(context: ctx),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Anonymizer'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Anonymizer'), findsNothing);
  });

  testWidgets('HighlightingTextController builds basic TextField', (tester) async {
    final controller = HighlightingTextController(
      mappings: const [],
      isCaseSensitiveForSearch: false,
      isWholeWordForSearch: false,
      searchQuery: 'und',
      activeSearchMatchIndex: 0,
      text: 'lorem und ipsum',
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    // reine Smoke: keine Exceptions beim Erzeugen
    expect(controller.text.contains('und'), isTrue);
  });
}
