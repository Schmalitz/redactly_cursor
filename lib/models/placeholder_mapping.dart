import 'package:flutter/material.dart';

class PlaceholderMapping {
  final String id; // z. B. uuid
  final String originalText;
  final String placeholder; // z. B. [[NAME1]]
  final Color color;

  PlaceholderMapping({
    required this.id,
    required this.originalText,
    required this.placeholder,
    required this.color,
  });

  PlaceholderMapping copyWith({
    String? originalText,
    String? placeholder,
    Color? color,
  }) {
    return PlaceholderMapping(
      id: id,
      originalText: originalText ?? this.originalText,
      placeholder: placeholder ?? this.placeholder,
      color: color ?? this.color,
    );
  }
}
