import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ClipboardService {
  ClipboardService._();

  /// Kopiert [text] in die Zwischenablage.
  /// Zeigt eine SnackBar bei Erfolg/Fehler (wenn [context] vorhanden).
  static Future<bool> copyText(BuildContext? context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _toast(context, 'Copied to clipboard');
      return true;
    } on PlatformException catch (e) {
      _toast(context, 'Clipboard error: ${e.message ?? e.code}');
      _log('Clipboard setData failed: $e');
      return false;
    } catch (e) {
      _toast(context, 'Clipboard error');
      _log('Clipboard setData failed: $e');
      return false;
    }
  }

  /// Liest Text aus der Zwischenablage.
  /// Gibt `null` zurück, wenn leer oder Fehler; optional SnackBar.
  static Future<String?> pasteText(BuildContext? context, {bool notifyOnEmpty = false}) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) {
        if (notifyOnEmpty) _toast(context, 'Clipboard is empty');
        return null;
      }
      return text;
    } on PlatformException catch (e) {
      _toast(context, 'Clipboard error: ${e.message ?? e.code}');
      _log('Clipboard getData failed: $e');
      return null;
    } catch (e) {
      _toast(context, 'Clipboard error');
      _log('Clipboard getData failed: $e');
      return null;
    }
  }

  // -------- helpers --------

  static void _toast(BuildContext? context, String msg) {
    if (context == null) return;
    // SnackBar nur zeigen, wenn ein Scaffold vorhanden ist.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  static void _log(Object msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(msg);
    }
  }
}
