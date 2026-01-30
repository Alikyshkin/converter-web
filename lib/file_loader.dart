import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

/// Один файл: имя и байты.
typedef LoadedFile = ({String name, Uint8List bytes});

/// Загружает байты из выбранных (picked) или сброшенных (dropped) файлов.
/// Для dropped нужен [dropzoneController].
Future<List<LoadedFile>> loadFileBytes({
  List<DropzoneFileInterface>? dropped,
  List<PlatformFile>? picked,
  DropzoneViewController? dropzoneController,
}) async {
  if (picked != null && picked.isNotEmpty) {
    return [
      for (final f in picked)
        if (f.bytes != null) (name: f.name, bytes: f.bytes!)
    ];
  }
  if (dropped != null && dropped.isNotEmpty && dropzoneController != null) {
    final list = <LoadedFile>[];
    for (final f in dropped) {
      final name = await dropzoneController.getFilename(f);
      final bytes = await dropzoneController.getFileData(f);
      list.add((name: name, bytes: bytes));
    }
    return list;
  }
  return [];
}
