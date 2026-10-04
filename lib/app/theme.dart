import 'package:flutter/material.dart';

/// Avelo palette, taken from the cat's model sheet and the living room.
abstract final class AveloColors {
  static const wall = Color(0xFFF4E4BC); // living-room wall, page ground
  static const background = wall;
  static const surface = Color(0xFFFBF1DE); // belly cream, sheets
  static const card = Color(0xFFFFFFFF);
  static const fur = Color(0xFFE8B87A);
  static const stripe = Color(0xFFB9733F); // cinnamon
  static const ink = Color(0xFF5A3A26); // outline brown
  static const text = Color(0xFF4A2F1F);
  static const muted = Color(0xFF7A5640);
  static const blush = Color(0xFFE9A6A0);
  static const coral = Color(0xFFE8735A); // sweatband
  /// Primary action; white text on it passes 4.5:1.
  static const terracotta = Color(0xFFB24B2C);
  static const peach = Color(0xFFF6DCC4); // her-pick card
  static const track = Color(0xFFF1DDB3); // empty dots and bars
}

abstract final class AveloFonts {
  static const display = 'YoungSerif';
  static const body = 'Figtree';
}

/// Serif display style for headlines.
TextStyle display(double size, {Color color = AveloColors.text}) => TextStyle(
  fontFamily: AveloFonts.display,
  fontSize: size,
  height: 1.15,
  color: color,
);

/// Small uppercase label ("HER PICK FOR YOU").
const eyebrow = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  letterSpacing: 1,
  color: AveloColors.muted,
);

ThemeData buildAveloTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AveloColors.coral,
        brightness: Brightness.light,
      ).copyWith(
        primary: AveloColors.terracotta,
        onPrimary: Colors.white,
        secondary: AveloColors.stripe,
        surface: AveloColors.surface,
        onSurface: AveloColors.text,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AveloFonts.body,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AveloColors.background,
    textTheme: base.textTheme.apply(
      bodyColor: AveloColors.text,
      displayColor: AveloColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AveloColors.background,
      foregroundColor: AveloColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AveloFonts.display,
        fontSize: 24,
        color: AveloColors.text,
      ),
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
        backgroundColor: AveloColors.terracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: AveloFonts.body,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AveloColors.terracotta,
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(
          fontFamily: AveloFonts.body,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
