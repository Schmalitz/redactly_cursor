import 'dart:async';
import 'dart:ui' as ui show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class GlobalErrorHandling {
  GlobalErrorHandling._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static bool _dialogOpen = false;

  /// Einmal beim App-Start aufrufen (vor runApp).
  static void init() {
    // Flutter-Framework-Fehler (z. B. Build/Render)
    FlutterError.onError = (FlutterErrorDetails details) {
      // Optional: in Debug zusätzlich die Standardausgabe behalten
      FlutterError.dumpErrorToConsole(details);
      _show(details.exceptionAsString());
    };

    // Ungefangene Errors aus Platform/Isolates (nicht-UI)
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _show(error.toString());
      return true; // handled
    };
  }

  /// App in Guarded-Zone starten (fängt Future-/Zone-Errors).
  static void runWithGuards(Widget app) {
    runZonedGuarded(
          () => runApp(app),
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
