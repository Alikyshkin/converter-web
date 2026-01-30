import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('при initialUploadedCountForTesting: 3 показывает «Загружено: 3 файлов»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 3),
        ),
      );

      expect(find.text('Загружено: 3 файлов'), findsOneWidget);
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
      expect(find.text('Загрузить другие'), findsOneWidget);
    });

    testWidgets('нажатие «Сжать» показывает SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Сжать'));
      await tester.pump();

      expect(find.text('Сжатие 1 файла — в разработке'), findsOneWidget);
    });

    testWidgets('нажатие «Сжать» при нескольких файлах показывает SnackBar с числом', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 5),
        ),
      );

      await tester.tap(find.text('Сжать'));
      await tester.pump();

      expect(find.text('Сжатие 5 файлов — в разработке'), findsOneWidget);
    });

    testWidgets('нажатие «Конвертировать» показывает SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Конвертировать'));
      await tester.pump();

      expect(find.text('Конвертация 1 файла — в разработке'), findsOneWidget);
    });

    testWidgets('нажатие «Размер» показывает SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Размер'));
      await tester.pump();

      expect(find.text('Изменение размера — в разработке'), findsOneWidget);
    });

    testWidgets('нажатие «Повернуть» показывает SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Повернуть'));
      await tester.pump();

      expect(find.text('Поворот — в разработке'), findsOneWidget);
    });

    testWidgets('нажатие «Отразить» показывает SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 1),
        ),
      );

      await tester.tap(find.text('Отразить'));
      await tester.pump();

      expect(find.text('Отразить — в разработке'), findsOneWidget);
    });

    testWidgets('«Загрузить другие» возвращает к зоне загрузки', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(initialUploadedCountForTesting: 2),
        ),
      );

      expect(find.text('Загружено: 2 файлов'), findsOneWidget);

      await tester.tap(find.text('Загрузить другие'));
      await tester.pump();

      expect(find.text('Загружено: 2 файлов'), findsNothing);
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
  });
}
