import 'package:campus_domain/campus_domain.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

/// Resultado de resolver un código QR escaneado a una ubicación del campus.
class QrLocationResult {
  /// Nodo concreto donde se posiciona al usuario.
  final NodeModel node;

  /// Etiqueta legible de lo escaneado (edificio/piso/zona/nodo).
  final String locationLabel;

  /// Identificador del código QR escaneado.
  final String qrId;

  const QrLocationResult({
    required this.node,
    required this.locationLabel,
    required this.qrId,
  });
}

/// Resuelve un código QR escaneado a un punto concreto del campus.
///
/// Cada QR lleva DOS identificadores (`id` y `name`): si el `id` no existe se
/// intenta por `name`, y viceversa.
///
/// - Nodo (`N`)     → el propio nodo.
/// - Zona (`Z`)     → nodo de entrada de la zona (o su primer nodo).
/// - Piso (`F`)     → primer nodo del piso (zona de menor orden).
/// - Edificio (`B`) → primer nodo de su primer piso.
class QrLocationResolver {
  QrLocationResolver._();

  static QrLocationResult? resolve(CampusQrReference ref) {
    final campus = MockCampusData.campus;

    switch (ref.type) {
      case CampusQrEntityType.node:
        return _resolveNode(ref, campus);

      case CampusQrEntityType.zone:
        return _resolveZone(ref, campus);

      case CampusQrEntityType.floor:
        return _resolveFloor(ref, campus);

      case CampusQrEntityType.building:
        return _resolveBuilding(ref, campus);
    }
  }

  static QrLocationResult? _resolveNode(
    CampusQrReference ref,
    CampusModel campus,
  ) {
    NodeModel? node = _nodeByIdOrName(ref.id, ref.name, campus);
    if (node == null) return null;
    return QrLocationResult(
      node: node,
      locationLabel: node.name,
      qrId: node.id,
    );
  }

  static QrLocationResult? _resolveZone(
    CampusQrReference ref,
    CampusModel campus,
  ) {
    final zone = _zoneByIdOrName(ref.id, ref.name, campus);
    if (zone == null) return null;

    String? nodeId = zone.entryNodeId;
    if (nodeId == null && zone.nodeIds.isNotEmpty) nodeId = zone.nodeIds.first;
    final node = nodeId == null ? null : campus.getNode(nodeId);

    if (node == null) return null;
    return QrLocationResult(
      node: node,
      locationLabel: '${zone.name} · Piso ${_floorLabel(zone.floorId, campus)}',
      qrId: zone.id,
    );
  }

  static QrLocationResult? _resolveFloor(
    CampusQrReference ref,
    CampusModel campus,
  ) {
    final floor = _floorByIdOrName(ref.id, ref.name, campus);
    if (floor == null) return null;

    final zones = campus.getZonesForFloor(floor.id).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final zone in zones) {
      String? nodeId = zone.entryNodeId;
      if (nodeId == null && zone.nodeIds.isNotEmpty) {
        nodeId = zone.nodeIds.first;
      }
      final node = nodeId == null ? null : campus.getNode(nodeId);
      if (node != null) {
        return QrLocationResult(
          node: node,
          locationLabel: '${floor.name} (${floor.id})',
          qrId: floor.id,
        );
      }
    }
    return null;
  }

  static QrLocationResult? _resolveBuilding(
    CampusQrReference ref,
    CampusModel campus,
  ) {
    final building = _buildingByIdOrName(ref.id, ref.name, campus);
    if (building == null) return null;

    final floors = campus.getFloorsForBuilding(building.id).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    for (final floor in floors) {
      final resolvedFloor = _resolveFloor(
        CampusQrReference(
          type: CampusQrEntityType.floor,
          id: floor.id,
          name: floor.name,
        ),
        campus,
      );
      if (resolvedFloor != null) {
        return QrLocationResult(
          node: resolvedFloor.node,
          locationLabel: building.name,
          qrId: building.id,
        );
      }
    }
    return null;
  }

  // ═══ Búsqueda por id o nombre ═══

  static NodeModel? _nodeByIdOrName(String id, String name, CampusModel campus) {
    final byId = campus.getNode(id);
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = name.toLowerCase().trim();
    for (final node in campus.nodes) {
      if (node.name.toLowerCase().trim() == normalized ||
          node.destinationLabel?.toLowerCase().trim() == normalized) {
        return node;
      }
    }
    return null;
  }

  static ZoneModel? _zoneByIdOrName(String id, String name, CampusModel campus) {
    final byId = campus.getZone(id);
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = name.toLowerCase().trim();
    for (final zone in campus.zones) {
      if (zone.name.toLowerCase().trim() == normalized) return zone;
    }
    return null;
  }

  static FloorModel? _floorByIdOrName(String id, String name, CampusModel campus) {
    final byId = campus.getFloor(id);
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = name.toLowerCase().trim();
    for (final floor in campus.floors) {
      if (floor.name.toLowerCase().trim() == normalized) return floor;
    }
    return null;
  }

  static BuildingModel? _buildingByIdOrName(
    String id,
    String name,
    CampusModel campus,
  ) {
    final byId = campus.getBuilding(id);
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = name.toLowerCase().trim();
    for (final building in campus.buildings) {
      if (building.name.toLowerCase().trim() == normalized) return building;
    }
    return null;
  }

  static String _floorLabel(String floorId, CampusModel campus) {
    final floor = campus.getFloor(floorId);
    return floor?.name ?? floorId;
  }
}