import 'dart:typed_data';

import 'package:image_compressor/face_detector.dart';
import 'package:image_compressor/face_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectFaces', () {
    test('возвращает Future<List<FaceRegion>>', () {
      final future = detectFaces(Uint8List(0));
      expect(future, isA<Future<List<FaceRegion>>>());
    });

    test('завершается списком (stub возвращает пустой список вне веба)', () async {
      final result = await detectFaces(Uint8List.fromList([1, 2, 3]));
      expect(result, isA<List<FaceRegion>>());
      expect(result, isEmpty);
    });

    test('для любых байтов stub возвращает пустой список', () async {
      final bytes = Uint8List(100);
      final result = await detectFaces(bytes);
      expect(result, isEmpty);
    });
  });
}
