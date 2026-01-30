import 'package:flutter/material.dart';

/// Единая тема приложения: белый, чёрный, серый. Отступы и скругления.
abstract class AppTheme {
  AppTheme._();

  // — Цвета (только белый, чёрный, серый)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFEEEEEE);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color accent = Color(0xFF1A1A1A);
  static const Color success = Color(0xFF424242);
  static const Color error = Color(0xFF424242);

  // — Usability: минимальная область нажатия (px)
  static const double minTouchTarget = 48.0;

  // — Отступы (px)
  static const double pagePadding = 20.0;
  static const double sectionGap = 20.0;
  static const double blockGap = 12.0;
  static const double cardPadding = 20.0;
  static const double titleTop = 24.0;
  static const double titleToSubtitle = 8.0;
  static const double subtitleToContent = 16.0;

  // — Скругления
  static const double radiusCard = 12.0;
  static const double radiusSmall = 8.0;
  static const double radiusSnackBar = 8.0;

  // — Размеры
  static const double iconBoxSize = 48.0;
  static const double iconSize = 26.0;
  static const double dropZoneHeight = 160.0;

  /// Склонение «файл» для числа: 1 файл, 2–4 файла, 5+ файлов (в т.ч. 21 файл, 22 файла).
  static String fileCount(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return '$n файл';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return '$n файла';
    return '$n файлов';
  }
}
