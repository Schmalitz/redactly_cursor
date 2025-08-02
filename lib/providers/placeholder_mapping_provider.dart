import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:anonymizer/models/placeholder_mapping.dart';
import 'settings_provider.dart';

class PlaceholderMappingNotifier extends StateNotifier<List<PlaceholderMapping>> {
  final Ref ref;
  PlaceholderMappingNotifier(this.ref) : super([]);

  final List<Color> _availableColors = [
    Colors.deepOrange.shade200,
    Colors.lightBlue.shade200,
    Colors.lightGreen.shade200,
    Colors.purple.shade200,
    Colors.red.shade200,
    Colors.teal.shade200,
    Colors.brown.shade200,
  ];

  int _colorIndex = 0;

  void addMapping(String selectedText) {
    final isCaseSensitiveGlobal = ref.read(caseSensitiveProvider);
    final isWholeWordGlobal = ref.read(wholeWordProvider);

    final existing = state.firstWhereOrNull((m) => isCaseSensitiveGlobal
        ? m.originalText == selectedText
        : m.originalText.toLowerCase() == selectedText.toLowerCase());

    if (existing != null) return;

    final placeholder = _generatePlaceholder();
    final nextColor = _getNextColor();

    final mapping = PlaceholderMapping(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: selectedText,
      placeholder: placeholder,
      colorValue: nextColor.value,
      isCaseSensitive: isCaseSensitiveGlobal,
      isWholeWord: isWholeWordGlobal,
    );

    state = [...state, mapping];
  }

  void addCustomMapping({required String originalText, required String placeholder}) {
    final existing = state.firstWhereOrNull((m) => m.placeholder == placeholder);
    if (existing != null) return;

    final nextColor = _getNextColor();
    final isCaseSensitiveGlobal = ref.read(caseSensitiveProvider);
    final isWholeWordGlobal = ref.read(wholeWordProvider);

    final mapping = PlaceholderMapping(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: originalText.trim(),
      placeholder: placeholder.trim(),
      colorValue: nextColor.value,
      isCaseSensitive: isCaseSensitiveGlobal,
      isWholeWord: isWholeWordGlobal,
    );

    state = [...state, mapping];
  }

  String _generatePlaceholder() {
    final count = state.length + 1;
    return '[PLZH$count]';
  }

  Color _getNextColor() {
    final color = _availableColors[_colorIndex % _availableColors.length];
    _colorIndex++;
    return color;
  }

  void removeMapping(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void updateMapping(PlaceholderMapping updatedMapping) {
    state = [
      for (final mapping in state)
        if (mapping.id == updatedMapping.id) updatedMapping else mapping,
    ];
  }

  void clearAll() {
    state = [];
    _colorIndex = 0;
  }
}

final placeholderMappingProvider =
StateNotifierProvider<PlaceholderMappingNotifier, List<PlaceholderMapping>>(
        (ref) => PlaceholderMappingNotifier(ref));
