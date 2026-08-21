import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_domain/campus_domain.dart';
import 'package:admin_web/core/utils/image_byte_store.dart';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Datos de un media del editor de inicio (sin bytes, esos van al byte store).
class HomeEditorMedia {
  final String id;
  final String name;
  final bool isVideo;

  const HomeEditorMedia({
    required this.id,
    required this.name,
    required this.isVideo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isVideo': isVideo,
      };

  static HomeEditorMedia fromJson(Map<String, dynamic> json) => HomeEditorMedia(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        isVideo: json['isVideo'] == true,
      );
}

/// Estado persistible del editor del fondo de inicio.
class HomeEditorState {
  final HomeBackgroundType type;
  final int intervalSeconds;
  final List<HomeEditorMedia> media;

  const HomeEditorState({
    required this.type,
    required this.intervalSeconds,
    this.media = const [],
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'intervalSeconds': intervalSeconds,
        'media': media.map((m) => m.toJson()).toList(),
      };

  static HomeEditorState fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type = HomeBackgroundType.values.asNameMap()[typeName];
    if (type == null) return const HomeEditorState(type: HomeBackgroundType.image, intervalSeconds: 5);
    final interval = (json['intervalSeconds'] as num?)?.toInt() ?? 5;
    final media = (json['media'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(HomeEditorMedia.fromJson)
            .toList() ??
        const <HomeEditorMedia>[];
    return HomeEditorState(type: type, intervalSeconds: interval, media: media);
  }
}

/// Persistencia del editor del fondo de inicio (web).
///
/// - La configuración (tipo, intervalo, metadatos de archivos) se guarda en
///   `PlatformStorage` (localStorage).
/// - Los bytes de los media se guardan en el byte store (IndexedDB en web),
///   como las imágenes de panorama, para no exceder la cuota de localStorage.
///
/// Al recargar la página el editor se reconstruye desde aquí (y también se
/// puede restaurar desde el backend con la sección "Publicado en el backend").
class HomeEditorStorage {
  HomeEditorStorage._();

  static const String _configKey = 'home_editor_config_v1';
  static const String _mediaPrefix = 'home_editor_media_';

  // ═══════════════════════════════════════════
  // CONFIG
  // ═══════════════════════════════════════════

  static Future<void> saveState(HomeEditorState state) async {
    await PlatformStorage.instance.writeJson(_configKey, state.toJson());
  }

  static Future<HomeEditorState?> loadState() async {
    final json = await PlatformStorage.instance.readJson(_configKey);
    if (json == null) return null;
    return HomeEditorState.fromJson(json);
  }

  static Future<void> clearState() async {
    final state = await loadState();
    if (state != null) {
      for (final media in state.media) {
        await deleteMediaBytes(media.id);
      }
    }
    await PlatformStorage.instance.remove(_configKey);
  }

  // ═══════════════════════════════════════════
  // BYTES DE MEDIA
  // ═══════════════════════════════════════════

  static Future<void> saveMediaBytes(String mediaId, Uint8List bytes) async {
    try {
      await writeBytes(_mediaPrefix + mediaId, bytes);
    } on Object {
      await PlatformStorage.instance.write(
        _mediaPrefix + mediaId,
        base64Encode(bytes),
      );
    }
  }

  static Future<Uint8List?> loadMediaBytes(String mediaId) async {
    try {
      final bytes = await readBytes(_mediaPrefix + mediaId);
      if (bytes != null) return bytes;
    } on Object {
      // falla a localStorage como migración
    }
    final raw = await PlatformStorage.instance.read(_mediaPrefix + mediaId);
    if (raw == null) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteMediaBytes(String mediaId) async {
    await PlatformStorage.instance.remove(_mediaPrefix + mediaId);
    try {
      await deleteBytes(_mediaPrefix + mediaId);
    } on Object {
      // noop
    }
  }
}