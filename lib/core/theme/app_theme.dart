import 'package:flutter/material.dart';

class AppTheme {
  // KONUBU Renk Paleti
  static const Color primaryColor = Color(0xFF2C3E50);      // Grafit (koyu gri)
  static const Color backgroundColor = Color(0xFFEFF0DD);   // Bej rengi (User requested)
  static const Color accentColor = Color(0xFF52C41A);       // Soft yeşil
  
  // Metin renkleri
  static const Color textPrimaryColor = Color(0xFF1A1A1A);     // Koyu gri
  static const Color textSecondaryColor = Color(0xFF6C757D);   // Orta gri
  
  // Yardımcı renkler
  static const Color surfaceColor = Colors.white;
  static const Color successColor = Color(0xFF52C41A);      // Soft yeşil
  static const Color errorColor = Color(0xFFE74C3C);        // Soft kırmızı
  static const Color warningColor = Color(0xFFF39C12);      // Soft turuncu
  
  // Dark mode (opsiyonel)
  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkSurfaceColor = Color(0xFF2C3E50);
  static const Color textDarkPrimaryColor = Color(0xFFF8F9FA);
  static const Color textDarkSecondaryColor = Color(0xFF9CA3AF);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: darkSurfaceColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: textDarkPrimaryColor,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
