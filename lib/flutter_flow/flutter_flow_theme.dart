import 'package:flutter/material.dart';

class FlutterFlowTheme {
  static const Color primaryColor = Color(0xFF363740);
  static const Color secondaryColor = Color(0xFFBF9BF2);
  static const Color tertiaryColor = Color(0xFFC5C352);
  
  static const Color textColor = Color(0xFFFCFDFF);
  static const Color monthlyColor = Color(0xFFC5C352);
  static const Color weeklyColor = Color(0xFFBF9BF2);
  static const Color dailyColor = Color(0xFF6FA6A0);
  
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(
          primaryColor.value,
          <int, Color>{
            50: primaryColor.withOpacity(0.1),
            100: primaryColor.withOpacity(0.2),
            200: primaryColor.withOpacity(0.3),
            300: primaryColor.withOpacity(0.4),
            400: primaryColor.withOpacity(0.5),
            500: primaryColor.withOpacity(0.6),
            600: primaryColor.withOpacity(0.7),
            700: primaryColor.withOpacity(0.8),
            800: primaryColor.withOpacity(0.9),
            900: primaryColor,
          },
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Roboto Flex', color: textColor),
        bodyMedium: TextStyle(fontFamily: 'Roboto Flex', color: textColor),
        displayLarge: TextStyle(fontFamily: 'Roboto Flex', color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Roboto Flex', color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  static ThemeData of(BuildContext context) => theme;
} 