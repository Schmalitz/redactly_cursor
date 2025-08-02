import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'placeholder_mapping.g.dart';

@HiveType(typeId: 1)
class PlaceholderMapping extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalText;

  @HiveField(2)
  final String placeholder;

  @HiveField(3)
  final int colorValue; // Hive speichert diesen int-Wert

  @HiveField(4)
  final bool isCaseSensitive;

  @HiveField(5)
  final bool isWholeWord;

  // Getter, um das Color-Objekt bequem zu nutzen
  Color get color => Color(colorValue);

  // KORRIGIERT: Der Konstruktor erwartet jetzt 'colorValue' (int) statt 'Color'.
  // Das ist für den Hive-Generator verständlich.
  PlaceholderMapping({
    required this.id,
    required this.originalText,
    required this.placeholder,
    required this.colorValue,
    this.isCaseSensitive = true,
    this.isWholeWord = true,
  });

  // copyWith wurde ebenfalls angepasst.
  PlaceholderMapping copyWith({
    String? originalText,
    String? placeholder,
    Color? color,
    bool? isCaseSensitive,
    bool? isWholeWord,
  }) {
    return PlaceholderMapping(
      id: id,
      originalText: originalText ?? this.originalText,
      placeholder: placeholder ?? this.placeholder,
      colorValue: color?.value ?? this.colorValue,
      isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
      isWholeWord: isWholeWord ?? this.isWholeWord,
    );
  }
}
