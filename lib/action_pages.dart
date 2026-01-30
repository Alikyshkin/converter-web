import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:image_compressor/app_theme.dart';
import 'package:image_compressor/download_helper.dart';
import 'package:image_compressor/file_loader.dart';
import 'package:image_compressor/face_detector.dart';
import 'package:image_compressor/image_service.dart';

/// Базовые данные для экранов действий: загруженные файлы и контроллер dropzone.
class ActionPageArgs {
  const ActionPageArgs({
    this.dropped,
    this.picked,
    this.dropzoneController,
  });
  final List<DropzoneFileInterface>? dropped;
  final List<PlatformFile>? picked;
  final DropzoneViewController? dropzoneController;
}

String _baseName(String path) {
  final i = path.lastIndexOf('.');
  return i > 0 ? path.substring(0, i) : path;
}

String _extension(String path) {
  final i = path.lastIndexOf('.');
  return i > 0 ? path.substring(i + 1).toLowerCase() : '';
}

Future<List<LoadedFile>> loadFilesFromArgs(ActionPageArgs args) {
  return loadFileBytes(
    dropped: args.dropped,
    picked: args.picked,
    dropzoneController: args.dropzoneController,
  );
}

void downloadAllAndNotify(BuildContext context, List<LoadedFile> results) {
  for (final f in results) {
    downloadBytes(f.bytes, f.name);
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Скачано: ${AppTheme.fileCount(results.length)}')),
  );
}

Widget buildResultsScaffold(
  BuildContext context, {
  required String titleDone,
  required List<LoadedFile> results,
  required VoidCallback onDownloadAll,
  Widget? topContent,
}) {
  return Scaffold(
    appBar: AppBar(title: Text(titleDone)),
    body: ListView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      children: [
        if (topContent != null) ...[
          topContent,
          const SizedBox(height: AppTheme.blockGap),
        ],
        ElevatedButton(
          onPressed: onDownloadAll,
          child: const Text('Скачать все'),
        ),
        const SizedBox(height: AppTheme.sectionGap),
        ...results.map(
          (f) => ListTile(
            title: Text(f.name),
            trailing: TextButton(
              onPressed: () => downloadBytes(f.bytes, f.name),
              child: const Text('Скачать'),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Двухколоночный макет: превью слева, действия справа. Превью обновляется при каждом setState.
Widget buildActionLayout(
  BuildContext context, {
  required String title,
  required Widget previewPanel,
  required Widget controlsPanel,
}) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(AppTheme.pagePadding),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: previewPanel,
          ),
        ),
        const SizedBox(width: AppTheme.sectionGap),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: controlsPanel,
          ),
        ),
      ],
    ),
  );
}

Widget buildPreviewImage(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) {
    return const Center(
      child: Text('Превью недоступно', style: TextStyle(color: AppTheme.textSecondary)),
    );
  }
  return Center(child: Image.memory(bytes, fit: BoxFit.contain));
}

/// Экран сжатия: качество JPEG 1–100, затем «Применить» и скачивание.
class CompressPage extends StatefulWidget {
  const CompressPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<CompressPage> createState() => _CompressPageState();
}

class _CompressPageState extends State<CompressPage> {
  List<LoadedFile>? _files;
  String? _error;
  int _quality = 85;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) {
        _error = 'Нет файлов для обработки.';
      } else {
        _files = list;
      }
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.compress(f.bytes, quality: _quality);
      if (out != null) {
        final name = '${_baseName(f.name)}_compressed.jpg';
        results.add((name: name, bytes: out));
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сжать')),
        body: Center(child: Text(_error!)),
      );
    }
    if (_files == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сжать')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Сжать — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
        topContent: Text(
          'Обработано: ${AppTheme.fileCount(_results!.length)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    final previewBytes = ImageService.compress(_files!.first.bytes, quality: _quality) ?? _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Сжать',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Качество JPEG (1–100). Меньше — сильнее сжатие.', style: Theme.of(context).textTheme.bodyMedium),
          Slider(value: _quality.toDouble(), min: 1, max: 100, divisions: 99, label: '$_quality', onChanged: (v) => setState(() => _quality = v.round())),
          Text('$_quality%', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(
            onPressed: _processing ? null : _apply,
            child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить'),
          ),
        ],
      ),
    );
  }
}

/// Экран конвертации: выбор формата (JPEG, PNG, BMP, GIF), затем «Применить» и скачивание.
class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  List<LoadedFile>? _files;
  String? _error;
  String _format = 'png';
  List<LoadedFile>? _results;
  bool _processing = false;

  static const _formats = ['jpg', 'png', 'bmp', 'gif'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.convert(f.bytes, _format);
      if (out != null) {
        final name = '${_baseName(f.name)}.$_format';
        results.add((name: name, bytes: out));
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Конвертировать')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Конвертировать')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Конвертировать — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final previewBytes = ImageService.convert(_files!.first.bytes, _format) ?? _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Конвертировать',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Формат результата:'),
          DropdownButton<String>(
            value: _format,
            items: _formats.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _format = v ?? 'png'),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Экран изменения размера: ширина/высота или процент, затем «Применить» и скачивание.
class ResizePage extends StatefulWidget {
  const ResizePage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<ResizePage> createState() => _ResizePageState();
}

