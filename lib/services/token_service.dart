import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/text_state_provider.dart';

class TokenService extends StateNotifier<Map<String, String>> {
  TokenService(this.ref) : super({});
  final Ref ref;
  int _tokenCounter = 1;

  void replaceWithToken(String original) {
    if (original.trim().isEmpty) return;

    // Token generieren oder vorhandenen nehmen
    final token = state.entries.firstWhere(
          (e) => e.key == original,
      orElse: () => MapEntry(original, '[[TOKEN$_tokenCounter]]'),
    ).value;

    if (!state.containsKey(original)) {
      _tokenCounter++;
      state = {...state, original: token};
    }

    // Text ersetzen
    final oldText = ref.read(textInputProvider);
    final newText = oldText.replaceAll(original, token);
    ref.read(textInputProvider.notifier).state = newText;
  }
}
