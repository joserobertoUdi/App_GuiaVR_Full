import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_guia_ar/core/utils/app_settings.dart';
import 'package:app_guia_ar/core/utils/campus_bundle_export.dart';
import 'package:app_guia_ar/core/utils/home_content_storage.dart';
import 'package:app_guia_ar/core/utils/local_image_storage.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

/// Notificador global de sync. Las pantallas que dependen del campus
/// deben escuchar [changes] para reconstruirse cuando el sync termine.
class CampusSyncNotifier {
  CampusSyncNotifier._();
  static final instance = CampusSyncNotifier._();
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get changes => _controller.stream;
  void notify() => _controller.add(true);
}

/// Sincronización automática con el backend de push.
///
/// Al arrancar la app consulta el servidor del admin:
///   - `/api/bundle`: último bundle publicado (campus + overlays + direcciones +
///     configuración del fondo de inicio), se aplica con
///     `CampusBundleExport.importFromBundle`.
///   - `/api/images`: imágenes de panorama por nodo descargadas y guardadas en
///     `LocalImageStorage`.
///   - `/api/home-media`: media del fondo de inicio (imagen/video/carrusel/360°)
///     descargados y guardados en `HomeContentStorage`.
///
/// Es transparente para el usuario final: no hay botones ni configuración.
class CampusSyncService {
  CampusSyncService._();

  static const Duration _timeout = Duration(seconds: 10);

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

      var homeDownloaded = 0;
      var homePruned = 0;
      try {
        final result = await _downloadHomeMedia(client, baseUrl);
        homeDownloaded = result.$1;
        homePruned = result.$2;
      } catch (_) {}

      client.close(force: true);
      if (applied) {
        stdout.writeln('[sync] bundle aplicado desde $baseUrl');
      }
      if (applied || homeDownloaded > 0 || homePruned > 0) {
        stdout.writeln(
            '[sync] home: $homeDownloaded media descargados, $homePruned '
            'huérfanos eliminados desde $baseUrl');
      }
      if (applied) {
        CampusSyncNotifier.instance.notify();
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

  /// Descarga los media del fondo de inicio configurados en el bundle y purga
  /// los que ya no estén en la configuración. Devuelve `(descargados, purgados)`.
  static Future<(int, int)> _downloadHomeMedia(
    HttpClient client,
    String baseUrl,
  ) async {
    final config = await HomeContentStorage.loadConfig();
    if (config == null || config.isEmpty) return (0, 0);

    var downloaded = 0;
    for (final mediaId in config.mediaIds) {
      final hasLocal = await HomeContentStorage.hasMedia(mediaId, config.type);
      if (hasLocal) continue;

      final mediaRequest =
          await client.getUrl(Uri.parse('$baseUrl/api/home-media/$mediaId'));
      final mediaResponse = await mediaRequest.close();
      if (mediaResponse.statusCode != HttpStatus.ok) continue;

      final bytes = await mediaResponse
          .fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      if (bytes.isEmpty) continue;
      await HomeContentStorage.saveMedia(
        mediaId: mediaId,
        bytes: bytes,
        type: config.type,
      );
      downloaded++;
    }

    final pruned = await HomeContentStorage.cleanupMedia(config.mediaIds.toSet());

    // Notifica a la pantalla de inicio para recargar el fondo sin reiniciar.
    if (downloaded > 0) {
      HomeContentStorage.notifyChange();
    }
    return (downloaded, pruned);
  }
}