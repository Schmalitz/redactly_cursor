import 'dart:async';

import 'package:anonymizer/models/session.dart';
import 'package:anonymizer/models/session_title_mode.dart';
import 'package:anonymizer/providers/placeholder_mapping_provider.dart';
import 'package:anonymizer/providers/text_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

final activeSessionIdProvider = StateProvider<String?>((ref) => null);

class SessionNotifier extends StateNotifier<List<Session>> {
  final Ref ref;
  late final Box<Session> _sessionBox;
  bool _isInitialized = false;
  Timer? _titleUpdateTimer;

  SessionNotifier(this.ref) : super([]) {
    _sessionBox = Hive.box<Session>('sessions');
    state = _sessionBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    ref.listen(textInputProvider, (_, next) {
      _debouncedUpdateSessionTitle(next.toString());
      saveCurrentSession();
    });

    ref.listen(placeholderMappingProvider, (_, __) => saveCurrentSession());
  }

  void initialize() {
    if (_isInitialized) return;

    if (state.isEmpty) {
      createNewSession();
    } else {
      loadSession(state.first.id);
    }
    _isInitialized = true;
  }

  final _uuid = const Uuid();

  void createNewSession() {
    final newSession = Session(
      id: _uuid.v4(),
      title: 'New Session',
      content: '',
      mappings: [],
      createdAt: DateTime.now(),
    );
    _sessionBox.put(newSession.id, newSession);
    state = [newSession, ...state];
    loadSession(newSession.id);
  }

  void loadSession(String id) {
    final sessionToLoad = _sessionBox.get(id);
    if (sessionToLoad == null) {
      if (state.isNotEmpty) {
        loadSession(state.first.id);
      } else {
        createNewSession();
      }
      return;
    }

    ref.read(activeSessionIdProvider.notifier).state = id;
    ref.read(textInputProvider.notifier).state = sessionToLoad.content;
    ref.read(placeholderMappingProvider.notifier).state = sessionToLoad.mappings;
  }

  void saveCurrentSession() {
    if (!_isInitialized) return;

    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;

    final session = _sessionBox.get(activeId);
    if (session == null) return;

    session.content = ref.read(textInputProvider);
    session.mappings = ref.read(placeholderMappingProvider);

    session.save();
  }

  void _debouncedUpdateSessionTitle(String newText) {
    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;

    final session = _sessionBox.get(activeId);
    if (session == null) return;

    if (session.titleMode != SessionTitleMode.auto) return;

    _titleUpdateTimer?.cancel();
    _titleUpdateTimer = Timer(const Duration(milliseconds: 400), () {
      final trimmedText = newText.trim();
      if (trimmedText.length < 8) return;

      final firstLine = trimmedText.split('\n').first;
      const maxLength = 25;
      final newTitle = firstLine.length > maxLength
          ? '${firstLine.substring(0, maxLength)}...'
          : firstLine;

      if (newTitle.isNotEmpty) {
        session.title = newTitle;
        session.save();

        state = [
          for (final s in state)
            if (s.id == activeId) s else s
        ];
      }
    });
  }

  void deleteSession(String id) {
    _sessionBox.delete(id);
    final wasActive = ref.read(activeSessionIdProvider) == id;
    state = state.where((s) => s.id != id).toList();

    if (wasActive) {
      if (state.isNotEmpty) {
        loadSession(state.first.id);
      } else {
        createNewSession();
      }
    }
  }

  void renameSession(String id, String newTitle) {
    final session = _sessionBox.get(id);
    if (session == null) return;

    session.title = newTitle;
    session.titleMode = SessionTitleMode.userDefined; // statt bool
    session.save();

    state = [
      for (final s in state)
        if (s.id == id) s else s
    ];
  }

  @override
  void dispose() {
    _titleUpdateTimer?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, List<Session>>(
      (ref) => SessionNotifier(ref),
);
