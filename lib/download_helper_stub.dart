import 'dart:typed_data';

/// Заглушка: скачивание поддерживается только в веб-версии.
void downloadBytes(Uint8List bytes, String filename) {
  throw UnsupportedError('Скачивание доступно только в веб-версии.');
}
