import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/session.dart';
import '../providers/placeholder_mapping_provider.dart';
import '../providers/text_state_provider.dart';

class SessionNotifier extends StateNotifier<List<Session>> {
  final Ref ref;
  SessionNotifier(this.ref) : super([]);

  var _uuid = const Uuid();

  void createNewSession() {
    final newSession = Session(
      id: _uuid.v4(),
      title: 'Neue Session',
      content: '',
      mappings: [],
      createdAt: DateTime.now(),
    );
    state = [newSession, ...state];
    loadSession(newSession.id);
  }

  void loadSession(String id) {
    final session = state.firstWhere((s) => s.id == id);
    ref.read(textInputProvider.notifier).state = session.content;
    ref.read(placeholderMappingProvider.notifier).state = session.mappings;
  }

  void saveCurrentSession(String id) {
    state = [
      for (final session in state)
        if (session.id == id)
          session.copyWith(
            content: ref.read(textInputProvider),
            mappings: ref.read(placeholderMappingProvider),
          )
        else
          session,
    ];
  }

  void deleteSession(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void renameSession(String id, String newTitle) {
    state = [
      for (final session in state)
        if (session.id == id)
          session.copyWith(title: newTitle)
        else
          session,
    ];
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, List<Session>>(
      (ref) => SessionNotifier(ref),
);

final activeSessionIdProvider = StateProvider<String?>((ref) => null);