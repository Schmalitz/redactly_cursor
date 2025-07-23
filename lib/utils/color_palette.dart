import 'package:flutter/material.dart';

class AppColorPalette {
  static final List<Color> _colors = [
    Colors.lightBlueAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.deepPurpleAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];

  static Color getNext(int index) {
    return _colors[index % _colors.length];
  }
}
