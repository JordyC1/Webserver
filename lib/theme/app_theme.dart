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

  // 🎨 Paleta de colores para tipos de insectos (compatible con tema oscuro)
  static const List<Color> insectTypeColors = [
    Color(0xFF2196F3), // Azul (Principal)
    Color(0xFF4CAF50), // Verde
    Color(0xFFFF9800), // Naranja
    Color(0xFFE91E63), // Rosa/Magenta
    Color(0xFF9C27B0), // Púrpura
    Color(0xFF00BCD4), // Cian
    Color(0xFFFFEB3B), // Amarillo
    Color(0xFFFF5722), // Rojo-Naranja
    Color(0xFF8BC34A), // Verde lima
    Color(0xFF607D8B), // Azul gris
    Color(0xFFFF6F00), // Ámbar oscuro
    Color(0xFFAD1457), // Rosa oscuro
    Color(0xFF1A237E), // Índigo oscuro
    Color(0xFF00695C), // Verde azulado oscuro
    Color(0xFF6A1B9A), // Púrpura oscuro
  ];

  // 🎯 Método para obtener color por índice de tipo de insecto
  static Color getInsectTypeColor(int index) {
    return insectTypeColors[index % insectTypeColors.length];
  }

  // 🎯 Método para obtener color por nombre de tipo de insecto (hash-based)
  static Color getInsectTypeColorByName(String typeName) {
    final hash = typeName.hashCode.abs();
    return insectTypeColors[hash % insectTypeColors.length];
  }

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
