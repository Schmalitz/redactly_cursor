import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_service.dart';

final textInputProvider = StateProvider<String>((ref) => '');

final tokenizerProvider = StateNotifierProvider<TokenService, Map<String, String>>(
      (ref) => TokenService(ref),
);
