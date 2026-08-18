import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:campus_domain/models/campus_model.dart';
import 'package:campus_domain/models/building_model.dart';
import 'package:campus_domain/models/floor_model.dart';
import 'package:campus_domain/models/zone_model.dart';
import 'package:campus_domain/models/node_model.dart';

class CampusValidationError extends Equatable {
  final String field;
  final String message;
  final String severity;

  const CampusValidationError({
    required this.field,
    required this.message,
    this.severity = 'error',
  });

  @override
  List<Object?> get props => [field, message, severity];
}

class SearchResult extends Equatable {
  final NodeModel? node;
  final ZoneModel? zone;
  final FloorModel? floor;
  final BuildingModel? building;
  final String matchType;

  const SearchResult({
    this.node,
    this.zone,
    this.floor,
    this.building,
    required this.matchType,
  });

  @override
  List<Object?> get props => [node, zone, floor, building, matchType];
}

class RouteResult extends Equatable {
  final List<ZoneModel> zonePath;
  final List<NodeModel> nodePath;
  final String? error;

  const RouteResult({
    this.zonePath = const [],
    this.nodePath = const [],
    this.error,
  });

  bool get hasError => error != null;
  bool get isSuccess => error == null && nodePath.isNotEmpty;

  @override
  List<Object?> get props => [zonePath, nodePath, error];
}

class CampusRepository {
  CampusModel _campus;
  final List<CampusValidationError> _validationErrors = [];

  CampusRepository(this._campus);

  CampusModel get campus => _campus;
  List<CampusValidationError> get validationErrors =>
      List.unmodifiable(_validationErrors);

  void updateCampus(CampusModel campus) {
    _campus = campus;
    _validate();
  }

  // ═══════════════════════════════════════════
  // HIERARCHICAL SEARCH
  // ═══════════════════════════════════════════

  SearchResult? searchByNodeId(String nodeId) {
    final node = _campus.getNode(nodeId);
    if (node == null) return null;

    ZoneModel? zone;
    FloorModel? floor;
    BuildingModel? building;

    if (node.zoneId != null) {
      zone = _campus.getZone(node.zoneId!);
      if (zone != null) {
        floor = _campus.getFloor(zone.floorId);
        if (floor != null) {
          building = _campus.getBuilding(floor.buildingId);
        }
      }
    }

    return SearchResult(
      node: node,
      zone: zone,
      floor: floor,
      building: building,
      matchType: 'node_id',
    );
  }

  List<SearchResult> searchByName(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final results = <SearchResult>[];

    for (final node in _campus.nodes) {
      if (_matchesQuery(node.name, q) ||
          _matchesQuery(node.description, q) ||
          _matchesQuery(node.id, q) ||
          (node.destinationLabel != null && _matchesQuery(node.destinationLabel!, q))) {
        ZoneModel? zone;
        FloorModel? floor;
        BuildingModel? building;

        if (node.zoneId != null) {
          zone = _campus.getZone(node.zoneId!);
          if (zone != null) {
            floor = _campus.getFloor(zone.floorId);
            if (floor != null) {
              building = _campus.getBuilding(floor.buildingId);
            }
          }
        }

        results.add(SearchResult(
          node: node,
          zone: zone,
          floor: floor,
          building: building,
          matchType: 'node_name',
        ));
      }
    }

    for (final zone in _campus.zones) {
      if (_matchesQuery(zone.name, q) || _matchesQuery(zone.description, q)) {
        FloorModel? floor;
        BuildingModel? building;
        floor = _campus.getFloor(zone.floorId);
        if (floor != null) {
          building = _campus.getBuilding(floor.buildingId);
        }

        results.add(SearchResult(
          zone: zone,
          floor: floor,
          building: building,
          matchType: 'zone',
        ));
      }
    }

    return results;
  }

  bool _matchesQuery(String text, String query) {
    return text.toLowerCase().contains(query);
  }

  // ═══════════════════════════════════════════
  // ZONE-LEVEL ROUTING
  // ═══════════════════════════════════════════

