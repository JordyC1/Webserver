import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color.fromRGBO(39, 150, 244, 1);
  static const Color secondaryBlue = Color.fromRGBO(39, 150, 244, 0.8);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF252525);
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color dividerColor = Color(0xFF323232);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: cardBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dividerColor: dividerColor,
        iconTheme: const IconThemeData(
          color: primaryBlue,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: primaryBlue,
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(surfaceColor),
          dataRowColor: MaterialStateProperty.all(cardBackground),
        ),
      );
}
