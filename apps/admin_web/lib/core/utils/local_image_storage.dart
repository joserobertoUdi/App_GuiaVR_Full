import 'dart:convert';
import 'dart:typed_data';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Almacenamiento local de imágenes de panorama.
/// - En web: almacena base64 en SharedPreferences (localStorage).
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
    final base64Data = base64Encode(bytes);
    final storage = PlatformStorage.instance;

    // Guardar imagen como base64
    await storage.write('$_imagePrefix$nodeId', base64Data);

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
    final base64Data = await storage.read('$_imagePrefix$nodeId');
    if (base64Data == null) {
      _imageCache[nodeId] = _ImageEntry.empty();
      return null;
    }

    try {
      final bytes = base64Decode(base64Data);
      final entry = _ImageEntry(bytes: bytes);
      _imageCache[nodeId] = entry;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Indica si existe una imagen guardada para el nodo.
  static Future<bool> hasImage(String nodeId) async {
    final storage = PlatformStorage.instance;
    return await storage.contains('$_imagePrefix$nodeId');
  }

  /// Elimina la imagen de un nodo.
  static Future<void> deleteImage(String nodeId) async {
    final storage = PlatformStorage.instance;
    await storage.remove('$_imagePrefix$nodeId');
    await storage.remove('$_thumbPrefix$nodeId');

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