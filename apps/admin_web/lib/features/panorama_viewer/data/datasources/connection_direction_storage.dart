import 'package:admin_web/core/utils/platform_storage.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/connection_direction_model.dart';

/// Almacén en memoria de las direcciones de conexión definidas por el operador.
/// Cada entrada asocia un nodo con uno de sus nodos conectados y apunta a qué
/// punto de la foto 360° (yaw/pitch) corresponde esa salida.
class ConnectionDirectionStorage {
  ConnectionDirectionStorage._();

  static const String _storageKey = 'connection_directions_json';

  static final Map<String, Map<String, ConnectionDirection>> _directions = {};

  static ConnectionDirection? getDirection(String nodeId, String targetNodeId) {
    return _directions[nodeId]?[targetNodeId];
  }

  static List<ConnectionDirection> getDirectionsForNode(String nodeId) {
    return List.unmodifiable(_directions[nodeId]?.values ?? const []);
  }

  static bool hasDirection(String nodeId, String targetNodeId) {
    return getDirection(nodeId, targetNodeId) != null;
  }

  static void setDirection(ConnectionDirection direction) {
    final nodeDirections = _directions[direction.nodeId] ?? {};
    nodeDirections[direction.targetNodeId] = direction;
    _directions[direction.nodeId] = nodeDirections;
    _save();
  }

  static void removeDirection(String nodeId, String targetNodeId) {
    final nodeDirections = _directions[nodeId];
    if (nodeDirections == null) return;
    nodeDirections.remove(targetNodeId);
    if (nodeDirections.isEmpty) {
      _directions.remove(nodeId);
    }
    _save();
  }

  static void clear() {
    _directions.clear();
  }

  static List<String> getNodeIdsWithDirections() {
    return _directions.keys.where((id) => _directions[id]!.isNotEmpty).toList();
  }

  static Map<String, dynamic> exportToJson() {
    final data = <String, dynamic>{};
    for (final entry in _directions.entries) {
      if (entry.value.isNotEmpty) {
        data[entry.key] =
            entry.value.values.map((d) => d.toJson()).toList();
      }
    }
    return data;
  }

  static void importFromJson(Map<String, dynamic> json) {
    _directions.clear();
    for (final entry in json.entries) {
      final directions = (entry.value as List)
          .map((e) => ConnectionDirection.fromJson(e as Map<String, dynamic>))
          .toList();
      final map = <String, ConnectionDirection>{};
      for (final d in directions) {
        map[d.targetNodeId] = d;
      }
      _directions[entry.key] = map;
    }
    _save();
  }

  /// Restaura las direcciones guardadas en `PlatformStorage` (localStorage web).
  static Future<void> loadPersisted() async {
    final storage = PlatformStorage.instance;
    final json = await storage.readJson(_storageKey);
    if (json == null) return;
    importFromJson(json);
  }

  static void _save() {
    PlatformStorage.instance.writeJson(_storageKey, exportToJson());
  }
}