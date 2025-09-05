import 'dart:async';
import 'dart:ui' as ui show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class GlobalErrorHandling {
  GlobalErrorHandling._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static bool _dialogOpen = false;

  static void init() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      _show(details.exceptionAsString());
    };

    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _show(error.toString());
      return true;
    };
  }

  /// MINIMAL-ÄNDERUNG: runWithGuards nimmt jetzt eine async-Funktion entgegen
  /// und führt *alles* (Bindings, init, runApp) in derselben Zone aus.
  static void runWithGuards(FutureOr<void> Function() body) {
    runZonedGuarded(
          () async => await body(),
          (error, stack) => _show(error.toString()),
    );
  }

  static void _show(String message) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || _dialogOpen) return;

    _dialogOpen = true;
    Future.microtask(() async {
      try {
        await showDialog<void>(
          context: ctx,
          builder: (c) => AlertDialog(
            title: const Text('Unexpected error'),
            content: Text(
              message.length > 800 ? '${message.substring(0, 800)}…' : message,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        _dialogOpen = false;
      }
    });
  }
}
