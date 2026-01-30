import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_compressor/file_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loadFileBytes', () {
    test('без аргументов возвращает пустой список', () async {
      final result = await loadFileBytes();
      expect(result, isEmpty);
    });

    test('picked: [] возвращает пустой список', () async {
      final result = await loadFileBytes(picked: []);
      expect(result, isEmpty);
    });

    test('picked: null возвращает пустой список', () async {
      final result = await loadFileBytes(picked: null);
      expect(result, isEmpty);
    });

    test('dropped: [] без controller возвращает пустой список', () async {
      final result = await loadFileBytes(dropped: [], dropzoneController: null);
      expect(result, isEmpty);
    });

    test('picked с файлом с bytes возвращает один LoadedFile', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await loadFileBytes(
        picked: [PlatformFile(name: 'test.png', size: 3, bytes: bytes)],
      );
      expect(result.length, 1);
      expect(result[0].name, 'test.png');
      expect(result[0].bytes, same(bytes));
    });

    test('picked с файлом без bytes не добавляет в список', () async {
      final result = await loadFileBytes(
        picked: [PlatformFile(name: 'test.png', size: 0, bytes: null)],
      );
      expect(result, isEmpty);
    });
  });
}
