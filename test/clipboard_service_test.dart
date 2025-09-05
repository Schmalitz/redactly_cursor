import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/src/services/system_channels.dart';
import 'package:redactly/services/clipboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('copyText returns true on platform success', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        // success
        return true;
      }
      return null;
    });

    final ok = await ClipboardService.copyText(null, 'hello');
    expect(ok, isTrue);
  });

  test('copyText returns false on PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'CLIP_ERR', message: 'fail');
      }
      return null;
    });

    final ok = await ClipboardService.copyText(null, 'hello');
    expect(ok, isFalse);
  });

  test('pasteText returns text on platform success', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.getData') {
        // Flutter erwartet {'text': '...'}
        return <String, dynamic>{'text': 'pasted'};
      }
      return null;
    });

    final text = await ClipboardService.pasteText(null);
    expect(text, 'pasted');
  });

  test('pasteText returns null on PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.getData') {
        throw PlatformException(code: 'CLIP_ERR');
      }
      return null;
    });

    final text = await ClipboardService.pasteText(null);
    expect(text, isNull);
  });
}
