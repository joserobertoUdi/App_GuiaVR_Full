import 'dart:convert';
import 'package:app_guia_ar/core/utils/platform_storage.dart';

/// Registra y consulta los destinos más visitados por el usuario.
///
/// Cada vez que el usuario inicia una ruta, se incrementa el contador
/// del nodo de destino. Los destinos populares se muestran ordenados
/// de mayor a menor visitas.
class PopularDestinations {
  PopularDestinations._();

  static const String _storageKey = 'popular_destinations_v1';
  static Map<String, int>? _cache;

  /// Registra una visita al destino [nodeId].
  static Future<void> trackVisit(String nodeId) async {
    final counts = await _load();
    counts[nodeId] = (counts[nodeId] ?? 0) + 1;
    _cache = counts;
    await _save(counts);
  }

  /// Retorna los IDs de los destinos más visitados, ordenados de mayor a menor.
  /// [limit] define cuántos retornar (por defecto 5).
  static Future<List<PopularEntry>> getPopular({int limit = 5}) async {
    final counts = await _load();
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => PopularEntry(
      nodeId: e.key,
      visitCount: e.value,
    )).toList();
  }

  static Future<Map<String, int>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final json = await PlatformStorage.instance.read(_storageKey);
      if (json == null || json.isEmpty) return {};
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      return _cache!;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, int> counts) async {
    try {
      final json = jsonEncode(counts);
      await PlatformStorage.instance.write(_storageKey, json);
    } catch (_) {}
  }

  /// Limpia el historial de visitas.
  static Future<void> clear() async {
    _cache = null;
    await PlatformStorage.instance.remove(_storageKey);
  }
}

/// Entrada de destino popular con su conteo de visitas.
class PopularEntry {
  final String nodeId;
  final int visitCount;

  const PopularEntry({required this.nodeId, required this.visitCount});
}
