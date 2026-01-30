import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_compressor/main.dart';

void main() {
  group('ImageCompressorApp', () {
    testWidgets('приложение запускается и показывает заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(const ImageCompressorApp());

      expect(find.text('Image Compressor'), findsOneWidget);
    });

    testWidgets('приложение показывает подзаголовок про загрузку фото', (WidgetTester tester) async {
      await tester.pumpWidget(const ImageCompressorApp());

      expect(find.text('Загрузите фото и выберите действие'), findsOneWidget);
    });

    testWidgets('приложение не показывает debug banner', (WidgetTester tester) async {
      await tester.pumpWidget(const ImageCompressorApp());

      expect(find.byType(MaterialApp), findsOneWidget);
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });
  });
}
