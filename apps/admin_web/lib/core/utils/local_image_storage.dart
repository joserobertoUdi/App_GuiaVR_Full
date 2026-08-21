import 'dart:convert';
import 'dart:typed_data';
import 'package:admin_web/core/utils/image_byte_store.dart';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Almacenamiento local de imágenes de panorama.
/// - En web: los bytes van a IndexedDB (cuota de cientos de MB, apta para
///   panoramas 360°); el base64 en localStorage se usa solo como migración de
///   imágenes guardadas con versiones anteriores.
/// - En móvil: mantiene la lógica de archivos si path_provider está disponible,
///   pero sin importar dart:io directamente (usa la abstracción de PlatformStorage).
class LocalImageStorage {
  static const String _metadataKey = 'panorama_image_metadata';
  static const String _imagePrefix = 'panorama_img_';
  static const String _thumbPrefix = 'panorama_thumb_';

  /// Cache en memoria por nodo para evitar releer en cada transición.
  static final Map<String, _ImageEntry?> _imageCache = {};

  // ═══════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════

  /// Guarda una imagen de panorama para un nodo.
  /// [bytes] son los bytes de la imagen (JPEG/PNG).
  static Future<void> saveImage({
    required String nodeId,
    required List<int> bytes,
    String? description,
  }) async {
    final uint8 = Uint8List.fromList(bytes);
    final storage = PlatformStorage.instance;

    // Guardar imagen: IndexedDB en web; base64 en localStorage si no se pudo
    // usar IndexedDB, o en plataformas sin navegador.
    try {
      await writeBytes('$_imagePrefix$nodeId', uint8);
    } on Object {
      await storage.write('$_imagePrefix$nodeId', base64Encode(uint8));
    }

    // Guardar metadata
    final metadata = await _loadMetadata();
    metadata[nodeId] = {
      'nodeId': nodeId,
      'fileSize': bytes.length,
      'uploadDate': DateTime.now().toIso8601String(),
      'description': description,
      'status': 'local',
    };
    await _saveMetadata(metadata);

    // Invalidar cache
    _imageCache[nodeId] = null;
  }

  /// Obtiene los bytes de la imagen de un nodo como Uint8List.
  /// Devuelve null si no existe imagen para ese nodo.
  static Future<Uint8List?> getImageBytes(String nodeId) async {
    final cached = _imageCache[nodeId];
    if (cached != null) return cached.bytes;

    final storage = PlatformStorage.instance;
    final key = '$_imagePrefix$nodeId';

    Uint8List? base64Data;
    try {
      base64Data = await readBytes(key);
    } on Object {
      base64Data = null;
    }
    if (base64Data == null) {
      // Migración: imágenes guardadas como base64 en versiones anteriores.
      final raw = await storage.read(key);
      if (raw != null) {
        try {
          base64Data = base64Decode(raw);
        } catch (_) {
          base64Data = null;
        }
      }
    }

    if (base64Data == null) {
      _imageCache[nodeId] = _ImageEntry.empty();
      return null;
    }

    final entry = _ImageEntry(bytes: base64Data);
    _imageCache[nodeId] = entry;
    return base64Data;
  }

  /// Indica si existe una imagen guardada para el nodo.
  static Future<bool> hasImage(String nodeId) async {
    final storage = PlatformStorage.instance;
    final key = '$_imagePrefix$nodeId';
    try {
      if (await hasBytes(key)) return true;
    } on Object {
      // falla a localStorage como migración
    }
    return await storage.contains(key);
  }

  /// Elimina la imagen de un nodo.
  static Future<void> deleteImage(String nodeId) async {
    final storage = PlatformStorage.instance;
    await storage.remove('$_imagePrefix$nodeId');
    await storage.remove('$_thumbPrefix$nodeId');
    try {
      await deleteBytes('$_imagePrefix$nodeId');
    } on Object {
      // noop
    }

    final metadata = await _loadMetadata();
    metadata.remove(nodeId);
    await _saveMetadata(metadata);
    _imageCache[nodeId] = null;
  }

  /// Lista los IDs de nodos que tienen imagen.
  static Future<List<String>> getAllNodeIdsWithImages() async {
    final metadata = await _loadMetadata();
    return metadata.keys.toList();
  }

  /// Metadata de un nodo específico.
  static Future<Map<String, dynamic>?> getNodeMetadata(String nodeId) async {
    final metadata = await _loadMetadata();
    return metadata[nodeId] as Map<String, dynamic>?;
  }

  /// Número total de imágenes almacenadas.
  static Future<int> getImageCount() async {
    final metadata = await _loadMetadata();
    return metadata.length;
  }

  /// Tamaño total de las imágenes en bytes.
  static Future<int> getTotalImageSize() async {
    final metadata = await _loadMetadata();
    int totalSize = 0;
    for (final nodeData in metadata.values) {
      final data = nodeData as Map<String, dynamic>;
      totalSize += (data['fileSize'] as int?) ?? 0;
    }
    return totalSize;
  }

  /// Elimina todas las imágenes y metadata.
  static Future<void> clearAll() async {
    final metadata = await _loadMetadata();
    final storage = PlatformStorage.instance;

    for (final nodeId in metadata.keys) {
      await storage.remove('$_imagePrefix$nodeId');
      await storage.remove('$_thumbPrefix$nodeId');
      try {
        await deleteBytes('$_imagePrefix$nodeId');
      } on Object {
        // noop
      }
    }

    await storage.remove(_metadataKey);
    _imageCache.clear();
  }

  /// Estadísticas de almacenamiento.
  static Future<Map<String, dynamic>> getStorageStats() async {
    final metadata = await _loadMetadata();
    int imageCount = metadata.length;
    int totalImageSize = 0;

    for (final nodeData in metadata.values) {
      final data = nodeData as Map<String, dynamic>;
      totalImageSize += (data['fileSize'] as int?) ?? 0;
    }

    return {
      'nodeCount': metadata.length,
      'imageCount': imageCount,
      'totalImageSize': totalImageSize,
      'averageImageSize': imageCount > 0 ? totalImageSize ~/ imageCount : 0,
    };
  }

  // ═══════════════════════════════════════════
  // METADATA HELPERS
  // ═══════════════════════════════════════════

  static Future<Map<String, dynamic>> _loadMetadata() async {
    final storage = PlatformStorage.instance;
    final raw = await storage.read(_metadataKey);
    if (raw == null) return {};
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveMetadata(Map<String, dynamic> metadata) async {
    final storage = PlatformStorage.instance;
    await storage.write(_metadataKey, json.encode(metadata));
  }
}

class _ImageEntry {
  final Uint8List? bytes;
  const _ImageEntry({this.bytes});
  factory _ImageEntry.empty() => const _ImageEntry();
}