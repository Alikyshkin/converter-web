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

  static const double _maxContentWidth = 760.0;

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
                    onTap: () => _onCompress(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.transform_rounded,
                    label: 'Конвертировать',
                    onTap: () => _onConvert(context),
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
                    onTap: () => _onResize(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.rotate_right_rounded,
                    label: 'Повернуть',
                    onTap: () => _onRotate(context),
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
                    onTap: () => _onFlip(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.crop_rounded,
                    label: 'Обрезать',
                    onTap: () => _onCrop(context),
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
                    onTap: () => _onFilters(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Редактор',
                    onTap: () => _onEditor(context),
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
                    onTap: () => _onUpscale(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Улучшить качество',
                    onTap: () => _onSharpen(context),
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
                    onTap: () => _onBlur(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.blur_off_rounded,
                    label: 'Убрать размытие',
                    onTap: () => _onSharpen(context),
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
                    onTap: () => _onWatermark(context),
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
                    onTap: () => _onFaceBlur(context),
                  ),
                ),
                const SizedBox(width: AppTheme.blockGap),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.layers_clear_rounded,
                    label: 'Удалить фон',
                    onTap: () => _onRemoveBackground(context),
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
                    onTap: () => _onDrawOnPhoto(context),
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
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _pickFiles(context),
                  icon: const Icon(Icons.folder_open_rounded, size: 22),
                  label: const Text('Выбрать файлы'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
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
                      const SizedBox(height: 8),
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
              ],
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

  ActionPageArgs get _actionPageArgs => ActionPageArgs(
        dropped: _droppedFiles,
        picked: _pickedFiles,
        dropzoneController: _dropzoneController,
      );

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _onCompress(BuildContext context) => _pushPage(context, CompressPage(args: _actionPageArgs));

  void _onConvert(BuildContext context) => _pushPage(context, ConvertPage(args: _actionPageArgs));

  void _onResize(BuildContext context) => _pushPage(context, ResizePage(args: _actionPageArgs));

  void _onRotate(BuildContext context) => _pushPage(context, RotatePage(args: _actionPageArgs));

  void _onFlip(BuildContext context) => _pushPage(context, FlipPage(args: _actionPageArgs));

  void _onCrop(BuildContext context) => _pushPage(context, CropPage(args: _actionPageArgs));

  void _onFilters(BuildContext context) => _pushPage(context, FiltersPage(args: _actionPageArgs));

  void _onEditor(BuildContext context) => _pushPage(context, EditorPage(args: _actionPageArgs));

  void _onUpscale(BuildContext context) => _pushPage(context, UpscalePage(args: _actionPageArgs));

  void _onSharpen(BuildContext context) => _pushPage(context, SharpenPage(args: _actionPageArgs));

  void _onBlur(BuildContext context) => _pushPage(context, BlurPage(args: _actionPageArgs));

  void _onWatermark(BuildContext context) => _pushPage(context, WatermarkPage(args: _actionPageArgs));

  void _onRemoveWatermark(BuildContext context) => _pushPage(context, const RemoveWatermarkPage());

  void _onFaceBlur(BuildContext context) => _pushPage(context, FaceBlurPage(args: _actionPageArgs));

  void _onDrawOnPhoto(BuildContext context) => _pushPage(context, DrawOnPhotoPage(args: _actionPageArgs));

  void _onRemoveBackground(BuildContext context) => _pushPage(context, RemoveBackgroundPage(args: _actionPageArgs));
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
          child: content,
        ),
      ),
    );
  }
}
