import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RedactMode { anonymize, deanonymize }

final redactModeProvider = StateProvider<RedactMode>((ref) => RedactMode.anonymize);
