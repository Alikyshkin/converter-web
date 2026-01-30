import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:image_compressor/face_region.dart';

/// Детекция лиц в браузере через Shape Detection API (FaceDetector).
Future<List<FaceRegion>> detectFaces(Uint8List imageBytes) async {
  final blob = html.Blob([imageBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final imageElement = html.ImageElement()..src = url;
  try {
    await imageElement.onLoad.first;
    final p = (html.window as JSObject).callMethod(
      '__detectFaces'.toJS,
      imageElement as JSAny,
    );
    final result = await (p as JSPromise).toDart;
    if (result == null) return [];
    final arr = result as JSObject;
    final length =
        ((arr.getProperty('length'.toJS)) as JSNumber?)?.toDartInt ?? 0;
    final regions = <FaceRegion>[];
    for (var i = 0; i < length; i++) {
      final item = arr.getProperty(i.toJS) as JSObject?;
      if (item == null) continue;
      final x = ((item.getProperty('x'.toJS)) as JSNumber?)?.toDartInt ?? 0;
      final y = ((item.getProperty('y'.toJS)) as JSNumber?)?.toDartInt ?? 0;
      final width =
          ((item.getProperty('width'.toJS)) as JSNumber?)?.toDartInt ?? 0;
      final height =
          ((item.getProperty('height'.toJS)) as JSNumber?)?.toDartInt ?? 0;
      regions.add((x: x, y: y, width: width, height: height));
    }
    return regions;
  } catch (_) {
    return [];
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
