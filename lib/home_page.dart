import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:image_compressor/action_pages.dart';
import 'package:image_compressor/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialUploadedCountForTesting});

  /// Только для тестов: показать экран «Загружено N файлов» без реальной загрузки.
  final int? initialUploadedCountForTesting;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dropzoneHover = false;
  int? _uploadedCount;
  List<DropzoneFileInterface>? _droppedFiles;
  List<PlatformFile>? _pickedFiles;
  DropzoneViewController? _dropzoneController;

  bool get _hasUploadedFiles => _uploadedCount != null && _uploadedCount! > 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialUploadedCountForTesting != null) {
      _uploadedCount = widget.initialUploadedCountForTesting;
    }
  }

  static const double _maxContentWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
                  sliver: SliverToBoxAdapter(
                    child: Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.titleTop,
                        bottom: AppTheme.titleToSubtitle,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Image Compressor',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  letterSpacing: 0,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.titleToSubtitle),
                          Text(
                            'Загрузите фото и выберите действие',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppTheme.subtitleToContent,
                      bottom: AppTheme.sectionGap,
                    ),
                    child: _buildDropZoneOrActions(context),
                  ),
                ),
              ),
              ],
            ),
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
    final label = AppTheme.fileCount(count);

    return Semantics(
      label: 'Загружено $label. Выберите инструмент для работы с фото.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.outline, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.textPrimary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Загружено: $label',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sectionGap),
            const Text(
              'Что сделать с фото?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.4,
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
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.flip_rounded,
                    label: 'Отразить',
                    onTap: () => _onFlip(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.crop_rounded,
                    label: 'Обрезать',
                    onTap: () => _onCrop(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.filter_rounded,
                    label: 'Фильтры',
                    onTap: () => _onFilters(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Редактор',
                    onTap: () => _onEditor(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.zoom_in_rounded,
                    label: 'Увеличить',
                    onTap: () => _onUpscale(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Улучшить качество',
                    onTap: () => _onSharpen(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.blur_on_rounded,
                    label: 'Размытие',
                    onTap: () => _onBlur(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.blur_off_rounded,
                    label: 'Убрать размытие',
                    onTap: () => _onSharpen(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.branding_watermark_rounded,
                    label: 'Водяной знак',
                    onTap: () => _onWatermark(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Убрать вод. знак',
                    onTap: () => _onRemoveWatermark(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.face_rounded,
                    label: 'Размытие лиц',
                    onTap: () => _onFaceBlur(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.layers_clear_rounded,
                    label: 'Удалить фон',
                    onTap: () => _onRemoveBackground(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.blockGap),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.draw_rounded,
                    label: 'Рисовать',
                    onTap: () => _onDrawOnPhoto(context, dropped: _droppedFiles, picked: _pickedFiles),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearUpload,
              child: const Text(
                'Загрузить другие',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
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
              onCreated: (DropzoneViewController ctrl) => setState(() => _dropzoneController = ctrl),
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
                    color: _dropzoneHover ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.blockGap),
                  Text(
                    _dropzoneHover ? 'Отпустите для загрузки' : 'Перетащите изображения сюда',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG, WebP, GIF, BMP',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
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
                  splashColor: AppTheme.textPrimary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Выбрать файлы',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
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
      width: double.infinity,
      height: AppTheme.dropZoneHeight,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isHover ? AppTheme.textPrimary : AppTheme.outline,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompressPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onConvert(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConvertPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onResize(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResizePage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onRotate(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RotatePage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onFlip(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlipPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onCrop(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onFilters(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FiltersPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onEditor(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onUpscale(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpscalePage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onSharpen(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharpenPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onBlur(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlurPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onWatermark(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WatermarkPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onRemoveWatermark(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RemoveWatermarkPage(),
      ),
    );
  }

  void _onFaceBlur(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FaceBlurPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onDrawOnPhoto(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawOnPhotoPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }

  void _onRemoveBackground(
    BuildContext context, {
    List<DropzoneFileInterface>? dropped,
    List<PlatformFile>? picked,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoveBackgroundPage(
          args: ActionPageArgs(
            dropped: dropped,
            picked: picked,
            dropzoneController: _dropzoneController,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textPrimary, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          splashColor: AppTheme.textPrimary.withOpacity(0.1),
          child: fullWidth ? SizedBox(width: double.infinity, child: content) : content,
        ),
      ),
    );
  }
}