  RouteResult findRoute(String startNodeId, String endNodeId) {
    final startResult = searchByNodeId(startNodeId);
    final endResult = searchByNodeId(endNodeId);

    if (startResult == null) {
      return const RouteResult(error: 'El nodo de inicio no existe. Verificalo en Admin.');
    }
    if (endResult == null) {
      return const RouteResult(error: 'El nodo de destino no existe. Verificalo en Admin.');
    }

    if (startResult.zone == null) {
      return RouteResult(error: 'El nodo "${startResult.node!.name}" no pertenece a ninguna zona. Asignalo a una zona en Admin → Estructura → toca el nodo → Editar → Zona.');
    }
    if (endResult.zone == null) {
      return RouteResult(error: 'El nodo "${endResult.node!.name}" no pertenece a ninguna zona. Asignalo a una zona en Admin → Estructura → toca el nodo → Editar → Zona.');
    }

    if (startResult.zone!.id == endResult.zone!.id) {
      final path = _findNodeOnlyRoute(startNodeId, endNodeId);
      if (path.isEmpty) {
        return RouteResult(error: 'No se encontro ruta dentro de la zona "${startResult.zone!.name}". Los nodos "${startResult.node!.name}" y "${endResult.node!.name}" no estan conectados entre si. Conectalos en Admin → Estructura → toca el nodo → Conexiones.');
      }
      return RouteResult(zonePath: [startResult.zone!], nodePath: path);
    }

    final zonePath = _findZonePath(startResult.zone!.id, endResult.zone!.id);
    if (zonePath.isEmpty) {
      final startZoneName = startResult.zone!.name;
      final endZoneName = endResult.zone!.name;
      final connectedStart = startResult.zone!.connectedZoneIds.isEmpty
          ? 'no tiene conexiones con otras zonas'
          : 'solo se conecta con: ${startResult.zone!.connectedZoneIds.join(", ")}';
      return RouteResult(error: 'No hay ruta entre las zonas "$startZoneName" y "$endZoneName". La zona "$startZoneName" $connectedStart. Conecta las zonas en Admin → Estructura → toca la zona → Conexiones.');
    }

    final nodePath = _buildNodePath(zonePath, startNodeId, endNodeId);
    if (nodePath.isEmpty) {
      return RouteResult(error: 'No se encontro ruta entre los nodos dentro de las zonas. Verifica que los nodos de entrada/salida de cada zona esten correctamente asignados.');
    }

    return RouteResult(zonePath: zonePath, nodePath: nodePath);
  }

  List<ZoneModel> _findZonePath(String startZoneId, String endZoneId) {
    final visited = <String>{};
    final queue = <List<ZoneModel>>[];

    final startZone = _campus.getZone(startZoneId);
    if (startZone == null) return [];

    queue.add([startZone]);
    visited.add(startZoneId);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current.id == endZoneId) return path;

