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
/// intenta por `name`, y viceversa. La búsqueda por nombre normaliza acentos,
/// mayúsculas y espacios para tolerar diferencias menores entre el dato
/// publicado y el escaneado.
///
/// - Nodo (`N`)     → el propio nodo (también por `panoramaId`, que es como el
///   backend asocia imagen/overlay de cada instancia física).
/// - Zona (`Z`)     → nodo de entrada de la zona; si no existe, primer nodo
///   disponible de la zona; si tampoco, un nodo del mismo piso.
/// - Piso (`F`)     → primer nodo del piso (zona de menor orden); si no hay,
///   primer nodo que declare ese piso.
/// - Edificio (`B`) → primer nodo de su primer piso; si no hay, primer nodo del
///   edificio.
class QrLocationResolver {
  QrLocationResolver._();

  /// [campus] permite inyectar datos en tests; por defecto usa el campus que la
  /// app tiene sincronizado (backend de push o datos locales).
  static QrLocationResult? resolve(
    CampusQrReference ref, {
    CampusModel? campus,
  }) {
    final model = campus ?? MockCampusData.campus;

    switch (ref.type) {
      case CampusQrEntityType.node:
        return _resolveNode(ref, model);

      case CampusQrEntityType.zone:
        return _resolveZone(ref, model);

      case CampusQrEntityType.floor:
        return _resolveFloor(ref, model);

      case CampusQrEntityType.building:
        return _resolveBuilding(ref, model);
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

    final node = _firstAvailableNodeForZone(zone, campus);
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
      final node = _firstAvailableNodeForZone(zone, campus);
      if (node != null) {
        return QrLocationResult(
          node: node,
          locationLabel: '${floor.name} (${floor.id})',
          qrId: floor.id,
        );
      }
    }

    final floorNode = _firstNodeForFloor(floor, campus);
    if (floorNode != null) {
      return QrLocationResult(
        node: floorNode,
        locationLabel: '${floor.name} (${floor.id})',
        qrId: floor.id,
      );
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

    for (final node in campus.nodes) {
      if (node.buildingId == building.id) {
        return QrLocationResult(
          node: node,
          locationLabel: building.name,
          qrId: building.id,
        );
      }
    }

    return null;
  }

  /// Devuelve el primer nodo disponible de una zona: entrada → primer `nodeId`
  /// existente → primer nodo que declara `zoneId` → primer nodo de otro nodo
  /// del mismo piso.
  static NodeModel? _firstAvailableNodeForZone(
    ZoneModel zone,
    CampusModel campus,
  ) {
    NodeModel? node;
    final entryId = zone.entryNodeId;
    if (entryId != null && entryId.isNotEmpty) {
      node = campus.getNode(entryId);
      if (node != null) return node;
    }

    for (final candidate in zone.nodeIds) {
      node = campus.getNode(candidate);
      if (node != null) return node;
    }

    final byZone = campus.getNodesForZone(zone.id);
    if (byZone.isNotEmpty) return byZone.first;

    final floorZoneIds =
        campus.getZonesForFloor(zone.floorId).map((z) => z.id).toSet();
    for (final candidate in campus.nodes) {
      if (candidate.zoneId != null && floorZoneIds.contains(candidate.zoneId)) {
        return candidate;
      }
    }

    return null;
  }

  /// Primer nodo que declara este piso (por id de piso, nivel o nombre).
  static NodeModel? _firstNodeForFloor(FloorModel floor, CampusModel campus) {
    for (final node in campus.nodes) {
      final level = node.floorLevel?.trim() ?? '';
      if (level == floor.id ||
          level == '${floor.level}' ||
          _normalize(level) == _normalize(floor.name)) {
        return node;
      }
    }
    return null;
  }

  // ═══ Búsqueda por id o nombre normalizado ═══

  static NodeModel? _nodeByIdOrName(String id, String name, CampusModel campus) {
    final trimmedId = id.trim();
    final byId = campus.getNode(trimmedId);
    if (byId != null) return byId;

    // Las instancias físicas del backend se indexan por nodeId Y panoramaId.
    if (trimmedId.isNotEmpty) {
      for (final node in campus.nodes) {
        if (node.panoramaId.trim() == trimmedId) return node;
      }
    }

    if (name.isEmpty) return null;

    final normalized = _normalize(name);
    for (final node in campus.nodes) {
      if (_normalize(node.name) == normalized ||
          _normalize(node.destinationLabel ?? '') == normalized) {
        return node;
      }
    }
    return null;
  }

  static ZoneModel? _zoneByIdOrName(String id, String name, CampusModel campus) {
    final byId = campus.getZone(id.trim());
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = _normalize(name);
    for (final zone in campus.zones) {
      if (_normalize(zone.name) == normalized) return zone;
    }
    return null;
  }

  static FloorModel? _floorByIdOrName(String id, String name, CampusModel campus) {
    final byId = campus.getFloor(id.trim());
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = _normalize(name);
    for (final floor in campus.floors) {
      if (_normalize(floor.name) == normalized) return floor;
    }
    return null;
  }

  static BuildingModel? _buildingByIdOrName(
    String id,
    String name,
    CampusModel campus,
  ) {
    final byId = campus.getBuilding(id.trim());
    if (byId != null) return byId;
    if (name.isEmpty) return null;

    final normalized = _normalize(name);
    for (final building in campus.buildings) {
      if (_normalize(building.name) == normalized) return building;
    }
    return null;
  }

  static String _floorLabel(String floorId, CampusModel campus) {
    final floor = campus.getFloor(floorId);
    return floor?.name ?? floorId;
  }

  /// Normaliza un texto para comparaciones tolerantes: minúsculas, sin acentos
  /// y con espacios colapsados (p.ej. "Vestíbulo" ≡ "VESTIBULO" ≡ "vestibulo").
  static String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_accentMap[ch] ?? ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Map<String, String> _accentMap = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ñ': 'n', 'ç': 'c',
  };
}