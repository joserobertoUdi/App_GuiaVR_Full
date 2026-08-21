import 'dart:io';

import 'package:campus_domain/campus_domain.dart';
import 'package:app_guia_ar/core/utils/platform_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Configuración y media del fondo de la pantalla de inicio.
///
/// La configuración ([HomeBackgroundConfig]) llega en el bundle desde el admin
/// y se guarda en SharedPreferences. Los archivos de media (imagen/video del
/// fondo) se descargan del backend y se guardan como archivos en el directorio
/// de documentos de la app para evitar inflar el almacenamiento de preferencias.
class HomeContentStorage {
  HomeContentStorage._();

  static const String _configKey = 'home_background_config';
  static const String _mediaDir = 'home_media';

  static HomeBackgroundConfig? _cachedConfig;
  static final Map<String, Uint8List> _bytesCache = {};
  static final Map<String, File> _fileCache = {};

  /// Notifica cuando cambia la config (sync del backend). La pantalla de inicio
  /// escucha para recargar el fondo sin necesidad de reiniciar la app.
  static final ChangeNotifier changes = _HomeContentNotifier();

  /// Dispara [changes] públicamente (la sync del backend la llama al terminar).
  static void notifyChange() {
    (changes as _HomeContentNotifier).notify();
  }

  // ═══════════════════════════════════════════
  // CONFIG
  // ═══════════════════════════════════════════

  /// Guarda la configuración del fondo de inicio.
  static Future<void> saveConfig(HomeBackgroundConfig config) async {
    await PlatformStorage.instance
        .writeJson(_configKey, config.toJson());
    _cachedConfig = config;
    notifyChange();
  }

  /// Lee la configuración guardada, o `null` si no existe.
  static Future<HomeBackgroundConfig?> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig;
    final json = await PlatformStorage.instance.readJson(_configKey);
    _cachedConfig = HomeBackgroundConfig.fromJson(json);
    return _cachedConfig;
  }

  // ═══════════════════════════════════════════
  // MEDIA
  // ═══════════════════════════════════════════

  static Future<Directory> _mediaDirPath() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}$_mediaDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _extFor(HomeBackgroundType type) {
    switch (type) {
      case HomeBackgroundType.video:
        return '.mp4';
      case HomeBackgroundType.image:
      case HomeBackgroundType.carousel:
      case HomeBackgroundType.panorama:
        return '.jpg';
    }
  }

  /// Guarda un media descargado del backend y lo devuelve como [File].
  static Future<File> saveMedia({
    required String mediaId,
    required List<int> bytes,
    required HomeBackgroundType type,
  }) async {
    final dir = await _mediaDirPath();
    final file = File('${dir.path}${Platform.pathSeparator}$mediaId${_extFor(type)}');
    await file.writeAsBytes(bytes, flush: true);
    _fileCache[mediaId] = file;
    _bytesCache[mediaId] = Uint8List.fromList(bytes);
    return file;
  }

  /// Devuelve el archivo local de un media (`null` si no existe).
  static Future<File?> mediaFile(String mediaId, HomeBackgroundType type) async {
    final cached = _fileCache[mediaId];
    if (cached != null && await cached.exists()) return cached;

    final dir = await _mediaDirPath();
    final file = File('${dir.path}${Platform.pathSeparator}$mediaId${_extFor(type)}');
    if (await file.exists()) {
      _fileCache[mediaId] = file;
      return file;
    }
    return null;
  }

  /// Devuelve los bytes de un media desde el cache en memoria.
  static Uint8List? mediaBytesFromCache(String mediaId) => _bytesCache[mediaId];

  /// Indica si ya existe localmente un media.
  static Future<bool> hasMedia(String mediaId, HomeBackgroundType type) async {
    return await mediaFile(mediaId, type) != null;
  }

  /// Elimina un media local (si existe).
  static Future<void> deleteMedia(String mediaId, HomeBackgroundType type) async {
    final file = await mediaFile(mediaId, type);
    if (file != null && await file.exists()) {
      await file.delete();
    }
    _fileCache.remove(mediaId);
    _bytesCache.remove(mediaId);
  }

  /// Elimina los media locales cuyo id NO esté en [keepIds]. Útil tras una
  /// sincronización para no dejar archivos huérfanos del backend.
  static Future<int> cleanupMedia(Set<String> keepIds) async {
    final dir = await _mediaDirPath();
    if (!await dir.exists()) return 0;
    var removed = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final id = _stripMediaExtension(entity.uri.pathSegments.last);
      if (id.isEmpty || keepIds.contains(id)) continue;
      try {
        await entity.delete();
        _fileCache.remove(id);
        _bytesCache.remove(id);
        removed++;
      } catch (_) {}
    }
    return removed;
  }

  static String _stripMediaExtension(String fileName) {
    for (final ext in const ['.jpg', '.mp4']) {
      if (fileName.endsWith(ext)) return fileName.substring(0, fileName.length - ext.length);
    }
    return fileName;
  }

  /// Elimina la config y todos los media guardados.
  static Future<void> clearAll() async {
    await PlatformStorage.instance.remove(_configKey);
    _cachedConfig = null;
    final dir = await _mediaDirPath();
    if (await dir.exists()) {
      for (final file in await dir.list().toList()) {
        if (file is File) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    }
    _fileCache.clear();
    _bytesCache.clear();
    notifyChange();
  }
}

/// Notifier para [HomeContentStorage.changes] con método público no protegido.
class _HomeContentNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}