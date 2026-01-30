import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_compressor/action_pages.dart';

void main() {
  void expectNoOverlap(WidgetTester tester, List<String> textLabels) {
    final rects = <String, Rect>{};
    for (final label in textLabels) {
      final f = find.text(label);
      if (f.evaluate().isEmpty) return;
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
  }
  group('DrawOnPhotoPage', () {
    testWidgets('при пустых аргументах после загрузки показывает «Нет файлов.»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: DrawOnPhotoPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Нет файлов.'), findsOneWidget);
    });
  });

  group('FaceBlurPage', () {
    testWidgets('при пустых аргументах после загрузки показывает «Нет файлов.»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FaceBlurPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Нет файлов.'), findsOneWidget);
      expect(find.text('Размытие лиц'), findsWidgets);
    });

    testWidgets('показывает заголовок «Размытие лиц»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FaceBlurPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Размытие лиц'), findsWidgets);
    });

    testWidgets('контент не накладывается: заголовок и текст «Нет файлов.» не пересекаются', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FaceBlurPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectNoOverlap(tester, ['Размытие лиц', 'Нет файлов.']);
    });
  });

  group('CompressPage', () {
    testWidgets('при пустых аргументах показывает «Нет файлов для обработки.»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: CompressPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Нет файлов для обработки.'), findsOneWidget);
    });

    testWidgets('контент не накладывается: заголовок и сообщение об ошибке не пересекаются', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: CompressPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectNoOverlap(tester, ['Сжать', 'Нет файлов для обработки.']);
    });
  });

  group('ConvertPage', () {
    testWidgets('при пустых аргументах показывает «Нет файлов.»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: ConvertPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Нет файлов.'), findsOneWidget);
    });
  });

  group('RemoveBackgroundPage', () {
    testWidgets('при пустых аргументах показывает «Нет файлов.»', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: RemoveBackgroundPage(
            args: const ActionPageArgs(dropped: null, picked: [], dropzoneController: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Нет файлов.'), findsOneWidget);
    });
  });

  group('RemoveWatermarkPage', () {
    testWidgets('показывает сообщение о неподдержке автоудаления', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const RemoveWatermarkPage(),
        ),
      );

      expect(find.text('Убрать водяной знак'), findsOneWidget);
      expect(
        find.text('Автоматическое удаление водяного знака с фото не поддерживается.'),
        findsOneWidget,
      );
    });

    testWidgets('контент не накладывается: заголовок и основной текст не пересекаются', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const RemoveWatermarkPage(),
        ),
      );

      expectNoOverlap(tester, [
        'Убрать водяной знак',
        'Автоматическое удаление водяного знака с фото не поддерживается.',
      ]);
    });
  });
}
