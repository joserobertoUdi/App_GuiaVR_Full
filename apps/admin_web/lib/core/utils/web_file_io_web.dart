// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as web;

/// Implementación para navegador usando `dart:html`.
///
/// `pickImageBytes`: abre el diálogo del sistema para elegir una imagen.
/// `pickJsonText`: abre el diálogo para elegir un archivo JSON y lo lee como texto.
/// `downloadFile`: dispara la descarga de un archivo generado en memoria.
Future<Uint8List?> pickImageBytes() {
  return _pickBytes(accept: 'image/*');
}

Future<String?> pickJsonText() {
  final completer = Completer<String?>();

  final input = web.FileUploadInputElement()
    ..accept = '.json,application/json,text/plain';

  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = web.FileReader();
    reader.onError.listen((_) => completer.complete(null));
    reader.onLoad.listen((_) {
      final result = reader.result;
      completer.complete(result is String ? result : null);
    });
    reader.readAsText(file);
  });

  input.click();
  return completer.future;
}

Future<Uint8List?> _pickBytes({required String accept}) {
  final completer = Completer<Uint8List?>();

  final input = web.FileUploadInputElement()..accept = accept;

  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = web.FileReader();
    reader.onError.listen((_) => completer.complete(null));
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result);
      } else if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else {
        completer.complete(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}

void downloadFile(
  String filename,
  String content, {
  String mime = 'application/json',
}) {
  final blob = web.Blob([content], mime);
  final url = web.Url.createObjectUrlFromBlob(blob);

  final anchor = web.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.Url.revokeObjectUrl(url);
}

/// Descarga bytes binarios (p.ej. PNG) con nombre y MIME especificados.
void downloadBytes(
  String filename,
  List<int> bytes, {
  String mime = 'application/octet-stream',
}) {
  final blob = web.Blob([Uint8List.fromList(bytes)], mime);
  final url = web.Url.createObjectUrlFromBlob(blob);

  final anchor = web.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.Url.revokeObjectUrl(url);
}