class _ResizePageState extends State<ResizePage> {
  List<LoadedFile>? _files;
  String? _error;
  final _widthCtrl = TextEditingController(text: '800');
  final _heightCtrl = TextEditingController();
  bool _percentMode = false;
  final _percentCtrl = TextEditingController(text: '50');
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    int? w;
    int? h;
    if (_percentMode) {
      final p = int.tryParse(_percentCtrl.text) ?? 50;
      if (p <= 0 || p > 100) {
        setState(() => _processing = false);
        return;
      }
      for (final f in _files!) {
        final img = ImageService.decode(f.bytes);
        if (img != null) {
          final nw = (img.width * p / 100).round().clamp(1, 10000);
          final nh = (img.height * p / 100).round().clamp(1, 10000);
          final out = ImageService.resize(f.bytes, width: nw, height: nh);
          if (out != null) results.add((name: '${_baseName(f.name)}_${nw}x$nh.${_extension(f.name)}', bytes: out));
        }
      }
    } else {
      w = int.tryParse(_widthCtrl.text);
      h = int.tryParse(_heightCtrl.text);
      if (w == null && h == null) {
        setState(() => _processing = false);
        return;
      }
      for (final f in _files!) {
        final out = ImageService.resize(f.bytes, width: w, height: h, maintainAspect: true);
        if (out != null) results.add((name: '${_baseName(f.name)}_resized.${_extension(f.name)}', bytes: out));
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Размер')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Размер')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Размер — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    Uint8List? previewBytes;
    if (_percentMode) {
      final p = int.tryParse(_percentCtrl.text) ?? 50;
      if (p > 0 && p <= 100) {
        final img = ImageService.decode(_files!.first.bytes);
        if (img != null) {
          final nw = (img.width * p / 100).round().clamp(1, 10000);
          final nh = (img.height * p / 100).round().clamp(1, 10000);
          previewBytes = ImageService.resize(_files!.first.bytes, width: nw, height: nh);
        }
      }
    } else {
      final w = int.tryParse(_widthCtrl.text);
      final h = int.tryParse(_heightCtrl.text);
      if (w != null || h != null) {
        previewBytes = ImageService.resize(_files!.first.bytes, width: w, height: h, maintainAspect: true);
      }
    }
    previewBytes ??= _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Размер',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(title: const Text('По проценту от оригинала'), value: _percentMode, onChanged: (v) => setState(() => _percentMode = v)),
          if (_percentMode) ...[
            TextField(controller: _percentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Процент (1–100)'), onChanged: (_) => setState(() {})),
          ] else ...[
            TextField(controller: _widthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ширина (пусто — по пропорции)'), onChanged: (_) => setState(() {})),
            TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Высота (пусто — по пропорции)'), onChanged: (_) => setState(() {})),
          ],
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Экран поворота: 90°, 180°, 270°, затем «Применить» и скачивание.
class RotatePage extends StatefulWidget {
  const RotatePage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<RotatePage> createState() => _RotatePageState();
}

class _RotatePageState extends State<RotatePage> {
  List<LoadedFile>? _files;
  String? _error;
  int _angle = 90;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.rotate(f.bytes, _angle);
      if (out != null) results.add((name: '${_baseName(f.name)}_rotated.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Повернуть')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Повернуть')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Повернуть — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final previewBytes = ImageService.rotate(_files!.first.bytes, _angle) ?? _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Повернуть',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Угол поворота:'),
          Wrap(
            spacing: 8,
            children: [90, 180, 270].map((a) => ChoiceChip(
              label: Text('$a°'),
              selected: _angle == a,
              onSelected: (v) => setState(() => _angle = a),
            )).toList(),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Экран отражения: по горизонтали / по вертикали, затем «Применить» и скачивание.
class FlipPage extends StatefulWidget {
  const FlipPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<FlipPage> createState() => _FlipPageState();
}

class _FlipPageState extends State<FlipPage> {
  List<LoadedFile>? _files;
  String? _error;
  bool _horizontal = true;
  bool _vertical = false;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    if (!_horizontal && !_vertical) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите направление: по горизонтали и/или по вертикали.')));
      return;
    }
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.flip(f.bytes, horizontal: _horizontal, vertical: _vertical);
      if (out != null) results.add((name: '${_baseName(f.name)}_flipped.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Отразить')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Отразить')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Отразить — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final previewBytes = (_horizontal || _vertical)
        ? (ImageService.flip(_files!.first.bytes, horizontal: _horizontal, vertical: _vertical) ?? _files!.first.bytes)
        : _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Отразить',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(title: const Text('По горизонтали'), value: _horizontal, onChanged: (v) => setState(() => _horizontal = v ?? false)),
          CheckboxListTile(title: const Text('По вертикали'), value: _vertical, onChanged: (v) => setState(() => _vertical = v ?? false)),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Режим перетаскивания при обрезке.
enum _CropDragMode { none, move, left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight }

/// Экран обрезки: пользователь тянет прямоугольник на фото, затем «Применить».
class CropPage extends StatefulWidget {
  const CropPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  List<LoadedFile>? _files;
  String? _error;
  /// Область обрезки в нормализованных координатах 0–1 (left, top, right, bottom).
  Rect _cropRect = const Rect.fromLTRB(0, 0, 1, 1);
  _CropDragMode _cropDragMode = _CropDragMode.none;
  Rect _cropDragStartRect = Rect.zero;
  Offset _cropDragStartLocal = Offset.zero;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else {
        _files = list;
        _cropRect = const Rect.fromLTRB(0, 0, 1, 1);
      }
    });
  }

  Rect _rectToPixels(Rect normRect, int imgW, int imgH) {
    return Rect.fromLTRB(
      (normRect.left * imgW).round().toDouble(),
      (normRect.top * imgH).round().toDouble(),
      (normRect.right * imgW).round().toDouble(),
      (normRect.bottom * imgH).round().toDouble(),
    );
  }

  Uint8List? _cropByRect(Uint8List bytes, Rect normRect) {
    final decoded = ImageService.decode(bytes);
    if (decoded == null) return null;
    final w = decoded.width;
    final h = decoded.height;
    final r = _rectToPixels(normRect, w, h);
    final x = r.left.round().clamp(0, w - 1);
    final y = r.top.round().clamp(0, h - 1);
    final rw = (r.width.round().clamp(1, w - x));
    final rh = (r.height.round().clamp(1, h - y));
    return ImageService.cropRect(bytes, x: x, y: y, width: rw, height: rh);
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = _cropByRect(f.bytes, _cropRect);
      if (out != null) results.add((name: '${_baseName(f.name)}_cropped.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  void _resetCrop() {
    setState(() => _cropRect = const Rect.fromLTRB(0, 0, 1, 1));
  }

  /// Определяет режим перетаскивания по точке в нормализованных координатах.
  _CropDragMode _hitTest(Offset normPos) {
    final l = _cropRect.left;
    final t = _cropRect.top;
    final r = _cropRect.right;
    final b = _cropRect.bottom;
    final margin = 0.08;
    final inLeft = normPos.dx <= l + margin && normPos.dx >= l - margin;
    final inRight = normPos.dx >= r - margin && normPos.dx <= r + margin;
    final inTop = normPos.dy <= t + margin && normPos.dy >= t - margin;
    final inBottom = normPos.dy >= b - margin && normPos.dy <= b + margin;
    final inRect = normPos.dx >= l && normPos.dx <= r && normPos.dy >= t && normPos.dy <= b;
    if (inLeft && inTop) return _CropDragMode.topLeft;
    if (inRight && inTop) return _CropDragMode.topRight;
    if (inLeft && inBottom) return _CropDragMode.bottomLeft;
    if (inRight && inBottom) return _CropDragMode.bottomRight;
    if (inLeft) return _CropDragMode.left;
    if (inRight) return _CropDragMode.right;
    if (inTop) return _CropDragMode.top;
    if (inBottom) return _CropDragMode.bottom;
    if (inRect) return _CropDragMode.move;
    return _CropDragMode.none;
  }

  void _updateCropRect(Offset normDelta) {
    double newLeft = _cropRect.left;
    double newTop = _cropRect.top;
    double newRight = _cropRect.right;
    double newBottom = _cropRect.bottom;
    const minSize = 0.05;
    switch (_cropDragMode) {
      case _CropDragMode.move:
        newLeft = (_cropDragStartRect.left + normDelta.dx).clamp(0.0, 1.0 - minSize);
        newTop = (_cropDragStartRect.top + normDelta.dy).clamp(0.0, 1.0 - minSize);
        newRight = (_cropDragStartRect.right + normDelta.dx).clamp(minSize, 1.0);
        newBottom = (_cropDragStartRect.bottom + normDelta.dy).clamp(minSize, 1.0);
        if (newRight - newLeft < minSize || newBottom - newTop < minSize) return;
        break;
      case _CropDragMode.left:
        newLeft = (_cropDragStartRect.left + normDelta.dx).clamp(0.0, _cropRect.right - minSize);
        break;
      case _CropDragMode.right:
        newRight = (_cropDragStartRect.right + normDelta.dx).clamp(_cropRect.left + minSize, 1.0);
        break;
      case _CropDragMode.top:
        newTop = (_cropDragStartRect.top + normDelta.dy).clamp(0.0, _cropRect.bottom - minSize);
        break;
      case _CropDragMode.bottom:
        newBottom = (_cropDragStartRect.bottom + normDelta.dy).clamp(_cropRect.top + minSize, 1.0);
        break;
      case _CropDragMode.topLeft:
        newLeft = (_cropDragStartRect.left + normDelta.dx).clamp(0.0, _cropRect.right - minSize);
        newTop = (_cropDragStartRect.top + normDelta.dy).clamp(0.0, _cropRect.bottom - minSize);
        break;
      case _CropDragMode.topRight:
        newRight = (_cropDragStartRect.right + normDelta.dx).clamp(_cropRect.left + minSize, 1.0);
        newTop = (_cropDragStartRect.top + normDelta.dy).clamp(0.0, _cropRect.bottom - minSize);
        break;
      case _CropDragMode.bottomLeft:
        newLeft = (_cropDragStartRect.left + normDelta.dx).clamp(0.0, _cropRect.right - minSize);
        newBottom = (_cropDragStartRect.bottom + normDelta.dy).clamp(_cropRect.top + minSize, 1.0);
        break;
      case _CropDragMode.bottomRight:
        newRight = (_cropDragStartRect.right + normDelta.dx).clamp(_cropRect.left + minSize, 1.0);
        newBottom = (_cropDragStartRect.bottom + normDelta.dy).clamp(_cropRect.top + minSize, 1.0);
        break;
      case _CropDragMode.none:
        return;
    }
    setState(() => _cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Обрезать')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Обрезать')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Обрезать — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final decoded = ImageService.decode(_files!.first.bytes);
    if (decoded == null) {
      return buildActionLayout(
        context,
        title: 'Обрезать',
        previewPanel: buildPreviewImage(_files!.first.bytes),
        controlsPanel: const Text('Не удалось декодировать изображение.'),
      );
    }
    final imgW = decoded.width.toDouble();
    final imgH = decoded.height.toDouble();

    Widget previewPanel = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size.width <= 0 || size.height <= 0) return buildPreviewImage(_files!.first.bytes);
        final aspectImage = imgW / imgH;
        final aspectBox = size.width / size.height;
        double w, h;
        if (aspectBox > aspectImage) {
          h = size.height;
          w = size.height * aspectImage;
        } else {
          w = size.width;
          h = size.width / aspectImage;
        }
        final imageRect = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
        Offset localToNorm(Offset local) {
          if (w <= 0 || h <= 0) return Offset.zero;
          return Offset(
            ((local.dx - imageRect.left) / w).clamp(0.0, 1.0),
            ((local.dy - imageRect.top) / h).clamp(0.0, 1.0),
          );
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Center(
                child: Image.memory(_files!.first.bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              left: imageRect.left,
              top: imageRect.top,
              width: w,
              height: h,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  final norm = localToNorm(d.localPosition);
                  if (norm.dx < 0 || norm.dx > 1 || norm.dy < 0 || norm.dy > 1) return;
                  setState(() {
                    _cropDragMode = _hitTest(norm);
                    _cropDragStartRect = _cropRect;
                    _cropDragStartLocal = d.localPosition;
                  });
                },
                onPanUpdate: (d) {
                  if (_cropDragMode == _CropDragMode.none) return;
                  final curNorm = localToNorm(d.localPosition);
                  final startNorm = localToNorm(_cropDragStartLocal);
                  _updateCropRect(Offset(curNorm.dx - startNorm.dx, curNorm.dy - startNorm.dy));
                },
                onPanEnd: (_) {
                  setState(() => _cropDragMode = _CropDragMode.none);
                },
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _CropOverlayPainter(
                    cropRect: _cropRect,
                    borderColor: Colors.white,
                    dimColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return buildActionLayout(
      context,
      title: 'Обрезать',
      previewPanel: previewPanel,
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Тяните прямоугольник на фото: углы и границы — изменить размер, внутри — сдвинуть область.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.blockGap),
          OutlinedButton.icon(
            onPressed: _resetCrop,
            icon: const Icon(Icons.crop_free_rounded, size: 20),
            label: const Text('Сбросить область'),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.cropRect, required this.borderColor, required this.dimColor});
  final Rect cropRect;
  final Color borderColor;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final left = cropRect.left * w;
    final top = cropRect.top * h;
    final right = cropRect.right * w;
    final bottom = cropRect.bottom * h;
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
    final inner = Path()..addRect(Rect.fromLTWH(left, top, right - left, bottom - top));
    final dim = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(dim, Paint()..color = dimColor..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromLTWH(left, top, right - left, bottom - top), Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) => old.cropRect != cropRect;
}

/// Экран фильтров: яркость, контраст, ч/б, сепия, размытие — затем «Применить» и скачивание.
class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  List<LoadedFile>? _files;
  String? _error;
  double _brightness = 1.0;
  double _contrast = 1.0;
  bool _grayscale = false;
  bool _sepia = false;
  int _blurRadius = 0;
  double _saturation = 1.0;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      Uint8List? out = f.bytes;
      if (_brightness != 1.0 || _contrast != 1.0) {
        out = ImageService.brightnessContrast(out, brightness: _brightness, contrast: _contrast);
      }
      if (out != null && _saturation != 1.0) out = ImageService.saturation(out, saturation: _saturation);
      if (out != null && _grayscale) out = ImageService.grayscale(out, amount: 1.0);
      if (out != null && _sepia) out = ImageService.sepia(out, amount: 1.0);
      if (out != null && _blurRadius > 0) out = ImageService.blur(out, radius: _blurRadius);
      if (out != null) results.add((name: '${_baseName(f.name)}_filtered.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Фильтры')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Фильтры')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Фильтры — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    Uint8List? out = _files!.first.bytes;
    if (_brightness != 1.0 || _contrast != 1.0) {
      out = ImageService.brightnessContrast(out, brightness: _brightness, contrast: _contrast);
    }
    if (out != null && _saturation != 1.0) out = ImageService.saturation(out, saturation: _saturation);
    if (out != null && _grayscale) out = ImageService.grayscale(out, amount: 1.0);
    if (out != null && _sepia) out = ImageService.sepia(out, amount: 1.0);
    if (out != null && _blurRadius > 0) out = ImageService.blur(out, radius: _blurRadius);
    return buildActionLayout(
      context,
      title: 'Фильтры',
      previewPanel: buildPreviewImage(out),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Яркость (1.0 = без изменений):'),
          Slider(value: _brightness, min: 0.3, max: 2.0, onChanged: (v) => setState(() => _brightness = v)),
          Text('Яркость: ${_brightness.toStringAsFixed(1)}'),
          const Text('Контраст:'),
          Slider(value: _contrast, min: 0.3, max: 2.0, onChanged: (v) => setState(() => _contrast = v)),
          const Text('Насыщенность (0 = ч/б):'),
          Slider(value: _saturation, min: 0, max: 2.0, onChanged: (v) => setState(() => _saturation = v)),
          CheckboxListTile(title: const Text('Чёрно-белое'), value: _grayscale, onChanged: (v) => setState(() => _grayscale = v ?? false)),
          CheckboxListTile(title: const Text('Сепия'), value: _sepia, onChanged: (v) => setState(() => _sepia = v ?? false)),
          const Text('Размытие (радиус):'),
          Slider(value: _blurRadius.toDouble(), min: 0, max: 10, divisions: 10, onChanged: (v) => setState(() => _blurRadius = v.round())),
          Text('Размытие: $_blurRadius'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Редактор фото: обрезка, размер, поворот, отражение и фильтры в одном экране; настройки применяются ко всем файлам.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  List<LoadedFile>? _files;
  String? _error;
  int _previewIndex = 0;
  int _cropWidthPercent = 100;
  int _cropHeightPercent = 100;
  bool _resizeEnabled = false;
  final _resizeWidthCtrl = TextEditingController(text: '800');
  final _resizeHeightCtrl = TextEditingController();
  int _resizePercent = 100;
  bool _resizeByPercent = false;
  int _rotateAngle = 0;
  bool _flipH = false;
  bool _flipV = false;
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  bool _grayscale = false;
  bool _sepia = false;
  int _blurRadius = 0;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void dispose() {
    _resizeWidthCtrl.dispose();
    _resizeHeightCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Uint8List? _applyPipeline(Uint8List bytes) {
    Uint8List? out = bytes;
    if (_cropWidthPercent < 100 || _cropHeightPercent < 100) {
      out = ImageService.crop(out, widthPercent: _cropWidthPercent, heightPercent: _cropHeightPercent);
    }
    if (out != null && _rotateAngle != 0) out = ImageService.rotate(out, _rotateAngle);
    if (out != null && (_flipH || _flipV)) out = ImageService.flip(out, horizontal: _flipH, vertical: _flipV);
    if (out != null && _resizeEnabled) {
      if (_resizeByPercent) {
        final decoded = ImageService.decode(out);
        if (decoded != null) {
          final nw = (decoded.width * _resizePercent / 100).round().clamp(1, 10000);
          final nh = (decoded.height * _resizePercent / 100).round().clamp(1, 10000);
          out = ImageService.resize(out, width: nw, height: nh);
        }
      } else {
        final w = int.tryParse(_resizeWidthCtrl.text);
        final h = int.tryParse(_resizeHeightCtrl.text);
        out = ImageService.resize(out, width: w, height: h, maintainAspect: true);
      }
    }
    if (out != null && (_brightness != 1.0 || _contrast != 1.0)) out = ImageService.brightnessContrast(out, brightness: _brightness, contrast: _contrast);
    if (out != null && _saturation != 1.0) out = ImageService.saturation(out, saturation: _saturation);
    if (out != null && _grayscale) out = ImageService.grayscale(out, amount: 1.0);
    if (out != null && _sepia) out = ImageService.sepia(out, amount: 1.0);
    if (out != null && _blurRadius > 0) out = ImageService.blur(out, radius: _blurRadius);
    return out;
  }

  Future<void> _applyToAll() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = _applyPipeline(f.bytes);
      if (out != null) results.add((name: '${_baseName(f.name)}_edited.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Редактор')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Редактор')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Редактор — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }

    final file = _files![_previewIndex];
    final previewBytes = _applyPipeline(file.bytes);

    Widget previewPanel = buildPreviewImage(previewBytes);
    if (_files!.length > 1) {
      previewPanel = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<int>(
              value: _previewIndex,
              isExpanded: true,
              items: List.generate(_files!.length, (i) => DropdownMenuItem(value: i, child: Text('${i + 1}. ${_files![i].name}'))),
              onChanged: (v) => setState(() => _previewIndex = v ?? 0),
            ),
          ),
          Expanded(child: buildPreviewImage(previewBytes)),
        ],
      );
    }

    return buildActionLayout(
      context,
      title: 'Редактор фото',
      previewPanel: previewPanel,
      controlsPanel: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Обрезка (по центру)', style: TextStyle(fontWeight: FontWeight.w600)),
            Slider(value: _cropWidthPercent.toDouble(), min: 10, max: 100, divisions: 9, onChanged: (v) => setState(() => _cropWidthPercent = v.round())),
            Text('Ширина: $_cropWidthPercent%'),
            Slider(value: _cropHeightPercent.toDouble(), min: 10, max: 100, divisions: 9, onChanged: (v) => setState(() => _cropHeightPercent = v.round())),
            Text('Высота: $_cropHeightPercent%'),
            const Divider(),
            const Text('Размер', style: TextStyle(fontWeight: FontWeight.w600)),
            CheckboxListTile(title: const Text('Изменить размер'), value: _resizeEnabled, onChanged: (v) => setState(() => _resizeEnabled = v ?? false)),
            if (_resizeEnabled) ...[
              CheckboxListTile(title: const Text('По проценту'), value: _resizeByPercent, onChanged: (v) => setState(() => _resizeByPercent = v ?? false)),
              if (_resizeByPercent)
                Slider(value: _resizePercent.toDouble(), min: 5, max: 100, divisions: 19, onChanged: (v) => setState(() => _resizePercent = v.round()))
              else ...[
                TextField(controller: _resizeWidthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ширина'), onChanged: (_) => setState(() {})),
                TextField(controller: _resizeHeightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Высота (пусто — по пропорции)'), onChanged: (_) => setState(() {})),
              ],
            ],
            const Divider(),
            const Text('Поворот и отражение', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('90°'), selected: _rotateAngle == 90, onSelected: (v) => setState(() => _rotateAngle = v ? 90 : 0)),
                ChoiceChip(label: const Text('180°'), selected: _rotateAngle == 180, onSelected: (v) => setState(() => _rotateAngle = v ? 180 : 0)),
                ChoiceChip(label: const Text('270°'), selected: _rotateAngle == 270, onSelected: (v) => setState(() => _rotateAngle = v ? 270 : 0)),
              ],
            ),
            CheckboxListTile(title: const Text('Отразить по горизонтали'), value: _flipH, onChanged: (v) => setState(() => _flipH = v ?? false)),
            CheckboxListTile(title: const Text('Отразить по вертикали'), value: _flipV, onChanged: (v) => setState(() => _flipV = v ?? false)),
            const Divider(),
            const Text('Фильтры', style: TextStyle(fontWeight: FontWeight.w600)),
            Slider(value: _brightness, min: 0.3, max: 2.0, onChanged: (v) => setState(() => _brightness = v)),
            Text('Яркость: ${_brightness.toStringAsFixed(1)}'),
            Slider(value: _contrast, min: 0.3, max: 2.0, onChanged: (v) => setState(() => _contrast = v)),
            Text('Контраст: ${_contrast.toStringAsFixed(1)}'),
            Slider(value: _saturation, min: 0, max: 2.0, onChanged: (v) => setState(() => _saturation = v)),
            Text('Насыщенность: ${_saturation.toStringAsFixed(1)}'),
            CheckboxListTile(title: const Text('Ч/б'), value: _grayscale, onChanged: (v) => setState(() => _grayscale = v ?? false)),
            CheckboxListTile(title: const Text('Сепия'), value: _sepia, onChanged: (v) => setState(() => _sepia = v ?? false)),
            Slider(value: _blurRadius.toDouble(), min: 0, max: 8, divisions: 8, onChanged: (v) => setState(() => _blurRadius = v.round())),
            Text('Размытие: $_blurRadius'),
            const SizedBox(height: AppTheme.sectionGap),
            FilledButton(
              onPressed: _processing ? null : _applyToAll,
              child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить ко всем'),
            ),
          ],
        ),
    );
  }
}

/// Увеличение фото: масштаб 100–200%, затем «Применить» и скачивание.
class UpscalePage extends StatefulWidget {
  const UpscalePage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<UpscalePage> createState() => _UpscalePageState();
}

class _UpscalePageState extends State<UpscalePage> {
  List<LoadedFile>? _files;
  String? _error;
  int _percent = 150;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.upscale(f.bytes, percent: _percent);
      if (out != null) results.add((name: '${_baseName(f.name)}_upscaled.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Увеличить')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Увеличить')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Увеличить — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final previewBytes = _percent == 100 ? _files!.first.bytes : (ImageService.upscale(_files!.first.bytes, percent: _percent) ?? _files!.first.bytes);
    return buildActionLayout(
      context,
      title: 'Увеличить',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Масштаб (100% — без изменений, 200% — удвоение размера):'),
          Slider(value: _percent.toDouble(), min: 100, max: 200, divisions: 10, label: '$_percent%', onChanged: (v) => setState(() => _percent = v.round())),
          Text('$_percent%'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Резкость / улучшение качества / убрать размытие: сила эффекта, затем «Применить».
class SharpenPage extends StatefulWidget {
  const SharpenPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<SharpenPage> createState() => _SharpenPageState();
}

class _SharpenPageState extends State<SharpenPage> {
  List<LoadedFile>? _files;
  String? _error;
  double _amount = 1.0;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.sharpen(f.bytes, amount: _amount);
      if (out != null) results.add((name: '${_baseName(f.name)}_sharpened.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Резкость')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Резкость')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Резкость — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final previewBytes = ImageService.sharpen(_files!.first.bytes, amount: _amount) ?? _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Резкость / Улучшить качество',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Увеличивает резкость и может частично компенсировать лёгкое размытие. Сила эффекта 0–2:'),
          Slider(value: _amount, min: 0.3, max: 2.0, onChanged: (v) => setState(() => _amount = v)),
          Text('Сила: ${_amount.toStringAsFixed(1)}'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Размытие: радиус 0–10, затем «Применить».
class BlurPage extends StatefulWidget {
  const BlurPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<BlurPage> createState() => _BlurPageState();
}

class _BlurPageState extends State<BlurPage> {
  List<LoadedFile>? _files;
  String? _error;
  int _radius = 3;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.blur(f.bytes, radius: _radius);
      if (out != null) results.add((name: '${_baseName(f.name)}_blurred.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Размытие')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Размытие')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Размытие — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final previewBytes = _radius == 0 ? _files!.first.bytes : (ImageService.blur(_files!.first.bytes, radius: _radius) ?? _files!.first.bytes);
    return buildActionLayout(
      context,
      title: 'Размытие',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Радиус размытия (0 — без изменений):'),
          Slider(value: _radius.toDouble(), min: 0, max: 10, divisions: 10, onChanged: (v) => setState(() => _radius = v.round())),
          Text('Радиус: $_radius'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Водяной знак: текст, позиция, прозрачность, затем «Применить».
class WatermarkPage extends StatefulWidget {
  const WatermarkPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<WatermarkPage> createState() => _WatermarkPageState();
}

class _WatermarkPageState extends State<WatermarkPage> {
  List<LoadedFile>? _files;
  String? _error;
  final _textCtrl = TextEditingController(text: '© Водяной знак');
  String _position = 'bottom-right';
  double _opacity = 0.5;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите текст водяного знака.')));
      return;
    }
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.watermarkText(f.bytes, text: text, position: _position, opacity: _opacity);
      if (out != null) results.add((name: '${_baseName(f.name)}_watermark.${_extension(f.name)}', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Водяной знак')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Водяной знак')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Водяной знак — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    final text = _textCtrl.text.trim();
    final previewBytes = text.isEmpty
        ? _files!.first.bytes
        : (ImageService.watermarkText(_files!.first.bytes, text: text, position: _position, opacity: _opacity) ?? _files!.first.bytes);
    return buildActionLayout(
      context,
      title: 'Водяной знак',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _textCtrl, decoration: const InputDecoration(labelText: 'Текст водяного знака'), maxLength: 50, onChanged: (_) => setState(() {})),
          const Text('Позиция:'),
          DropdownButton<String>(
            value: _position,
            items: const [
              DropdownMenuItem(value: 'top-left', child: Text('Верхний левый')),
              DropdownMenuItem(value: 'top-right', child: Text('Верхний правый')),
              DropdownMenuItem(value: 'bottom-left', child: Text('Нижний левый')),
              DropdownMenuItem(value: 'bottom-right', child: Text('Нижний правый')),
            ],
            onChanged: (v) => setState(() => _position = v ?? 'bottom-right'),
          ),
          const Text('Прозрачность:'),
          Slider(value: _opacity, min: 0.2, max: 1.0, onChanged: (v) => setState(() => _opacity = v)),
          Text('${(_opacity * 100).round()}%'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
}

/// Убрать водяной знак: информационный экран (автоудаление не поддерживается).
class RemoveWatermarkPage extends StatelessWidget {
  const RemoveWatermarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Убрать водяной знак')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          const Text(
            'Автоматическое удаление водяного знака с фото не поддерживается.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          const Text(
            'Рекомендации:\n• Загрузите исходное изображение без водяного знака.\n• Если знак расположен по краю — используйте «Обрезать», чтобы обрезать область с водяным знаком.',
            style: TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Размытие лиц: детекция лиц (Face Detector API в браузере), размытие областей лиц.
class FaceBlurPage extends StatefulWidget {
  const FaceBlurPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<FaceBlurPage> createState() => _FaceBlurPageState();
}

class _FaceBlurPageState extends State<FaceBlurPage> {
  List<LoadedFile>? _files;
  String? _error;
  int _blurRadius = 15;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final regions = await detectFaces(f.bytes);
      final out = regions.isEmpty
          ? null
          : ImageService.blurRegions(
              f.bytes,
              regions: regions,
              radius: _blurRadius,
            );
      if (out != null) {
        results.add((name: '${_baseName(f.name)}_faces_blurred.${_extension(f.name)}', bytes: out));
      } else {
        results.add((name: f.name, bytes: f.bytes));
      }
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Размытие лиц')),
        body: Center(child: Text(_error!)),
      );
    }
    if (_files == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Размытие лиц')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Размытие лиц — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
      );
    }
    return buildActionLayout(
      context,
      title: 'Размытие лиц',
      previewPanel: buildPreviewImage(_files!.first.bytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Лица на фото будут найдены (Face Detector API в браузере) и размыты. Лучше всего работает в Chrome.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          const Text('Сила размытия (радиус):'),
          Slider(
            value: _blurRadius.toDouble(),
            min: 5,
            max: 25,
            divisions: 10,
            onChanged: (v) => setState(() => _blurRadius = v.round()),
          ),
          Text('Радиус: $_blurRadius'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(
            onPressed: _processing ? null : _apply,
            child: _processing
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Найти лица и размыть'),
          ),
        ],
      ),
    );
  }
}

/// Удаление фона: фон определяется по цвету углов, похожие пиксели делаются прозрачными. Результат — PNG.
class RemoveBackgroundPage extends StatefulWidget {
  const RemoveBackgroundPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<RemoveBackgroundPage> createState() => _RemoveBackgroundPageState();
}

class _RemoveBackgroundPageState extends State<RemoveBackgroundPage> {
  List<LoadedFile>? _files;
  String? _error;
  double _tolerance = 0.25;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    setState(() {
      if (list.isEmpty) _error = 'Нет файлов.';
      else _files = list;
    });
  }

  Future<void> _apply() async {
    if (_files == null || _files!.isEmpty) return;
    setState(() => _processing = true);
    final results = <LoadedFile>[];
    for (final f in _files!) {
      final out = ImageService.removeBackground(f.bytes, tolerance: _tolerance);
      if (out != null) results.add((name: '${_baseName(f.name)}_nobg.png', bytes: out));
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _results = results;
    });
  }

  void _downloadAll() {
    if (_results == null) return;
    downloadAllAndNotify(context, _results!);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Удалить фон')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Удалить фон')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return buildResultsScaffold(
        context,
        titleDone: 'Удалить фон — готово',
        results: _results!,
        onDownloadAll: _downloadAll,
        topContent: const Text(
          'Результат сохранён в формате PNG с прозрачностью.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      );
    }
    final previewBytes = ImageService.removeBackground(_files!.first.bytes, tolerance: _tolerance) ?? _files!.first.bytes;
    return buildActionLayout(
      context,
      title: 'Удалить фон',
      previewPanel: buildPreviewImage(previewBytes),
      controlsPanel: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Фон определяется по среднему цвету углов изображения. Пиксели, похожие на этот цвет, становятся прозрачными. Лучше всего работает с однотонным фоном.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          const Text('Чувствительность (чем выше — тем больше область удаляется):'),
          Slider(value: _tolerance, min: 0.08, max: 0.5, onChanged: (v) => setState(() => _tolerance = v)),
          Text('${(_tolerance * 100).round()}%'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(
            onPressed: _processing ? null : _apply,
            child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить'),
          ),
        ],
      ),
    );
  }
}

/// Один штрих: цвет, толщина и точки в нормализованных координатах (0–1).
class _DrawStroke {
  _DrawStroke({required this.color, required this.width});
  final Color color;
  final double width;
  final List<Offset> points = [];
}

/// Экран рисования на фото: загрузка одного изображения, рисование поверх, сохранение в PNG.
class DrawOnPhotoPage extends StatefulWidget {
  const DrawOnPhotoPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<DrawOnPhotoPage> createState() => _DrawOnPhotoPageState();
}

class _DrawOnPhotoPageState extends State<DrawOnPhotoPage> {
  String? _error;
  Uint8List? _imageBytes;
  String _fileName = '';
  ui.Image? _uiImage;
  int _imageWidth = 0;
  int _imageHeight = 0;
  final List<_DrawStroke> _strokes = [];
  _DrawStroke? _currentStroke;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 4.0;
  bool _saving = false;

  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.black,
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFilesFromArgs(widget.args);
    if (!mounted) return;
    if (list.isEmpty) {
      setState(() => _error = 'Нет файлов.');
      return;
    }
    final first = list.first;
    _imageBytes = first.bytes;
    _fileName = first.name;
    final img = await decodeImageFromList(first.bytes);
    if (!mounted) return;
    setState(() {
      _uiImage = img;
      _imageWidth = img.width;
      _imageHeight = img.height;
    });
  }

  Rect _imageRect(Size size) {
    if (_imageWidth <= 0 || _imageHeight <= 0) return Rect.zero;
    final aspectImage = _imageWidth / _imageHeight;
    final aspectBox = size.width / size.height;
    double w, h;
    if (aspectBox > aspectImage) {
      h = size.height;
      w = size.height * aspectImage;
    } else {
      w = size.width;
      h = size.width / aspectImage;
    }
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  Offset _localToNormalized(Offset local, Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) return Offset.zero;
    return Offset(
      ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0),
      ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0),
    );
  }

  void _onPanStart(DragStartDetails details, Rect rect) {
    final norm = _localToNormalized(details.localPosition, rect);
    setState(() {
      _currentStroke = _DrawStroke(color: _selectedColor, width: _strokeWidth);
      _currentStroke!.points.add(norm);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Rect rect) {
    if (_currentStroke == null) return;
    final norm = _localToNormalized(details.localPosition, rect);
    setState(() => _currentStroke!.points.add(norm));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.points.length >= 2) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
    } else {
      setState(() => _currentStroke = null);
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<void> _save() async {
    if (_uiImage == null || _imageBytes == null) return;
    setState(() => _saving = true);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = _imageWidth.toDouble();
    final h = _imageHeight.toDouble();
    canvas.drawImageRect(
      _uiImage!,
      Rect.fromLTWH(0, 0, w, h),
      Rect.fromLTWH(0, 0, w, h),
      Paint(),
    );
    for (final stroke in _strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width * (w + h) / 200
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        final p1 = Offset(stroke.points[i].dx * w, stroke.points[i].dy * h);
        final p2 = Offset(stroke.points[i + 1].dx * w, stroke.points[i + 1].dy * h);
        canvas.drawLine(p1, p2, paint);
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(_imageWidth, _imageHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted) return;
    setState(() => _saving = false);
    if (byteData != null) {
      final bytes = Uint8List.view(byteData.buffer);
      final name = '${_baseName(_fileName)}_drawn.png';
      downloadBytes(bytes, name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изображение сохранено')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Рисовать')),
        body: Center(child: Text(_error!)),
      );
    }
    if (_uiImage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Рисовать')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рисовать на фото'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            onPressed: _strokes.isEmpty ? null : _undo,
            tooltip: 'Отменить',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: (_strokes.isEmpty && _currentStroke == null) ? null : _clear,
            tooltip: 'Очистить',
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Сохранить'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 8),
            color: AppTheme.surfaceVariant,
            child: Row(
              children: [
                const Text('Цвет:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: _colors.map((c) {
                    final selected = _selectedColor.value == c.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppTheme.textPrimary : AppTheme.outline,
                            width: selected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16),
                const Text('Толщина:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 20,
                    onChanged: (v) => setState(() => _strokeWidth = v),
                  ),
                ),
                Text('${_strokeWidth.round()}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rect = _imageRect(constraints.biggest);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: CustomPaint(
                        size: rect.size,
                        painter: _ImagePainter(_uiImage!, rect),
                      ),
                    ),
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: GestureDetector(
                        onPanStart: (d) => _onPanStart(d, rect),
                        onPanUpdate: (d) => _onPanUpdate(d, rect),
                        onPanEnd: (_) => _onPanEnd(_),
                        child: CustomPaint(
                          size: rect.size,
                          painter: _StrokesPainter(
                            rect: rect,
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                            imageWidth: _imageWidth,
                            imageHeight: _imageHeight,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.dstRect);
  final ui.Image image;
  final Rect dstRect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter old) => old.image != image || old.dstRect != dstRect;
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({
    required this.rect,
    required this.strokes,
    this.currentStroke,
    required this.imageWidth,
    required this.imageHeight,
  });
  final Rect rect;
  final List<_DrawStroke> strokes;
  final _DrawStroke? currentStroke;
  final int imageWidth;
  final int imageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    void drawStroke(_DrawStroke stroke) {
      if (stroke.points.length < 2) return;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width * (size.width + size.height) / 200
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        final p1 = Offset(stroke.points[i].dx * size.width, stroke.points[i].dy * size.height);
        final p2 = Offset(stroke.points[i + 1].dx * size.width, stroke.points[i + 1].dy * size.height);
        canvas.drawLine(p1, p2, paint);
      }
    }
    for (final s in strokes) drawStroke(s);
    if (currentStroke != null) drawStroke(currentStroke!);
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) =>
      old.strokes != strokes || old.currentStroke != currentStroke;
}
