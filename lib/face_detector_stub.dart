import 'dart:typed_data';

import 'package:image_compressor/face_region.dart';

/// Заглушка: детекция лиц поддерживается только в веб-версии (браузерный Face Detector API).
Future<List<FaceRegion>> detectFaces(Uint8List imageBytes) async {
  return [];
}
