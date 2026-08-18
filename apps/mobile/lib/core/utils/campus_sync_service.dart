import 'dart:convert';
import 'dart:io';

import 'package:app_guia_ar/core/utils/app_settings.dart';
import 'package:app_guia_ar/core/utils/campus_bundle_export.dart';
import 'package:app_guia_ar/core/utils/local_image_storage.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

/// Sincronización automática con el backend de push.
///
/// Al arrancar la app consulta el servidor del admin:
///   - `/api/bundle`: último bundle publicado (campus + overlays + direcciones),
///     se aplica con `CampusBundleExport.importFromBundle`.
///   - `/api/images`: imágenes de panorama por nodo descargadas y guardadas en
///     `LocalImageStorage`.
///
/// Es transparente para el usuario final: no hay botones ni configuración.
class CampusSyncService {
  CampusSyncService._();

  static const Duration _timeout = Duration(seconds: 8);

  static Future<void> sync() async {
    final baseUrl = await AppSettings.backendBaseUrl();
    if (baseUrl.isEmpty) return;

    try {
      final client = HttpClient()
        ..connectionTimeout = _timeout
        ..idleTimeout = _timeout;

      var applied = false;
      try {
        final appliedBundle = await _downloadBundle(client, baseUrl);
        if (appliedBundle != null) {
          final ok = CampusBundleExport.importFromBundle(appliedBundle);
          if (ok) {
            await MockCampusData.saveToFile();
            applied = true;
          }
        }
      } catch (_) {}

      try {
        await _downloadImages(client, baseUrl);
      } catch (_) {}

      client.close(force: true);
      if (applied) {
        stdout.writeln('[sync] bundle aplicado desde $baseUrl');
      }
    } catch (_) {}
  }

  static Future<String?> _downloadBundle(HttpClient client, String baseUrl) async {
    final request = await client.getUrl(Uri.parse('$baseUrl/api/bundle'));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return null;
    return await utf8.decoder.bind(response).join();
  }

  static Future<void> _downloadImages(
    HttpClient client,
    String baseUrl,
  ) async {
    final request = await client.getUrl(Uri.parse('$baseUrl/api/images'));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return;

    final payload = json.decode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
    final ids = (payload['images'] as List?)?.cast<String>() ?? [];

    for (final nodeId in ids) {
      final hasLocal = await LocalImageStorage.hasImage(nodeId);
      if (hasLocal) continue;

      final imgRequest =
          await client.getUrl(Uri.parse('$baseUrl/api/images/$nodeId'));
      final imgResponse = await imgRequest.close();
      if (imgResponse.statusCode != HttpStatus.ok) continue;

      final bytes =
          await imgResponse.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      if (bytes.isEmpty) continue;
      await LocalImageStorage.saveImage(nodeId: nodeId, bytes: bytes);
    }
  }
}