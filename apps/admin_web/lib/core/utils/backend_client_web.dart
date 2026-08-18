// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;
import 'dart:typed_data';

/// Implementación para navegador usando `dart:html` (HttpRequest + fetch).
Future<bool> publishBundle(String baseUrl, String bundleJson) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/bundle',
      method: 'PUT',
      sendData: bundleJson,
      requestHeaders: const {'Content-Type': 'application/json'},
    );
    final status = request.status ?? 0;
    return status >= 200 && status < 300;
  } catch (_) {
    return false;
  }
}

Future<bool> publishImage(
  String baseUrl,
  String nodeId,
  Uint8List bytes,
) async {
  try {
    final blob = web.Blob([bytes]);
    final request = await web.HttpRequest.request(
      '$baseUrl/api/images/${Uri.encodeComponent(nodeId)}',
      method: 'PUT',
      sendData: blob,
    );
    final status = request.status ?? 0;
    return status >= 200 && status < 300;
  } catch (_) {
    return false;
  }
}

/// Opcional: consulta la versión publicada para mostrarla en el admin.
Future<Map<String, dynamic>?> fetchBundleVersion(String baseUrl) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/bundle/version',
      method: 'GET',
    );
    if ((request.status ?? 0) != 200) return null;
    return json.decode(request.responseText ?? '') as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}