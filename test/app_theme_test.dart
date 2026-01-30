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

    group('fileCount', () {
      test('1 → «1 файл»', () {
        expect(AppTheme.fileCount(1), '1 файл');
      });
      test('2, 3, 4 → «N файла»', () {
        expect(AppTheme.fileCount(2), '2 файла');
        expect(AppTheme.fileCount(3), '3 файла');
        expect(AppTheme.fileCount(4), '4 файла');
      });
      test('5–20 → «N файлов»', () {
        expect(AppTheme.fileCount(5), '5 файлов');
        expect(AppTheme.fileCount(10), '10 файлов');
        expect(AppTheme.fileCount(20), '20 файлов');
      });
      test('21 → «21 файл» (исключение)', () {
        expect(AppTheme.fileCount(21), '21 файл');
      });
      test('22, 23, 24 → «N файла»', () {
        expect(AppTheme.fileCount(22), '22 файла');
        expect(AppTheme.fileCount(24), '24 файла');
      });
      test('11, 12, 13 → «N файлов»', () {
        expect(AppTheme.fileCount(11), '11 файлов');
        expect(AppTheme.fileCount(12), '12 файлов');
      });
      test('0 → «0 файлов»', () {
        expect(AppTheme.fileCount(0), '0 файлов');
      });
    });
  });
}
