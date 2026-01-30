import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Декодирование и кодирование изображений (сжатие, конвертация, размер, поворот, отражение).
class ImageService {
  ImageService._();

  /// Декодирует байты в изображение. Поддерживает JPEG, PNG, WebP, GIF, BMP.
  static img.Image? decode(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// Сжимает изображение: перекодирует в JPEG с заданным качеством (1–100).
  /// Возвращает null при ошибке.
  static Uint8List? compress(Uint8List bytes, {int quality = 85}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    return img.encodeJpg(decoded, quality: quality.clamp(1, 100));
  }

  /// Конвертирует в выбранный формат. [format] — расширение: 'jpg', 'png', 'webp', 'gif', 'bmp'.
  static Uint8List? convert(Uint8List bytes, String format) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    switch (format.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return img.encodeJpg(decoded, quality: 90);
      case 'png':
        return img.encodePng(decoded);
      case 'bmp':
        return img.encodeBmp(decoded);
      case 'gif':
        return img.encodeGif(decoded);
      default:
        return img.encodePng(decoded);
    }
  }

  /// Меняет размер. Сохраняет пропорции, если задана только [width] или только [height].
  static Uint8List? resize(
    Uint8List bytes, {
    int? width,
    int? height,
    bool maintainAspect = true,
  }) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    if (width == null && height == null) return bytes;
    final resized = img.copyResize(
      decoded,
      width: width,
      height: height,
      maintainAspect: maintainAspect,
      interpolation: img.Interpolation.linear,
    );
    return _encodeSameFormat(decoded, resized, bytes);
  }

  /// Поворачивает на [angle] градусов (90, 180, 270).
  static Uint8List? rotate(Uint8List bytes, int angle) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final rotated = img.copyRotate(decoded, angle: angle.toDouble(), interpolation: img.Interpolation.linear);
    return _encodeSameFormat(decoded, rotated, bytes);
  }

  /// Отражает по горизонтали и/или вертикали.
  static Uint8List? flip(Uint8List bytes, {bool horizontal = false, bool vertical = false}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    img.Image result = decoded;
    if (horizontal) result = img.copyFlip(result, direction: img.FlipDirection.horizontal);
    if (vertical) result = img.copyFlip(result, direction: img.FlipDirection.vertical);
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Обрезка по центру: [widthPercent] и [heightPercent] 1–100 (доля от размера).
  static Uint8List? crop(
    Uint8List bytes, {
    int widthPercent = 100,
    int heightPercent = 100,
  }) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final w = decoded.width;
    final h = decoded.height;
    final cw = (w * (widthPercent.clamp(1, 100) / 100)).round();
    final ch = (h * (heightPercent.clamp(1, 100) / 100)).round();
    final x = ((w - cw) / 2).round().clamp(0, w - 1);
    final y = ((h - ch) / 2).round().clamp(0, h - 1);
    final cropped = img.copyCrop(decoded, x: x, y: y, width: cw.clamp(1, w), height: ch.clamp(1, h));
    return _encodeSameFormat(decoded, cropped, bytes);
  }

  /// Обрезка по прямоугольнику в пикселях: [x], [y] — левый верхний угол, [width], [height] — размер.
  static Uint8List? cropRect(
    Uint8List bytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final w = decoded.width;
    final h = decoded.height;
    final x1 = x.clamp(0, w - 1);
    final y1 = y.clamp(0, h - 1);
    final cw = width.clamp(1, w - x1);
    final ch = height.clamp(1, h - y1);
    final cropped = img.copyCrop(decoded, x: x1, y: y1, width: cw, height: ch);
    return _encodeSameFormat(decoded, cropped, bytes);
  }

  /// Яркость и контраст: [brightness] и [contrast] 1.0 = без изменений.
  static Uint8List? brightnessContrast(
    Uint8List bytes, {
    double brightness = 1.0,
    double contrast = 1.0,
  }) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final result = img.adjustColor(decoded, brightness: brightness, contrast: contrast);
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Чёрно-белое: [amount] 0–1 (сила эффекта).
  static Uint8List? grayscale(Uint8List bytes, {double amount = 1.0}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final result = img.grayscale(decoded, amount: amount.clamp(0.0, 1.0));
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Сепия: [amount] 0–1 (сила эффекта).
  static Uint8List? sepia(Uint8List bytes, {double amount = 1.0}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final result = img.sepia(decoded, amount: amount.clamp(0.0, 1.0));
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Размытие по Гауссу: [radius] 0–20 (радиус в пикселях).
  static Uint8List? blur(Uint8List bytes, {int radius = 3}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final r = radius.clamp(0, 20);
    if (r == 0) return bytes;
    final result = img.gaussianBlur(decoded, radius: r);
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Размытие заданных областей (например, лица). [regions] — список прямоугольников {x, y, width, height}.
  /// [radius] — радиус размытия по Гауссу (0–25).
  static Uint8List? blurRegions(
    Uint8List bytes, {
    required List<({int x, int y, int width, int height})> regions,
    int radius = 15,
  }) {
    if (regions.isEmpty) return bytes;
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final r = radius.clamp(0, 25);
    final result = decoded.clone();
    final w = result.width;
    final h = result.height;
    for (final region in regions) {
      final x = region.x.clamp(0, w - 1);
      final y = region.y.clamp(0, h - 1);
      final rw = region.width.clamp(1, w - x);
      final rh = region.height.clamp(1, h - y);
      final crop = img.copyCrop(result, x: x, y: y, width: rw, height: rh);
      final blurred = r > 0 ? img.gaussianBlur(crop, radius: r) : crop;
      img.compositeImage(result, blurred, dstX: x, dstY: y, dstW: rw, dstH: rh);
    }
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Насыщенность: [saturation] 1.0 = без изменений, 0 = ч/б.
  static Uint8List? saturation(Uint8List bytes, {double saturation = 1.0}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final result = img.adjustColor(decoded, saturation: saturation);
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Резкость (улучшение качества, частично компенсирует размытие). [amount] 0–2 (сила эффекта).
  static Uint8List? sharpen(Uint8List bytes, {double amount = 1.0}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    const sharpenKernel = [0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0];
    final result = img.convolution(decoded, filter: sharpenKernel, amount: amount.clamp(0.0, 2.0));
    return _encodeSameFormat(decoded, result, bytes);
  }

  /// Увеличение: масштаб [percent] 100–200% от текущего размера.
  static Uint8List? upscale(Uint8List bytes, {int percent = 150}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final p = percent.clamp(100, 200);
    if (p == 100) return bytes;
    final nw = (decoded.width * p / 100).round().clamp(1, 8000);
    final nh = (decoded.height * p / 100).round().clamp(1, 8000);
    final resized = img.copyResize(decoded, width: nw, height: nh, interpolation: img.Interpolation.linear);
    return _encodeSameFormat(decoded, resized, bytes);
  }

  /// Водяной знак: текст [text], [position] — угол (top-left, top-right, bottom-left, bottom-right), [opacity] 0–1.
  static Uint8List? watermarkText(
    Uint8List bytes, {
    required String text,
    String position = 'bottom-right',
    double opacity = 0.5,
  }) {
    if (text.trim().isEmpty) return bytes;
    final decoded = decode(bytes);
    if (decoded == null) return null;
    final alpha = (255 * opacity.clamp(0.0, 1.0)).round().clamp(0, 255);
    const padding = 16;
    final font = img.arial24;
    const fontHeight = 28;
    final w = decoded.width;
    final h = decoded.height;
    final pos = position.toLowerCase();
    final rightJustify = pos == 'top-right' || pos == 'bottom-right' || (pos != 'top-left' && pos != 'bottom-left');
    final x = rightJustify ? w - padding : padding;
    final y = (pos == 'bottom-left' || pos == 'bottom-right') ? h - fontHeight - padding : padding;
    img.drawString(
      decoded,
      text,
      font: font,
      x: x,
      y: y,
      rightJustify: rightJustify,
      color: img.ColorRgba8(255, 255, 255, alpha),
    );
    return _encodeSameFormat(decoded, decoded, bytes);
  }

  /// Удаление фона по цвету: считаем фоном средний цвет углов, делаем прозрачными пиксели,
  /// похожие на фон. [tolerance] 0–1: чем больше, тем агрессивнее удаление (0.15–0.4 разумно).
  /// Результат всегда PNG с прозрачностью.
  static Uint8List? removeBackground(Uint8List bytes, {double tolerance = 0.25}) {
    final decoded = decode(bytes);
    if (decoded == null) return null;
    img.Image work = decoded;
    if (!work.hasAlpha) {
      work = work.convert(numChannels: 4, alpha: work.maxChannelValue.toDouble());
    }
    final w = work.width;
    final h = work.height;
    if (w < 2 || h < 2) return img.encodePng(work);
    final p00 = work.getPixel(0, 0);
    final p10 = work.getPixel(w - 1, 0);
    final p01 = work.getPixel(0, h - 1);
    final p11 = work.getPixel(w - 1, h - 1);
    final bgR = (p00.r + p10.r + p01.r + p11.r) / 4.0;
    final bgG = (p00.g + p10.g + p01.g + p11.g) / 4.0;
    final bgB = (p00.b + p10.b + p01.b + p11.b) / 4.0;
    final tol = tolerance.clamp(0.05, 0.8);
    for (final p in work) {
      final dr = (p.r - bgR).abs() / 255.0;
      final dg = (p.g - bgG).abs() / 255.0;
      final db = (p.b - bgB).abs() / 255.0;
      final dist = (dr + dg + db) / 3.0;
      if (dist <= tol) {
        work.setPixelRgba(p.x, p.y, p.r, p.g, p.b, 0);
      }
    }
    return img.encodePng(work);
  }

  /// Кодирует обратно в тот же формат, что и исходные байты (по сигнатуре).
  static Uint8List _encodeSameFormat(img.Image original, img.Image result, Uint8List originalBytes) {
    if (_isJpeg(originalBytes)) return img.encodeJpg(result, quality: 90);
    if (_isPng(originalBytes)) return img.encodePng(result);
    if (_isGif(originalBytes)) return img.encodeGif(result);
    if (_isBmp(originalBytes)) return img.encodeBmp(result);
    if (_isWebP(originalBytes)) return img.encodePng(result); // WebP write not in image package, use PNG
    return img.encodePng(result);
  }

  static bool _isJpeg(List<int> b) => b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8;
  static bool _isPng(List<int> b) =>
      b.length >= 8 &&
      b[0] == 137 &&
      b[1] == 80 &&
      b[2] == 78 &&
      b[3] == 71 &&
      b[4] == 13 &&
      b[5] == 10 &&
      b[6] == 26 &&
      b[7] == 10;
  static bool _isGif(List<int> b) =>
      b.length >= 6 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46; // GIF87a / GIF89a
  static bool _isBmp(List<int> b) => b.length >= 2 && b[0] == 0x42 && b[1] == 0x4D;
  static bool _isWebP(List<int> b) =>
      b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50;
}
