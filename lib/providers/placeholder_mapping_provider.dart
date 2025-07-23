import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../models/placeholder_mapping.dart';

class PlaceholderMappingNotifier extends StateNotifier<List<PlaceholderMapping>> {
  PlaceholderMappingNotifier() : super([]);

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
    final existing = state.firstWhereOrNull((m) => m.originalText == selectedText);
    if (existing != null) return;

    final placeholder = _generatePlaceholder();
    final mapping = PlaceholderMapping(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: selectedText,
      placeholder: placeholder,
      color: _getNextColor(),
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

  void clearAll() {
    state = [];
    _colorIndex = 0;
  }
}

final placeholderMappingProvider =
StateNotifierProvider<PlaceholderMappingNotifier, List<PlaceholderMapping>>(
        (ref) => PlaceholderMappingNotifier());
