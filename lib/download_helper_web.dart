import 'dart:html' as html;
import 'dart:typed_data';

/// Скачивание файла в браузере.
void downloadBytes(Uint8List bytes, String filename) {
  final body = html.document.body;
  if (body == null) return;
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    body.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
