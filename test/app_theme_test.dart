import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_compressor/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('цвета заданы и непрозрачны', () {
      expect(AppTheme.background.alpha, 0xFF);
      expect(AppTheme.surface.alpha, 0xFF);
      expect(AppTheme.accent.alpha, 0xFF);
      expect(AppTheme.textPrimary.alpha, 0xFF);
      expect(AppTheme.textSecondary.alpha, 0xFF);
      expect(AppTheme.success.alpha, 0xFF);
      expect(AppTheme.error.alpha, 0xFF);
    });

    test('отступы положительные', () {
      expect(AppTheme.pagePadding, greaterThan(0));
      expect(AppTheme.sectionGap, greaterThan(0));
      expect(AppTheme.blockGap, greaterThan(0));
      expect(AppTheme.cardPadding, greaterThan(0));
      expect(AppTheme.radiusCard, greaterThan(0));
      expect(AppTheme.radiusSmall, greaterThan(0));
      expect(AppTheme.minTouchTarget, greaterThanOrEqualTo(48));
    });

    test('минимальная область нажатия не меньше 48', () {
      expect(AppTheme.minTouchTarget, greaterThanOrEqualTo(48));
    });

    test('высота зоны загрузки положительная', () {
      expect(AppTheme.dropZoneHeight, greaterThan(0));
    });
  });
}
