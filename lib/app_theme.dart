import 'package:flutter/material.dart';

/// Единая тема приложения: цвета, отступы, скругления.
abstract class AppTheme {
  AppTheme._();

  // — Цвета
  static const Color background = Color(0xFF0f172a);
  static const Color surface = Color(0xFF1e293b);
  static const Color surfaceVariant = Color(0xFF334155);
  static const Color accent = Color(0xFF38bdf8);
  static const Color accentDim = Color(0x2638bdf8);
  static const Color textPrimary = Color(0xFFf1f5f9);
  static const Color textSecondary = Color(0xFF94a3b8);
  static const Color outline = Color(0xFF475569);
  static const Color success = Color(0xFF22c55e);
  static const Color error = Color(0xFFef4444);

  // — Usability: минимальная область нажатия (px)
  static const double minTouchTarget = 48.0;

  // — Отступы (px)
  static const double pagePadding = 24.0;
  static const double sectionGap = 24.0;
  static const double blockGap = 12.0;
  static const double cardPadding = 20.0;
  static const double titleTop = 40.0;
  static const double titleToSubtitle = 8.0;
  static const double subtitleToContent = 16.0;

  // — Скругления
  static const double radiusCard = 16.0;
  static const double radiusSmall = 12.0;
  static const double radiusSnackBar = 12.0;

  // — Размеры
  static const double iconBoxSize = 48.0;
  static const double iconSize = 26.0;
  static const double dropZoneHeight = 140.0;
}
