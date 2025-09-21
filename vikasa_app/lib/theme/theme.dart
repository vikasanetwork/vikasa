import 'package:flutter/material.dart';

// Palette
const Color kGold = Color(0xFFD4AF37);
const Color kGoldDark = Color(0xFF8C6E23);
const Color kBackground = Color(0xFF0B0B0F);
const Color kSurface = Color(0xFF121212);

ThemeData buildVikasaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGold,
    brightness: Brightness.dark,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(
      primary: kGold,
      surface: kSurface,
    ),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
    ),
    iconTheme: const IconThemeData(color: kGold),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGold,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    ),
  );

  return base;
}
