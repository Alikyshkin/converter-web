import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:image_compressor/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dropzoneHover = false;
  int? _uploadedCount;
  List<DropzoneFileInterface>? _droppedFiles;
  List<PlatformFile>? _pickedFiles;

  bool get _hasUploadedFiles => _uploadedCount != null && _uploadedCount! > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.8),
            radius: 1.4,
            colors: [AppTheme.accentDim, AppTheme.background],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      AppTheme.titleTop,
                      AppTheme.pagePadding,
                      AppTheme.titleToSubtitle,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Image Compressor',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.02,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.titleToSubtitle),
                        Text(
                          'Загрузите фото и выберите действие',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    AppTheme.subtitleToContent,
                    AppTheme.pagePadding,
                    AppTheme.sectionGap,
                  ),
                  child: _buildDropZoneOrActions(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZoneOrActions(BuildContext context) {
    if (_hasUploadedFiles) {
      return _buildUploadedActions(context);
    }
    return _buildDropZone(context);
  }

  Widget _buildUploadedActions(BuildContext context) {
    final count = _uploadedCount!;
    final label = count == 1 ? '1 файл' : '$count файлов';

    return Semantics(
      label: 'Загружено $label. Выберите инструмент для работы с фото.',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: AppTheme.success.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Загружено: $label',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sectionGap),
            const Text(
              'Что сделать с фото?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.compress_rounded,
                    label: 'Сжать',
                    onTap: () => _onCompress(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.transform_rounded,
                    label: 'Конвертировать',
                    onTap: () => _onConvert(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.aspect_ratio_rounded,
                    label: 'Размер',
                    onTap: () => _onResize(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.rotate_right_rounded,
                    label: 'Повернуть',
                    onTap: () => _onRotate(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.flip_rounded,
                    label: 'Отразить',
                    onTap: () => _onFlip(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            TextButton(
              onPressed: _clearUpload,
              child: Text(
                'Загрузить другие',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(BuildContext context) {
    if (!kIsWeb) {
      return Semantics(
        button: true,
        label: 'Область загрузки изображений. Доступна в веб-версии.',
        child: _dropZoneDecoration(
          child: Center(
            child: Text(
              'Загрузка файлов доступна в веб-версии',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Область загрузки изображений. Перетащите сюда или нажмите «Выбрать файлы».',
      child: _dropZoneDecoration(
        isHover: _dropzoneHover,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DropzoneView(
              onDropFiles: (files) => _onFilesDropped(context, files ?? const []),
              onDropInvalid: (_) => _showError(context, 'Можно загружать только изображения (JPG, PNG, WebP, GIF, BMP).'),
              onHover: () => setState(() => _dropzoneHover = true),
              onLeave: () => setState(() => _dropzoneHover = false),
              mime: const ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/bmp'],
            ),
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _dropzoneHover ? Icons.folder_open_rounded : Icons.cloud_upload_rounded,
                    size: AppTheme.iconBoxSize,
                    color: _dropzoneHover ? AppTheme.accent : AppTheme.textSecondary.withOpacity(0.8),
                  ),
                  const SizedBox(height: AppTheme.blockGap),
                  Text(
                    _dropzoneHover ? 'Отпустите для загрузки' : 'Перетащите изображения сюда',
                    style: TextStyle(
                      color: _dropzoneHover ? AppTheme.accent : AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG, WebP, GIF, BMP',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: AppTheme.blockGap,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _pickFiles(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  splashColor: AppTheme.accent.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Выбрать файлы',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropZoneDecoration({
    bool isHover = false,
    required Widget child,
  }) {
    return Container(
      height: AppTheme.dropZoneHeight,
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isHover ? AppTheme.accent.withOpacity(0.5) : AppTheme.surfaceVariant.withOpacity(0.5),
          width: isHover ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  void _clearUpload() {
    setState(() {
      _uploadedCount = null;
      _droppedFiles = null;
      _pickedFiles = null;
    });
  }

  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _dropzoneHover = false;
      _uploadedCount = result.files.length;
      _droppedFiles = null;
      _pickedFiles = result.files;
    });
  }

  void _showError(BuildContext context, String message) {
    setState(() => _dropzoneHover = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error.withOpacity(0.9),
      ),
    );
  }

  Future<void> _onFilesDropped(BuildContext context, List<DropzoneFileInterface> files) async {
    if (files.isEmpty) return;
    setState(() {
      _dropzoneHover = false;
      _uploadedCount = files.length;
      _droppedFiles = files;
      _pickedFiles = null;
    });
  }

  void _onCompress(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    final n = _uploadedCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n == 1 ? 'Сжатие 1 файла — в разработке' : 'Сжатие $n файлов — в разработке'),
      ),
    );
    // TODO: экран сжатия с dropped / picked
  }

  void _onConvert(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    final n = _uploadedCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n == 1 ? 'Конвертация 1 файла — в разработке' : 'Конвертация $n файлов — в разработке'),
      ),
    );
    // TODO: экран конвертации с dropped / picked
  }

  void _onResize(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    final n = _uploadedCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n == 1 ? 'Изменение размера — в разработке' : 'Изменение размера $n файлов — в разработке'),
      ),
    );
    // TODO: экран изменения размера с dropped / picked
  }

  void _onRotate(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    final n = _uploadedCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n == 1 ? 'Поворот — в разработке' : 'Поворот $n файлов — в разработке'),
      ),
    );
    // TODO: экран поворота с dropped / picked
  }

  void _onFlip(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    final n = _uploadedCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n == 1 ? 'Отразить — в разработке' : 'Отразить $n файлов — в разработке'),
      ),
    );
    // TODO: экран отражения (по горизонтали/вертикали) с dropped / picked
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          splashColor: AppTheme.accent.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.accent, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
