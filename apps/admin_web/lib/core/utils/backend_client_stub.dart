import 'dart:typed_data';

/// Stub para entornos sin navegador (tests en VM). La publicación del bundle
/// e imágenes solo tiene sentido ejecutándose dentro de un navegador.
Future<bool> publishBundle(String baseUrl, String bundleJson) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<bool> publishImage(
  String baseUrl,
  String nodeId,
  Uint8List bytes,
) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<bool> publishHomeMedia(
  String baseUrl,
  String mediaId,
  Uint8List bytes,
) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<Map<String, dynamic>?> fetchBundleVersion(String baseUrl) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<String?> fetchBundle(String baseUrl) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<List<String>> fetchHomeMediaList(String baseUrl) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<Uint8List?> fetchHomeMediaBytes(String baseUrl, String mediaId) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<List<String>> fetchImageIds(String baseUrl) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}

Future<Uint8List?> fetchImageBytes(String baseUrl, String nodeId) async {
  throw UnsupportedError('BackendClient no disponible fuera del navegador');
}