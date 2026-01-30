import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:image_compressor/app_theme.dart';
import 'package:image_compressor/download_helper.dart';
import 'package:image_compressor/file_loader.dart';
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')),
    );
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
      return Scaffold(
        appBar: AppBar(title: const Text('Сжать — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            Text('Обработано: ${AppTheme.fileCount(_results!.length)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.blockGap),
            ElevatedButton(
              onPressed: _downloadAll,
              child: const Text('Скачать все'),
            ),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(
                  title: Text(f.name),
                  trailing: TextButton(
                    onPressed: () => downloadBytes(f.bytes, f.name),
                    child: const Text('Скачать'),
                  ),
                )),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Сжать')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Конвертировать')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Конвертировать')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Конвертировать — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Конвертировать')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          const Text('Формат результата:'),
          DropdownButton<String>(
            value: _format,
            items: _formats.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _format = v ?? 'png'),
          ),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Размер')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Размер')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Размер — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Размер')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          SwitchListTile(title: const Text('По проценту от оригинала'), value: _percentMode, onChanged: (v) => setState(() => _percentMode = v)),
          if (_percentMode) ...[
            TextField(controller: _percentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Процент (1–100)')),
          ] else ...[
            TextField(controller: _widthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ширина (пусто — по пропорции)')),
            TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Высота (пусто — по пропорции)')),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Повернуть')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Повернуть')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Повернуть — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Повернуть')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          const Text('Угол поворота:'),
          Row(
            children: [90, 180, 270].map((a) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$a°'),
                selected: _angle == a,
                onSelected: (v) => setState(() => _angle = a),
              ),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Отразить')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Отразить')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Отразить — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Отразить')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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

/// Экран обрезки: обрезка по центру (процент ширины/высоты), затем «Применить» и скачивание.
class CropPage extends StatefulWidget {
  const CropPage({super.key, required this.args});

  final ActionPageArgs args;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  List<LoadedFile>? _files;
  String? _error;
  int _widthPercent = 100;
  int _heightPercent = 100;
  List<LoadedFile>? _results;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
      final out = ImageService.crop(f.bytes, widthPercent: _widthPercent, heightPercent: _heightPercent);
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Обрезать')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Обрезать')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Обрезать — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Обрезать')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          const Text('Обрезка по центру (процент от размера):'),
          Slider(value: _widthPercent.toDouble(), min: 10, max: 100, divisions: 9, label: 'Ширина $_widthPercent%', onChanged: (v) => setState(() => _widthPercent = v.round())),
          Text('Ширина: $_widthPercent%'),
          Slider(value: _heightPercent.toDouble(), min: 10, max: 100, divisions: 9, label: 'Высота $_heightPercent%', onChanged: (v) => setState(() => _heightPercent = v.round())),
          Text('Высота: $_heightPercent%'),
          const SizedBox(height: AppTheme.sectionGap),
          FilledButton(onPressed: _processing ? null : _apply, child: _processing ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Применить')),
        ],
      ),
    );
  }
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Фильтры')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Фильтры')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Фильтры — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Фильтры')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Редактор')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Редактор')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактор — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }

    final file = _files![_previewIndex];
    final previewBytes = _applyPipeline(file.bytes);
    final hasPreview = previewBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор фото'),
        actions: [
          if (_files!.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: DropdownButton<int>(
                  value: _previewIndex,
                  items: List.generate(_files!.length, (i) => DropdownMenuItem(value: i, child: Text('${i + 1}. ${_files![i].name}'))),
                  onChanged: (v) => setState(() => _previewIndex = v ?? 0),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          if (hasPreview)
            Container(
              height: 220,
              margin: const EdgeInsets.only(bottom: AppTheme.sectionGap),
              decoration: BoxDecoration(border: Border.all(color: AppTheme.outline), borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              child: Image.memory(previewBytes, fit: BoxFit.contain),
            )
          else
            const SizedBox(height: 120, child: Center(child: Text('Превью недоступно'))),
          const Divider(),
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
              TextField(controller: _resizeWidthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ширина')),
              TextField(controller: _resizeHeightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Высота (пусто — по пропорции)')),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Увеличить')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Увеличить')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Увеличить — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Увеличить')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Резкость')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Резкость')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Резкость — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Резкость / Улучшить качество')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Размытие')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Размытие')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Размытие — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Размытие')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Водяной знак')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Водяной знак')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Водяной знак — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Водяной знак')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          TextField(controller: _textCtrl, decoration: const InputDecoration(labelText: 'Текст водяного знака'), maxLength: 50),
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
    final list = await loadFileBytes(
      dropped: widget.args.dropped,
      picked: widget.args.picked,
      dropzoneController: widget.args.dropzoneController,
    );
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
    for (final f in _results!) {
      downloadBytes(f.bytes, f.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Скачано: ${AppTheme.fileCount(_results!.length)}')));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Удалить фон')), body: Center(child: Text(_error!)));
    if (_files == null) return Scaffold(appBar: AppBar(title: const Text('Удалить фон')), body: const Center(child: CircularProgressIndicator()));
    if (_results != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Удалить фон — готово')),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            const Text('Результат сохранён в формате PNG с прозрачностью.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.blockGap),
            ElevatedButton(onPressed: _downloadAll, child: const Text('Скачать все')),
            const SizedBox(height: AppTheme.sectionGap),
            ..._results!.map((f) => ListTile(title: Text(f.name), trailing: TextButton(onPressed: () => downloadBytes(f.bytes, f.name), child: const Text('Скачать')))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Удалить фон')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
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
