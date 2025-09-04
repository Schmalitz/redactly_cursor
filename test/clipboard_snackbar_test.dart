import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/system_channels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anonymizer/services/clipboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Default: Erfolg für set/get
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.setData') return true;
      if (call.method == 'Clipboard.getData') return <String, dynamic>{'text': 'ok'};
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget _host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );

  testWidgets('copyText shows success SnackBar', (tester) async {
    await tester.pumpWidget(_host(Builder(
      builder: (ctx) => ElevatedButton(
        onPressed: () => ClipboardService.copyText(ctx, 'hello'),
        child: const Text('copy'),
      ),
    )));

    await tester.tap(find.text('copy'));
    await tester.pump(); // enqueue
    await tester.pump(const Duration(milliseconds: 100)); // show

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('copyText shows error SnackBar on failure', (tester) async {
    // Fehler simulieren
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'CLIP_ERR', message: 'nope');
      }
      return null;
    });

    await tester.pumpWidget(_host(Builder(
      builder: (ctx) => ElevatedButton(
        onPressed: () => ClipboardService.copyText(ctx, 'hello'),
        child: const Text('copy'),
      ),
    )));

    await tester.tap(find.text('copy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Clipboard error'), findsOneWidget);
  });

  testWidgets('pasteText notifies on empty clipboard when notifyOnEmpty=true', (tester) async {
    // Leere Zwischenablage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': ''};
      }
      return null;
    });

    await tester.pumpWidget(_host(Builder(
      builder: (ctx) => ElevatedButton(
        onPressed: () => ClipboardService.pasteText(ctx, notifyOnEmpty: true),
        child: const Text('paste'),
      ),
    )));

    await tester.tap(find.text('paste'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Clipboard is empty'), findsOneWidget);
  });
}
