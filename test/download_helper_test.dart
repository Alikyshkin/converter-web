import 'dart:typed_data';

import 'package:image_compressor/download_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('downloadBytes (stub вне веба)', () {
    test('выбрасывает UnsupportedError', () {
      expect(
        () => downloadBytes(Uint8List(0), 'test.png'),
        throwsA(isA<UnsupportedError>().having(
          (e) => e.message,
          'message',
          'Скачивание доступно только в веб-версии.',
        )),
      );
    });
  });
}
