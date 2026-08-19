import 'dart:typed_data';

/// Implementación para entornos sin navegador (tests en VM, desktop).
/// Lanza [UnsupportedError] para avisar que la web de administración solo
/// opera dentro de un navegador.
Future<Uint8List?> pickImageBytes() async {
  throw UnsupportedError('WebFileIO no disponible fuera del navegador');
}

Future<Uint8List?> pickVideoBytes() async {
  throw UnsupportedError('WebFileIO no disponible fuera del navegador');
}

Future<String?> pickJsonText() async {
  throw UnsupportedError('WebFileIO no disponible fuera del navegador');
}

void downloadFile(String filename, String content, {String mime = 'application/json'}) {
  throw UnsupportedError('WebFileIO no disponible fuera del navegador');
}

void downloadBytes(String filename, List<int> bytes, {String mime = 'application/octet-stream'}) {
  throw UnsupportedError('WebFileIO no disponible fuera del navegador');
}