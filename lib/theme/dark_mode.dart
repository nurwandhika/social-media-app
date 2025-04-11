// dark_mode.dart
import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF15202B), // Twitter dark background
    background: const Color(0xFF15202B),
    primary: const Color(0xFF1DA1F2), // Twitter blue
    secondary: const Color(0xFF38444D), // Twitter dark border
    tertiary: const Color(0xFF8899A6), // Twitter dark gray
    inversePrimary: Colors.white,
  ),
  cardColor: const Color(0xFF192734),
  dividerColor: const Color(0xFF38444D),
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ).copyWith(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 15, color: const Color(0xFF8899A6)),
    bodySmall: TextStyle(fontSize: 13, color: const Color(0xFF8899A6)),
  ),
  iconTheme: IconThemeData(
    color: const Color(0xFF8899A6),
  ),
);