      for (final neighborId in current.connectedZoneIds) {
        if (!visited.contains(neighborId)) {
          visited.add(neighborId);
          final neighbor = _campus.getZone(neighborId);
          if (neighbor != null) {
            queue.add([...path, neighbor]);
          }
        }
      }
    }

    return [];
  }

  List<NodeModel> _buildNodePath(
    List<ZoneModel> zonePath,
    String startNodeId,
    String endNodeId,
  ) {
    final fullPath = <NodeModel>[];

    for (int i = 0; i < zonePath.length; i++) {
      final zone = zonePath[i];
      final zoneNodes = _campus.getNodesForZone(zone.id);

      if (i == 0) {
        final startNode = _campus.getNode(startNodeId);
        if (startNode != null) {
          fullPath.add(startNode);
        }
        final exitNode = zone.exitNodeId != null
            ? _campus.getNode(zone.exitNodeId!)
            : null;
        if (exitNode != null && exitNode.id != startNodeId) {
          final pathToExit = _findNodePathInZone(zone.id, startNodeId, exitNode.id);
          if (pathToExit.length > 1) {
            fullPath.addAll(pathToExit.sublist(1));
          }
        }
      } else if (i == zonePath.length - 1) {
        final entryNode = zone.entryNodeId != null
            ? _campus.getNode(zone.entryNodeId!)
            : null;
        if (entryNode != null) {
          final pathToDest = _findNodePathInZone(zone.id, entryNode.id, endNodeId);
          if (pathToDest.isNotEmpty) {
            fullPath.addAll(pathToDest);
          }
        } else if (zoneNodes.isNotEmpty) {
          final pathToDest = _findNodePathInZone(zone.id, zoneNodes.first.id, endNodeId);
          if (pathToDest.isNotEmpty) {
            fullPath.addAll(pathToDest);
          }
        }
      } else {
        final entryNode = zone.entryNodeId != null
            ? _campus.getNode(zone.entryNodeId!)
            : zoneNodes.isNotEmpty
                ? zoneNodes.first
                : null;
        final exitNode = zone.exitNodeId != null
            ? _campus.getNode(zone.exitNodeId!)
            : zoneNodes.isNotEmpty
                ? zoneNodes.last
                : null;

        if (entryNode != null && exitNode != null && entryNode.id != exitNode.id) {
          final pathThrough = _findNodePathInZone(zone.id, entryNode.id, exitNode.id);
          if (pathThrough.length > 1) {
            fullPath.addAll(pathThrough.sublist(1));
          }
        } else if (entryNode != null) {
          fullPath.add(entryNode);
        }
      }
    }

    return fullPath;
  }

  List<NodeModel> _findNodePathInZone(String zoneId, String startId, String endId) {
    final zoneNodes = _campus.getNodesForZone(zoneId);
    final zoneNodeIds = zoneNodes.map((n) => n.id).toSet();

    final visited = <String>{};
    final queue = <List<NodeModel>>[];

    final startNode = _campus.getNode(startId);
    if (startNode == null) return [];

    queue.add([startNode]);
    visited.add(startId);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current.id == endId) return path;

      for (final neighborId in current.connectedNodeIds) {
        if (!visited.contains(neighborId)) {
          visited.add(neighborId);
          final neighbor = _campus.getNode(neighborId);
          if (neighbor != null && (zoneNodeIds.contains(neighborId) || neighborId == endId)) {
            queue.add([...path, neighbor]);
          }
        }
      }
    }

    return [];
  }

  List<NodeModel> _findNodeOnlyRoute(String startId, String endId) {
    final visited = <String>{};
    final queue = <List<NodeModel>>[];

    final startNode = _campus.getNode(startId);
    if (startNode == null) return [];

    queue.add([startNode]);
    visited.add(startId);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current.id == endId) return path;

      for (final neighborId in current.connectedNodeIds) {
        if (!visited.contains(neighborId)) {
          visited.add(neighborId);
          final neighbor = _campus.getNode(neighborId);
          if (neighbor != null) {
            queue.add([...path, neighbor]);
          }
        }
      }
    }

    return [];
  }

  // ═══════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════

  void addBuilding(BuildingModel building) {
    _campus = _campus.copyWith(
      buildings: [..._campus.buildings, building],
    );
  }

  void addFloor(FloorModel floor) {
    _campus = _campus.copyWith(
      floors: [..._campus.floors, floor],
    );
    final building = _campus.getBuilding(floor.buildingId);
    if (building != null) {
      final updated = building.copyWith(
        floorIds: [...building.floorIds, floor.id],
      );
      _updateBuilding(updated);
    }
  }

  void updateFloor(FloorModel floor) {
    final existing = _campus.getFloor(floor.id);
    if (existing == null) return;

    if (floor.buildingId != existing.buildingId) {
      final oldBuilding = _campus.getBuilding(existing.buildingId);
      if (oldBuilding != null) {
        _updateBuilding(oldBuilding.copyWith(
          floorIds: oldBuilding.floorIds.where((id) => id != floor.id).toList(),
        ));
      }
      final newBuilding = _campus.getBuilding(floor.buildingId);
      if (newBuilding != null && !newBuilding.floorIds.contains(floor.id)) {
        _updateBuilding(newBuilding.copyWith(
          floorIds: [...newBuilding.floorIds, floor.id],
        ));
      }
    }

    for (final zone in _campus.zones) {
      if (zone.floorId == floor.id && zone.buildingId != floor.buildingId) {
        _updateZone(zone.copyWith(buildingId: floor.buildingId));
      }
    }

    _updateFloor(floor);
  }

  void removeFloor(String floorId) {
    final floor = _campus.getFloor(floorId);
    if (floor == null) return;

    for (final zoneId in List.of(floor.zoneIds)) {
      removeZone(zoneId);
    }

    final building = _campus.getBuilding(floor.buildingId);
    if (building != null) {
      final updated = building.copyWith(
        floorIds: building.floorIds.where((id) => id != floorId).toList(),
      );
      _updateBuilding(updated);
    }

    _campus = _campus.copyWith(
      floors: _campus.floors.where((f) => f.id != floorId).toList(),
    );
  }

  void addZone(ZoneModel zone) {
    _campus = _campus.copyWith(
      zones: [..._campus.zones, zone],
    );
    final floor = _campus.getFloor(zone.floorId);
    if (floor != null) {
      final updated = floor.copyWith(
        zoneIds: [...floor.zoneIds, zone.id],
      );
      _updateFloor(updated);
    }
    _syncZoneConnections(zone);
  }

  void addNode(NodeModel node) {
    _campus = _campus.copyWith(
      nodes: [..._campus.nodes, node],
    );
    if (node.zoneId != null) {
      final zone = _campus.getZone(node.zoneId!);
      if (zone != null) {
        var updated = zone.copyWith(nodeIds: [...zone.nodeIds, node.id]);
        // Auto-assign entry/exit so the zone is navigable right away.
        if (!zone.hasEntry) updated = updated.copyWith(entryNodeId: node.id);
        if (!zone.hasExit) updated = updated.copyWith(exitNodeId: node.id);
        _updateZone(updated);
      }
    }
    _syncNodeConnections(node);
  }

  void updateNode(NodeModel node) {
    final existing = _campus.getNode(node.id);
    if (existing == null) return;

    // Remove this node from connections that were dropped.
    for (final other in _campus.nodes) {
      if (other.id == node.id) continue;
      final stillConnected = node.connectedNodeIds.contains(other.id);
      final hadConnection = other.connectedNodeIds.contains(node.id);
      if (!stillConnected && hadConnection) {
        _replaceNode(other.copyWith(
          connectedNodeIds: other.connectedNodeIds
              .where((id) => id != node.id)
              .toList(),
        ));
      }
    }

    _replaceNode(node);
    _syncNodeConnections(node);
  }

  void updateZone(ZoneModel zone) {
    final existing = _campus.getZone(zone.id);
    if (existing == null) return;

    // Remove this zone from connections that were dropped.
    for (final other in _campus.zones) {
      if (other.id == zone.id) continue;
      final stillConnected = zone.connectedZoneIds.contains(other.id);
      final hadConnection = other.connectedZoneIds.contains(zone.id);
      if (!stillConnected && hadConnection) {
        _updateZone(other.copyWith(
          connectedZoneIds: other.connectedZoneIds
              .where((id) => id != zone.id)
              .toList(),
        ));
      }
    }

    _updateZone(zone);
    _syncZoneConnections(zone);
  }

  void removeNode(String nodeId) {
    final node = _campus.getNode(nodeId);
    if (node != null && node.zoneId != null) {
      final zone = _campus.getZone(node.zoneId!);
      if (zone != null) {
        final remaining = zone.nodeIds.where((id) => id != nodeId).toList();
        var updatedZone = zone.copyWith(nodeIds: remaining);
        // Reassign entry/exit so the zone stays navigable.
        if (zone.entryNodeId == nodeId) {
          updatedZone = updatedZone.copyWith(
            entryNodeId: remaining.isNotEmpty ? remaining.first : null,
          );
        }
        if (zone.exitNodeId == nodeId) {
          updatedZone = updatedZone.copyWith(
            exitNodeId: remaining.isNotEmpty ? remaining.first : null,
          );
        }
        _updateZone(updatedZone);
      }
    }

    _campus = _campus.copyWith(
      nodes: _campus.nodes.where((n) => n.id != nodeId).toList(),
    );

    for (final n in _campus.nodes) {
      if (n.connectedNodeIds.contains(nodeId)) {
        final updated = n.copyWith(
          connectedNodeIds: n.connectedNodeIds.where((id) => id != nodeId).toList(),
        );
        updateNode(updated);
      }
    }
  }

  void removeZone(String zoneId) {
    final zone = _campus.getZone(zoneId);
    if (zone != null) {
      for (final nodeId in zone.nodeIds) {
        removeNode(nodeId);
      }
      final floor = _campus.getFloor(zone.floorId);
      if (floor != null) {
        _updateFloor(floor.copyWith(
          zoneIds: floor.zoneIds.where((id) => id != zoneId).toList(),
        ));
      }
    }

    _campus = _campus.copyWith(
      zones: _campus.zones.where((z) => z.id != zoneId).toList(),
    );

    for (final z in _campus.zones) {
      if (z.connectedZoneIds.contains(zoneId)) {
        final updated = z.copyWith(
          connectedZoneIds: z.connectedZoneIds.where((id) => id != zoneId).toList(),
        );
        _updateZone(updated);
      }
    }
  }

  void _updateZone(ZoneModel zone) {
    final index = _campus.zones.indexWhere((z) => z.id == zone.id);
    if (index >= 0) {
      final zones = List<ZoneModel>.from(_campus.zones);
      zones[index] = zone;
      _campus = _campus.copyWith(zones: zones);
    }
  }

  void _updateFloor(FloorModel floor) {
    final index = _campus.floors.indexWhere((f) => f.id == floor.id);
    if (index >= 0) {
      final floors = List<FloorModel>.from(_campus.floors);
      floors[index] = floor;
      _campus = _campus.copyWith(floors: floors);
    }
  }

  void _updateBuilding(BuildingModel building) {
    final index = _campus.buildings.indexWhere((b) => b.id == building.id);
    if (index >= 0) {
      final buildings = List<BuildingModel>.from(_campus.buildings);
      buildings[index] = building;
      _campus = _campus.copyWith(buildings: buildings);
    }
  }

  void _replaceNode(NodeModel node) {
    final index = _campus.nodes.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      final nodes = List<NodeModel>.from(_campus.nodes);
      nodes[index] = node;
      _campus = _campus.copyWith(nodes: nodes);
    }
  }

  /// Keeps node links bidirectional: every neighbor of [node] also lists it.
  void _syncNodeConnections(NodeModel node) {
    for (final connectedId in node.connectedNodeIds) {
      final connected = _campus.getNode(connectedId);
      if (connected != null && !connected.connectedNodeIds.contains(node.id)) {
        _replaceNode(connected.copyWith(
          connectedNodeIds: [...connected.connectedNodeIds, node.id],
        ));
      }
    }
  }

  /// Keeps zone links bidirectional: every connected zone also lists it.
  void _syncZoneConnections(ZoneModel zone) {
    for (final connectedId in zone.connectedZoneIds) {
      final connected = _campus.getZone(connectedId);
      if (connected != null && !connected.connectedZoneIds.contains(zone.id)) {
        _updateZone(connected.copyWith(
          connectedZoneIds: [...connected.connectedZoneIds, zone.id],
        ));
      }
    }
  }

  // ═══════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════

  List<CampusValidationError> validate() {
    _validationErrors.clear();
    _validate();
    return List.unmodifiable(_validationErrors);
  }

  void _validate() {
    _validationErrors.clear();

    // Check: nodes without any connections (isolated nodes)
    for (final node in _campus.nodes) {
      if (node.connectedNodeIds.isEmpty) {
        _validationErrors.add(CampusValidationError(
          field: 'node.${node.id}.connectedNodeIds',
          message: 'El nodo "${node.name}" (${node.id}) no tiene conexiones. Conectalo a al menos un nodo vecino en Admin → Estructura → toca el nodo → Editar → Conexiones.',
          severity: 'error',
        ));
      }
    }

    // Check: zones without entry or exit nodes
    for (final zone in _campus.zones) {
      if (zone.hasNodes && zone.entryNodeId == null) {
        _validationErrors.add(CampusValidationError(
          field: 'zone.${zone.id}.entryNodeId',
          message: 'La zona "${zone.name}" no tiene nodo de entrada (entryNodeId). Asignalo en Admin → Estructura → toca la zona → Editar.',
          severity: 'error',
        ));
      }
      if (zone.hasNodes && zone.exitNodeId == null) {
        _validationErrors.add(CampusValidationError(
          field: 'zone.${zone.id}.exitNodeId',
          message: 'La zona "${zone.name}" no tiene nodo de salida (exitNodeId). Asignalo en Admin → Estructura → toca la zona → Editar.',
          severity: 'error',
        ));
      }
    }

    // Check: zones not connected to any other zone (orphan zones)
    for (final zone in _campus.zones) {
      if (zone.connectedZoneIds.isEmpty && _campus.zones.length > 1) {
        _validationErrors.add(CampusValidationError(
          field: 'zone.${zone.id}.connectedZoneIds',
          message: 'La zona "${zone.name}" no esta conectada a ninguna otra zona. Las rutas no podran pasar por esta zona. Conectala en Admin → Estructura → toca la zona → Conexiones.',
          severity: 'warning',
        ));
      }
    }

    // Check: floors without zones
    for (final floor in _campus.floors) {
      if (floor.zoneIds.isEmpty) {
        _validationErrors.add(CampusValidationError(
          field: 'floor.${floor.id}.zoneIds',
          message: 'El piso "${floor.name}" no tiene zonas creadas. Agrega al menos una zona en Admin → Agregar → Zona.',
          severity: 'warning',
        ));
      }
    }

    // Check: zones without nodes
    for (final zone in _campus.zones) {
      if (zone.nodeIds.isEmpty) {
        _validationErrors.add(CampusValidationError(
          field: 'zone.${zone.id}.nodeIds',
          message: 'La zona "${zone.name}" no tiene nodos. Agrega al menos un nodo en Admin → Agregar → Nodo.',
          severity: 'warning',
        ));
      }
    }

    final nodeIds = _campus.nodes.map((n) => n.id).toSet();
    final zoneIds = _campus.zones.map((z) => z.id).toSet();
    final floorIds = _campus.floors.map((f) => f.id).toSet();

    for (final node in _campus.nodes) {
      if (node.zoneId != null && !zoneIds.contains(node.zoneId)) {
        _validationErrors.add(CampusValidationError(
          field: 'node.${node.id}.zoneId',
          message: 'El nodo "${node.name}" referencia zona inexistente: ${node.zoneId}',
          severity: 'error',
        ));
      }

      for (final connId in node.connectedNodeIds) {
        if (!nodeIds.contains(connId)) {
          _validationErrors.add(CampusValidationError(
            field: 'node.${node.id}.connectedNodeIds',
            message: 'El nodo "${node.name}" referencia nodo inexistente: $connId',
            severity: 'error',
          ));
        }
      }
    }

    for (final zone in _campus.zones) {
      if (!floorIds.contains(zone.floorId)) {
        _validationErrors.add(CampusValidationError(
          field: 'zone.${zone.id}.floorId',
          message: 'La zona "${zone.name}" referencia piso inexistente: ${zone.floorId}',
          severity: 'error',
        ));
      }

      for (final connId in zone.connectedZoneIds) {
        if (!zoneIds.contains(connId)) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.connectedZoneIds',
            message: 'La zona "${zone.name}" referencia zona inexistente: $connId',
            severity: 'error',
          ));
        }
      }
    }

    for (final floor in _campus.floors) {
      if (!_campus.buildings.any((b) => b.id == floor.buildingId)) {
        _validationErrors.add(CampusValidationError(
          field: 'floor.${floor.id}.buildingId',
          message: 'El piso "${floor.name}" referencia edificio inexistente: ${floor.buildingId}',
          severity: 'error',
        ));
      }
    }

    // Check: asymmetric (one-way) node connections
    for (final node in _campus.nodes) {
      for (final connId in node.connectedNodeIds) {
        final other = _campus.getNode(connId);
        if (other != null && !other.connectedNodeIds.contains(node.id)) {
          _validationErrors.add(CampusValidationError(
            field: 'node.${node.id}.connectedNodeIds',
            message: 'La conexión "${node.id} ↔ $connId" es unidireccional. Edita "${node.name}" en Admin → Estructura → toca el nodo → Conexiones para hacerla bidireccional.',
            severity: 'error',
          ));
        }
      }
    }

    // Check: zone entry/exit nodes exist and belong to the zone
    for (final zone in _campus.zones) {
      if (zone.entryNodeId != null && zone.entryNodeId!.isNotEmpty) {
        final refId = zone.entryNodeId!;
        final n = _campus.getNode(refId);
        if (n == null) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.entryNodeId',
            message: 'La zona "${zone.name}" referencia un nodo de entrada inexistente: $refId',
            severity: 'error',
          ));
        } else if (!zone.nodeIds.contains(refId)) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.entryNodeId',
            message: 'El nodo de entrada "${n.name}" ($refId) de la zona "${zone.name}" no pertenece a la zona. Edita la zona o el nodo en Admin → Estructura.',
            severity: 'error',
          ));
        }
      }
      if (zone.exitNodeId != null && zone.exitNodeId!.isNotEmpty) {
        final refId = zone.exitNodeId!;
        final n = _campus.getNode(refId);
        if (n == null) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.exitNodeId',
            message: 'La zona "${zone.name}" referencia un nodo de salida inexistente: $refId',
            severity: 'error',
          ));
        } else if (!zone.nodeIds.contains(refId)) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.exitNodeId',
            message: 'El nodo de salida "${n.name}" ($refId) de la zona "${zone.name}" no pertenece a la zona. Edita la zona o el nodo en Admin → Estructura.',
            severity: 'error',
          ));
        }
      }
    }

    // Check: zone.nodeIds membership consistency
    for (final zone in _campus.zones) {
      for (final nid in zone.nodeIds) {
        final n = _campus.getNode(nid);
        if (n == null) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.nodeIds',
            message: 'La zona "${zone.name}" referencia un nodo inexistente: $nid',
            severity: 'error',
          ));
        } else if (n.zoneId != zone.id) {
          _validationErrors.add(CampusValidationError(
            field: 'zone.${zone.id}.nodeIds',
            message: 'El nodo "$nid" aparece en la zona "${zone.name}" pero pertenece a otra zona. Edita el nodo en Admin → Estructura para corregir su zona.',
            severity: 'error',
          ));
        }
      }
    }

    // Check: floor references existing zones
    for (final floor in _campus.floors) {
      for (final zid in floor.zoneIds) {
        if (!zoneIds.contains(zid)) {
          _validationErrors.add(CampusValidationError(
            field: 'floor.${floor.id}.zoneIds',
            message: 'El piso "${floor.name}" referencia una zona inexistente: $zid',
            severity: 'error',
          ));
        }
      }
    }

    final nodeDuplicates = _findDuplicates(_campus.nodes.map((n) => n.id).toList());
    for (final dup in nodeDuplicates) {
      _validationErrors.add(CampusValidationError(
        field: 'node.$dup',
        message: 'ID de nodo duplicado: $dup',
        severity: 'error',
      ));
    }

    final zoneDuplicates = _findDuplicates(_campus.zones.map((z) => z.id).toList());
    for (final dup in zoneDuplicates) {
      _validationErrors.add(CampusValidationError(
        field: 'zone.$dup',
        message: 'ID de zona duplicado: $dup',
        severity: 'error',
      ));
    }
  }

  List<String> _findDuplicates(List<String> ids) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) duplicates.add(id);
    }
    return duplicates.toList();
  }

  /// Returns a human-readable health report of the campus
  String getHealthReport() {
    final errors = validate();
    if (errors.isEmpty) return 'Todo correcto. El campus esta listo para navegar.';

    final buffer = StringBuffer();
    buffer.writeln('Se encontraron ${errors.length} problema(s):');
    buffer.writeln('');

    final errs = errors.where((e) => e.severity == 'error').toList();
    final warns = errors.where((e) => e.severity == 'warning').toList();

    if (errs.isNotEmpty) {
      buffer.writeln('ERRORES (${errs.length}) - Deben corregirse:');
      for (int i = 0; i < errs.length; i++) {
        buffer.writeln('${i + 1}. ${errs[i].message}');
      }
      buffer.writeln('');
    }

    if (warns.isNotEmpty) {
      buffer.writeln('ADVERTENCIAS (${warns.length}) - Recomendado corregir:');
      for (int i = 0; i < warns.length; i++) {
        buffer.writeln('${i + 1}. ${warns[i].message}');
      }
    }

    return buffer.toString();
  }

  // ═══════════════════════════════════════════
  // JSON EXPORT/IMPORT
  // ═══════════════════════════════════════════

  String exportToJson({bool pretty = true}) {
    final data = _campus.toJson();
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    }
    return json.encode(data);
  }

  static CampusModel importFromJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return CampusModel.fromJson(data);
  }

  static CampusRepository fromJson(String jsonString) {
    return CampusRepository(importFromJson(jsonString));
  }
}