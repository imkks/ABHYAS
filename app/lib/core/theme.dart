import 'package:flutter/material.dart';

class AbhyasTheme {
  // Dark Theme Tokens (from spec 2.1)
  static const Color darkBg = Color(0xFF14121F);
  static const Color darkSurface = Color(0xFF1E1B2E);
  static const Color darkSurfaceAlt = Color(0xFF27233B);
  static const Color darkInk = Color(0xFFF1EBDD);
  static const Color darkInkSoft = Color(0xFFB9B0A0);

  static const Color saffron = Color(0xFFE89A47);
  static const Color saffronSoft = Color(0xFF4A3320);
  static const Color leaf = Color(0xFF86A882);
  static const Color sky = Color(0xFF7FA3C0);
  static const Color clay = Color(0xFFD77E66);
  static const Color hold = Color(0xFFA68BC4);
  static const Color line = Color(0xFF34304A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: saffron,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      canvasColor: darkSurfaceAlt,
      dividerColor: line,
      colorScheme: ColorScheme.dark(
        primary: saffron,
        secondary: sky,
        surface: darkSurface,
        background: darkBg,
        error: clay,
        onPrimary: darkBg,
        onSecondary: darkBg,
        onSurface: darkInk,
        onBackground: darkInk,
        onError: darkBg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkInk),
        iconTheme: IconThemeData(color: saffron),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkInk),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: darkInk),
        bodyLarge: TextStyle(fontSize: 16, color: darkInk),
        bodyMedium: TextStyle(fontSize: 14, color: darkInkSoft),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: line, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: darkBg,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: saffron,
        )
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceAlt,
        labelStyle: TextStyle(color: darkInk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: saffron,
        unselectedItemColor: darkInkSoft,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      )
    );
  }
}
