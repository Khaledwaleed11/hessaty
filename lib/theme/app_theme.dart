import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6C4AB6);
  static const Color secondary = Color(0xFF9475D1);

  static const Color lightBackground = Color(0xFFF8F7FC);
  static const Color darkBackground = Color(0xFF110E16);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,

    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,

      primaryContainer: Color(0xFFE9DFFF),
      onPrimaryContainer: Color(0xFF29134F),

      secondary: secondary,
      onSecondary: Colors.white,

      secondaryContainer: Color(0xFFEDE6FA),
      onSecondaryContainer: Color(0xFF2E1E42),

      surface: Colors.white,
      onSurface: Color(0xFF211D27),

      surfaceContainerLowest: Color(0xFFF8F7FC),
      surfaceContainerLow: Color(0xFFF4F1F9),
      surfaceContainer: Color(0xFFEEEAF4),
      surfaceContainerHigh: Color(0xFFE5E0EC),
      surfaceContainerHighest: Color(0xFFDCD6E5),

      onSurfaceVariant: Color(0xFF6D6675),

      outline: Color(0xFFC9C2D2),
      outlineVariant: Color(0xFFE1DCE7),

      error: Color(0xFFBA1A1A),
      onError: Colors.white,

      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF211D27),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),

      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFE1DCE7)),
      ),

      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),

      hintStyle: const TextStyle(
        color: Color(0xFF90899A),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,

        side: const BorderSide(color: primary),

        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE1DCE7),
      thickness: 1,
      space: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFB28BEA),
      onPrimary: Color(0xFF2B124F),

      primaryContainer: Color(0xFF53387E),
      onPrimaryContainer: Color(0xFFEEDDFF),

      secondary: Color(0xFFC7A8F0),
      onSecondary: Color(0xFF33204D),

      secondaryContainer: Color(0xFF493863),
      onSecondaryContainer: Color(0xFFEEDFFF),

      surface: Color(0xFF19151D),
      onSurface: Color(0xFFF0EAF3),

      surfaceContainerLowest: Color(0xFF0D0A10),
      surfaceContainerLow: Color(0xFF141017),
      surfaceContainer: Color(0xFF1D1821),
      surfaceContainerHigh: Color(0xFF27212C),
      surfaceContainerHighest: Color(0xFF322A38),

      onSurfaceVariant: Color(0xFFC5BACB),

      outline: Color(0xFF64596B),
      outlineVariant: Color(0xFF463D4D),

      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),

      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF0EAF3),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Color(0xFF19151D),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1D1821),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),

      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFF463D4D)),
      ),

      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFB28BEA), width: 1.5),
      ),

      hintStyle: const TextStyle(
        color: Color(0xFF968B9D),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Color(0xFFB28BEA),
        foregroundColor: Color(0xFF2B124F),
        elevation: 0,

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFFB28BEA),

        side: const BorderSide(color: Color(0xFFB28BEA)),

        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF463D4D),
      thickness: 1,
      space: 1,
    ),
  );
}
