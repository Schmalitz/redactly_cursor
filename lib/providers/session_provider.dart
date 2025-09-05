import 'dart:async';

import 'package:redactly/models/session.dart';
import 'package:redactly/models/session_props.dart';
import 'package:redactly/models/session_title_mode.dart';
import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/providers/placeholder_mapping_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Aktive Session-ID
final activeSessionIdProvider = StateProvider<String?>((ref) => null);

class SessionNotifier extends StateNotifier<List<Session>> {
  final Ref ref;
  late final Box<Session> _sessionBox;

  bool _isInitialized = false;
  bool _hydrated = false; // blockiert Saves während Load/Wechsel

  Timer? _titleUpdateTimer;

  // --- Debounce ---
  Timer? _saveDebounce;
  static const Duration _saveDelay = Duration(milliseconds: 350);

  SessionNotifier(this.ref) : super([]) {
    _sessionBox = Hive.box<Session>('sessions');

    // Sessions laden (neueste zuerst)
    state = _sessionBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Änderungen an den beiden Inputs/Mappings -> speichern (mit Debounce; nur wenn _hydrated)
    ref.listen<String>(anonymizeInputProvider,   (_, __) => _scheduleSave());
    ref.listen<String>(deanonymizeInputProvider, (_, __) => _scheduleSave());
    ref.listen(placeholderMappingProvider,       (_, __) => _scheduleSave());

    // Moduswechsel: keine Persistenz nötig (Inputs sind getrennt)
    ref.listen<RedactMode>(redactModeProvider, (prev, next) {});
  }

  // ---------- Public API ----------

  void initialize() {
    if (_isInitialized) return;

    if (state.isEmpty) {
      createNewSession();
    } else {
      loadSession(state.first.id);
    }
    _isInitialized = true;
  }

  void createNewSession() {
    final newSession = Session(
      id: const Uuid().v4(),
      title: 'New Session',
      originalInput: '',        // Anonymize Input
      placeholderedInput: '',   // De-Anonymize Input
      mappings: const [],
      createdAt: DateTime.now(),
      props: const SessionProps(),
    );

    _sessionBox.put(newSession.id, newSession);
    state = [newSession, ...state];
    loadSession(newSession.id);
  }

  void loadSession(String id) {
    // Laufenden Debounce abbrechen, damit kein alter Save mehr feuert
    _saveDebounce?.cancel();

    final session = _sessionBox.get(id);
    if (session == null) {
      if (state.isNotEmpty) {
        loadSession(state.first.id);
      } else {
        createNewSession();
      }
      return;
    }

    _hydrated = false; // Ladephase starten

    ref.read(activeSessionIdProvider.notifier).state = id;
    session.lastOpenedAt = DateTime.now();
    session.save();

    // Beide Inputs in ihre jeweiligen Provider laden
    ref.read(anonymizeInputProvider.notifier).state   = session.originalInput;
    ref.read(deanonymizeInputProvider.notifier).state = session.placeholderedInput;

    // Mappings laden
    ref.read(placeholderMappingProvider.notifier).state = session.mappings;

    _hydrated = true; // ab jetzt echte Änderungen speichern
  }

  void deleteSession(String id) {
    // Sicherheitshalber Debounce abbrechen
    _saveDebounce?.cancel();

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
    session.titleMode = SessionTitleMode.userDefined;
    session.updatedAt = DateTime.now();
    session.save();

    // Re-emit, damit UI (Sidebar) sofort aktualisiert
    state = [for (final s in state) s];
  }

  // ---------- Debounce & Persist ----------

  void _scheduleSave() {
    if (!_isInitialized || !_hydrated) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDelay, _persistActiveSession);
  }

  void _persistActiveSession() {
    if (!_isInitialized || !_hydrated) return;

    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == null) return;

    final session = _sessionBox.get(activeId);
    if (session == null) return;

    session.originalInput       = ref.read(anonymizeInputProvider);
    session.placeholderedInput  = ref.read(deanonymizeInputProvider);
    session.mappings            = ref.read(placeholderMappingProvider);
    session.updatedAt           = DateTime.now();
    session.save();
  }

  @override
  void dispose() {
    _titleUpdateTimer?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }
}

final sessionProvider =
StateNotifierProvider<SessionNotifier, List<Session>>((ref) {
  return SessionNotifier(ref);
});
