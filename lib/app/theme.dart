import 'package:flutter/material.dart';

/// Avelo palette, taken from the cat's model sheet.
abstract final class AveloColors {
  static const background = Color(0xFFF6E7B8); // warm mustard paper
  static const surface = Color(0xFFFBF1DE); // belly cream
  static const fur = Color(0xFFE8B87A);
  static const stripe = Color(0xFFB9733F); // cinnamon
  static const ink = Color(0xFF5A3A26); // outline brown
  static const blush = Color(0xFFE9A6A0);
  static const coral = Color(0xFFE8735A); // sweatband, primary action
  static const muted = Color(0xFF8C6B55);
}

ThemeData buildAveloTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AveloColors.coral,
    brightness: Brightness.light,
  ).copyWith(
    primary: AveloColors.coral,
    onPrimary: Colors.white,
    secondary: AveloColors.stripe,
    surface: AveloColors.surface,
    onSurface: AveloColors.ink,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AveloColors.background,
    textTheme: base.textTheme.apply(
      bodyColor: AveloColors.ink,
      displayColor: AveloColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AveloColors.background,
      foregroundColor: AveloColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AveloColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AveloColors.ink, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AveloColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AveloColors.surface,
      indicatorColor: AveloColors.fur.withValues(alpha: 0.6),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
