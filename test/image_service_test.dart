import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_compressor/image_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Uint8List validPngBytes;

  setUpAll(() {
    final image = img.Image(width: 50, height: 50);
    for (var y = 0; y < 50; y++) {
      for (var x = 0; x < 50; x++) {
        image.setPixelRgba(x, y, 100, 150, 200, 255);
      }
    }
    validPngBytes = Uint8List.fromList(img.encodePng(image));
  });

  group('ImageService', () {
    group('decode', () {
      test('валидный PNG возвращает не null', () {
        expect(ImageService.decode(validPngBytes), isNotNull);
      });
      test('пустой список возвращает null', () {
        expect(ImageService.decode(Uint8List(0)), isNull);
      });
      test('мусорные байты возвращают null', () {
        expect(ImageService.decode(Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
      });
    });

    group('blurRegions', () {
      test('пустой список областей возвращает те же байты', () {
        final result = ImageService.blurRegions(validPngBytes, regions: []);
        expect(result, same(validPngBytes));
      });
      test('одна область возвращает не null и валидное изображение', () {
        final result = ImageService.blurRegions(
          validPngBytes,
          regions: [(x: 5, y: 5, width: 20, height: 20)],
          radius: 5,
        );
        expect(result, isNotNull);
        final decoded = ImageService.decode(result!);
        expect(decoded, isNotNull);
        expect(decoded!.width, 50);
        expect(decoded.height, 50);
      });
      test('несколько областей применяют размытие', () {
        final result = ImageService.blurRegions(
          validPngBytes,
          regions: [
            (x: 0, y: 0, width: 10, height: 10),
            (x: 30, y: 30, width: 15, height: 15),
          ],
          radius: 3,
        );
        expect(result, isNotNull);
        expect(result!.length, greaterThan(0));
        expect(ImageService.decode(result), isNotNull);
      });
      test('radius 0 всё равно композитирует области', () {
        final result = ImageService.blurRegions(
          validPngBytes,
          regions: [(x: 10, y: 10, width: 10, height: 10)],
          radius: 0,
        );
        expect(result, isNotNull);
        expect(ImageService.decode(result!), isNotNull);
      });
      test('область за границами изображения клампится', () {
        final result = ImageService.blurRegions(
          validPngBytes,
          regions: [(x: 40, y: 40, width: 30, height: 30)],
          radius: 2,
        );
        expect(result, isNotNull);
        expect(ImageService.decode(result!), isNotNull);
      });
      test('невалидные байты возвращают null', () {
        final result = ImageService.blurRegions(
          Uint8List.fromList([1, 2, 3]),
          regions: [(x: 0, y: 0, width: 1, height: 1)],
        );
        expect(result, isNull);
      });
    });

    group('blur', () {
      test('radius 0 возвращает те же байты', () {
        final result = ImageService.blur(validPngBytes, radius: 0);
        expect(result, same(validPngBytes));
      });
      test('radius > 0 возвращает размытое изображение', () {
        final result = ImageService.blur(validPngBytes, radius: 2);
        expect(result, isNotNull);
        expect(result, isNot(same(validPngBytes)));
        expect(ImageService.decode(result!), isNotNull);
      });
    });

    group('compress', () {
      test('возвращает JPEG байты', () {
        final result = ImageService.compress(validPngBytes, quality: 80);
        expect(result, isNotNull);
        expect(result!.length >= 2, isTrue);
        expect(result[0], 0xFF);
        expect(result[1], 0xD8);
      });
    });

    group('resize', () {
      test('width и height null возвращают те же байты', () {
        final result = ImageService.resize(validPngBytes);
        expect(result, same(validPngBytes));
      });
      test('указанная ширина меняет размер', () {
        final result = ImageService.resize(validPngBytes, width: 25);
        expect(result, isNotNull);
        final decoded = ImageService.decode(result!);
        expect(decoded!.width, 25);
      });
    });

    group('rotate', () {
      test('90 градусов возвращает не null', () {
        final result = ImageService.rotate(validPngBytes, 90);
        expect(result, isNotNull);
        final decoded = ImageService.decode(result!);
        expect(decoded!.width, 50);
        expect(decoded.height, 50);
      });
    });

    group('flip', () {
      test('horizontal возвращает не null', () {
        final result = ImageService.flip(validPngBytes, horizontal: true);
        expect(result, isNotNull);
        expect(ImageService.decode(result!), isNotNull);
      });
    });

    group('convert', () {
      test('png возвращает PNG', () {
        final result = ImageService.convert(validPngBytes, 'png');
        expect(result, isNotNull);
        expect(result!.length >= 8, isTrue);
        expect(result.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      });
      test('jpg возвращает JPEG', () {
        final result = ImageService.convert(validPngBytes, 'jpg');
        expect(result, isNotNull);
        expect(result![0], 0xFF);
        expect(result[1], 0xD8);
      });
    });
  });
}
