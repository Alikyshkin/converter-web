import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_compressor/action_pages.dart';
import 'package:image_compressor/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('показывает заголовок и подзаголовок', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(),
        ),
      );

      expect(find.text('Image Compressor'), findsOneWidget);
      expect(find.text('Загрузите фото и выберите действие'), findsOneWidget);
    });

    testWidgets('показывает зону загрузки или сообщение для не-web', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(),
        ),
      );

      final dropZoneText = find.text('Перетащите изображения сюда');
      final webOnlyText = find.text('Загрузка файлов доступна в веб-версии');
      expect(dropZoneText.evaluate().isNotEmpty || webOnlyText.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('при initialUploadedCountForTesting: 1 показывает «Загружено: 1 файл»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      expect(find.text('Загружено: 1 файл'), findsOneWidget);
      expect(find.text('Что сделать с фото?'), findsOneWidget);
    });

    testWidgets('при initialUploadedCountForTesting: 3 показывает «Загружено: 3 файла»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 3),
        ),
      );

      expect(find.text('Загружено: 3 файла'), findsOneWidget);
    });

    testWidgets('при загруженных файлах показываются все кнопки инструментов', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 2),
        ),
      );

      expect(find.text('Сжать'), findsOneWidget);
      expect(find.text('Конвертировать'), findsOneWidget);
      expect(find.text('Размер'), findsOneWidget);
      expect(find.text('Повернуть'), findsOneWidget);
      expect(find.text('Отразить'), findsOneWidget);
      expect(find.text('Размытие лиц'), findsOneWidget);
      expect(find.text('Удалить фон'), findsOneWidget);
      expect(find.text('Рисовать'), findsOneWidget);
      expect(find.text('Водяной знак'), findsOneWidget);
      expect(find.text('Размытие'), findsOneWidget);
      expect(find.text('Улучшить качество'), findsOneWidget);
      expect(find.text('Увеличить'), findsOneWidget);
      expect(find.text('Загрузить другие'), findsOneWidget);
    });

    testWidgets('нажатие «Сжать» открывает экран сжатия', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Сжать'));
      await tester.pumpAndSettle();

      expect(find.byType(CompressPage), findsOneWidget);
    });

    testWidgets('нажатие «Конвертировать» открывает экран конвертации', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Конвертировать'));
      await tester.pumpAndSettle();

      expect(find.byType(ConvertPage), findsOneWidget);
    });

    testWidgets('нажатие «Размер» открывает экран изменения размера', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Размер'));
      await tester.pumpAndSettle();

      expect(find.byType(ResizePage), findsOneWidget);
    });

    testWidgets('нажатие «Повернуть» открывает экран поворота', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Повернуть'));
      await tester.pumpAndSettle();

      expect(find.byType(RotatePage), findsOneWidget);
    });

    testWidgets('нажатие «Отразить» открывает экран отражения', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Отразить'));
      await tester.pumpAndSettle();

      expect(find.byType(FlipPage), findsOneWidget);
    });

    testWidgets('«Загрузить другие» возвращает к зоне загрузки', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 2),
        ),
      );

      expect(find.text('Загружено: 2 файла'), findsOneWidget);

      await tester.tap(find.text('Загрузить другие'));
      await tester.pump();

      expect(find.text('Загружено: 2 файла'), findsNothing);
      expect(find.text('Image Compressor'), findsOneWidget);
    });

    testWidgets('при загруженных файлах кнопки инструментов кликабельны', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('нажатие «Размытие лиц» открывает экран размытия лиц', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Размытие лиц'));
      await tester.pumpAndSettle();

      expect(find.byType(FaceBlurPage), findsOneWidget);
      expect(find.text('Размытие лиц'), findsWidgets);
    });

    testWidgets('нажатие «Удалить фон» открывает экран удаления фона', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Удалить фон'));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveBackgroundPage), findsOneWidget);
    });

    testWidgets('нажатие «Водяной знак» открывает экран водяного знака', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Водяной знак'));
      await tester.pumpAndSettle();

      expect(find.byType(WatermarkPage), findsOneWidget);
    });

    testWidgets('нажатие «Размытие» открывает экран размытия', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Размытие'));
      await tester.pumpAndSettle();

      expect(find.byType(BlurPage), findsOneWidget);
    });

    testWidgets('нажатие «Улучшить качество» открывает экран резкости', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Улучшить качество'));
      await tester.pumpAndSettle();

      expect(find.byType(SharpenPage), findsOneWidget);
    });

    testWidgets('нажатие «Увеличить» открывает экран увеличения', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Увеличить'));
      await tester.pumpAndSettle();

      expect(find.byType(UpscalePage), findsOneWidget);
    });

    testWidgets('нажатие «Обрезать» открывает экран обрезки', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Обрезать'));
      await tester.pumpAndSettle();

      expect(find.byType(CropPage), findsOneWidget);
    });

    testWidgets('нажатие «Фильтры» открывает экран фильтров', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();

      expect(find.byType(FiltersPage), findsOneWidget);
    });

    testWidgets('нажатие «Редактор» открывает экран редактора', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Редактор'));
      await tester.pumpAndSettle();

      expect(find.byType(EditorPage), findsOneWidget);
    });

    testWidgets('нажатие «Рисовать» открывает экран рисования на фото', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Рисовать'));
      await tester.pumpAndSettle();

      expect(find.byType(DrawOnPhotoPage), findsOneWidget);
    });

    testWidgets('контент на главной не накладывается: заголовок и кнопки не пересекаются', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );
      await tester.pumpAndSettle();

      const labels = [
        'Загружено: 1 файл',
        'Что сделать с фото?',
        'Сжать',
        'Конвертировать',
        'Размер',
        'Повернуть',
        'Отразить',
        'Обрезать',
        'Фильтры',
        'Редактор',
        'Увеличить',
        'Улучшить качество',
        'Размытие',
        'Размытие лиц',
        'Водяной знак',
        'Удалить фон',
        'Рисовать',
        'Загрузить другие',
      ];
      final rects = <String, Rect>{};
      for (final label in labels) {
        final f = find.text(label);
        expect(f, findsOneWidget);
        rects[label] = tester.getRect(f);
      }
      final entries = rects.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          final a = entries[i].value;
          final b = entries[j].value;
          expect(
            a.overlaps(b),
            isFalse,
            reason: '«${entries[i].key}» и «${entries[j].key}» не должны пересекаться',
          );
        }
      }
    });

    testWidgets('контент на главной не накладывается: заголовок приложения и блок с кнопками не пересекаются', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );
      await tester.pumpAndSettle();

      final titleRect = tester.getRect(find.text('Image Compressor'));
      final subtitleRect = tester.getRect(find.text('Загрузите фото и выберите действие'));
      expect(titleRect.overlaps(subtitleRect), isFalse);

      final uploadedRect = tester.getRect(find.text('Загружено: 1 файл'));
      expect(titleRect.overlaps(uploadedRect), isFalse);
      expect(subtitleRect.overlaps(uploadedRect), isFalse);
    });
  });
}
