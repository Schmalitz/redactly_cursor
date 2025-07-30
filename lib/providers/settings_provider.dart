import 'package:flutter_riverpod/flutter_riverpod.dart';

final caseSensitiveProvider = StateProvider<bool>((ref) => true);

final wholeWordProvider = StateProvider<bool>((ref) => true);