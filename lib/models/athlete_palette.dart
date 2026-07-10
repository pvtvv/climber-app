import 'package:flutter/material.dart';

/// Fixed palette of 10 athlete colors.
const List<Color> athletePalette = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00897B), // teal
  Color(0xFFFDD835), // yellow
  Color(0xFF6D4C41), // brown
  Color(0xFF546E7A), // blue-grey
  Color(0xFFD81B60), // pink
];

Color colorForIndex(int index) {
  if (index < 0 || index >= athletePalette.length) {
    return athletePalette.first;
  }
  return athletePalette[index];
}
