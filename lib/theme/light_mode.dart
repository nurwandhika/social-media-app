// light_mode.dart
import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    background: Colors.white,
    primary: const Color(0xFF1DA1F2), // Twitter blue
    secondary: Colors.grey.shade200,
    tertiary: const Color(0xFF657786), // Twitter gray
    inversePrimary: Colors.black,
  ),
  cardColor: Colors.white,
  dividerColor: Colors.grey.shade200,
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: const Color(0xFF14171A), // Twitter dark gray
    displayColor: Colors.black,
  ).copyWith(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 15, color: const Color(0xFF657786)),
    bodySmall: TextStyle(fontSize: 13, color: const Color(0xFF657786)),
  ),
  iconTheme: IconThemeData(
    color: const Color(0xFF657786),
  ),
);