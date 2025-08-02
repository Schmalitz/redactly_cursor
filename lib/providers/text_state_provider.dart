import 'package:flutter_riverpod/flutter_riverpod.dart';

// The listener that caused the circular dependency has been removed.
// This provider is now simple and has no dependencies.
final textInputProvider = StateProvider<String>((ref) => '');
