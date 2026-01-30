import 'dart:typed_data';

import 'package:image_compressor/face_region.dart';
import 'package:image_compressor/face_detector_web.dart'
    if (dart.library.io) 'package:image_compressor/face_detector_stub.dart'
    as impl;

/// Детекция лиц. В веб-версии использует браузерный Face Detector API (Chrome и др.).
/// Вне веба возвращает пустой список.
Future<List<FaceRegion>> detectFaces(Uint8List imageBytes) =>
    impl.detectFaces(imageBytes);
