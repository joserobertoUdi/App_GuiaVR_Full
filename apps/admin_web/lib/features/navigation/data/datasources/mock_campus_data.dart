import 'package:admin_web/core/utils/platform_storage.dart';
import 'package:admin_web/features/navigation/domain/models/node_model.dart';
import 'package:admin_web/features/navigation/domain/models/route_model.dart';
import 'package:admin_web/features/navigation/domain/models/campus_model.dart';
import 'package:admin_web/features/navigation/domain/models/building_model.dart';
import 'package:admin_web/features/navigation/domain/models/floor_model.dart';
import 'package:admin_web/features/navigation/domain/models/zone_model.dart';
import 'package:admin_web/features/navigation/data/repositories/campus_repository.dart';

class MockCampusData {
  MockCampusData._();

  static const String buildingId = 'edificio_A';
  static const String buildingName = 'Edificio A';

  static final CampusRepository _repo = CampusRepository(_buildDefaultCampus());

  // ═══════════════════════════════════════════
  // DEFAULT CAMPUS DATA
  // ═══════════════════════════════════════════

  static CampusModel _buildDefaultCampus() {
    final building = BuildingModel(
      id: buildingId,
      name: buildingName,
      description: 'Edificio principal del campus',
      latitude: -16.5005,
      longitude: -68.1505,
      floorIds: ['piso_1', 'piso_2'],
    );

    // ═══ PISO 1 ═══
    final piso1 = FloorModel(
      id: 'piso_1',
      name: 'Piso 1',
      level: 1,
      buildingId: buildingId,
      zoneIds: ['z_vestibulo_p1', 'z_aulas_p1', 'z_escaleras_p1'],
      stairNodeId: 'P05',
    );

    // ═══ PISO 2 ═══
    final piso2 = FloorModel(
      id: 'piso_2',
      name: 'Piso 2',
      level: 2,
      buildingId: buildingId,
      zoneIds: ['z_vestibulo_p2', 'z_aulas_p2', 'z_salida_p2'],
      stairNodeId: 'P05',
    );

    // ═══ ZONAS PISO 1 ═══
    final zVestibuloP1 = ZoneModel(
      id: 'z_vestibulo_p1',
      name: 'Vestíbulo',
      description: 'Entrada principal del edificio',
      floorId: 'piso_1',
      buildingId: buildingId,
      type: ZoneType.vesticulo,
      connectedZoneIds: ['z_aulas_p1'],
      nodeIds: ['P01'],
      entryNodeId: 'P01',
      exitNodeId: 'P01',
      order: 0,
    );

    final zAulasP1 = ZoneModel(
      id: 'z_aulas_p1',
      name: 'Aulas P1',
      description: 'Pasillo principal y Aula 101 piso 1',
      floorId: 'piso_1',
      buildingId: buildingId,
      type: ZoneType.aula,
      connectedZoneIds: ['z_vestibulo_p1', 'z_escaleras_p1'],
      nodeIds: ['P02', 'P_AULA_101', 'P03'],
      entryNodeId: 'P02',
      exitNodeId: 'P03',
      order: 1,
    );

    final zEscalerasP1 = ZoneModel(
      id: 'z_escaleras_p1',
      name: 'Escaleras',
      description: 'Acceso al segundo piso',
      floorId: 'piso_1',
      buildingId: buildingId,
      type: ZoneType.transicion,
      connectedZoneIds: ['z_aulas_p1', 'z_vestibulo_p2'],
      nodeIds: ['P04', 'P05'],
      entryNodeId: 'P04',
      exitNodeId: 'P05',
      order: 2,
    );

    // ═══ ZONAS PISO 2 ═══
    final zVestibuloP2 = ZoneModel(
      id: 'z_vestibulo_p2',
      name: 'Cabeza Escalera P2',
      description: 'Llegada al segundo piso',
      floorId: 'piso_2',
      buildingId: buildingId,
      type: ZoneType.vesticulo,
      connectedZoneIds: ['z_aulas_p2'],
      nodeIds: ['P06'],
      entryNodeId: 'P06',
      exitNodeId: 'P06',
      order: 0,
    );

    final zAulasP2 = ZoneModel(
      id: 'z_aulas_p2',
      name: 'Aulas P2',
      description: 'Aulas 201, 204 y pasillo principal piso 2',
      floorId: 'piso_2',
      buildingId: buildingId,
      type: ZoneType.aula,
      connectedZoneIds: ['z_vestibulo_p2', 'z_salida_p2'],
      nodeIds: ['P07', 'P_AULA_201', 'P08', 'P_AULA_204'],
      entryNodeId: 'P07',
      exitNodeId: 'P08',
      order: 1,
    );

    final zSalidaP2 = ZoneModel(
      id: 'z_salida_p2',
      name: 'Salida Emergencia',
      description: 'Puerta de emergencia fondo del edificio',
      floorId: 'piso_2',
      buildingId: buildingId,
      type: ZoneType.destino,
      connectedZoneIds: ['z_aulas_p2'],
      nodeIds: ['P09'],
      entryNodeId: 'P09',
      exitNodeId: 'P09',
      order: 2,
    );

    // ═══ NODOS ═══
    final nodes = [
      // PISO 1 - Vestíbulo
      NodeModel(
        id: 'P01', name: 'Entrada Principal',
        description: 'Vestíbulo de entrada al edificio A',
        latitude: -16.5001, longitude: -68.1501, heading: 0,
        floorLevel: '1', buildingId: buildingId, panoramaId: 'P01',
        connectedNodeIds: ['P02'],
        zone: NodeZone.inicio, zoneId: 'z_vestibulo_p1',
      ),
      NodeModel(
        id: 'P02', name: 'Pasillo Principal P1',
        description: 'Cruce del pasillo principal - acceso a Aula 101',
        latitude: -16.5002, longitude: -68.1502, heading: 90,
        floorLevel: '1', buildingId: buildingId, panoramaId: 'P02',
        connectedNodeIds: ['P01', 'P03', 'P_AULA_101'],
        zone: NodeZone.pasillo, zoneId: 'z_aulas_p1',
      ),

      // PISO 1 - Aulas
      NodeModel(
        id: 'P_AULA_101', name: 'Aula 101',
        description: 'Aula de clases - Capacidad: 40 estudiantes',
        latitude: -16.50025, longitude: -68.15025, heading: 45,
        floorLevel: '1', buildingId: buildingId, panoramaId: 'P_AULA_101',
        connectedNodeIds: ['P02'],
        zone: NodeZone.destino, zoneId: 'z_aulas_p1',
        destinationLabel: 'Aula 101',
      ),
      NodeModel(
        id: 'P03', name: 'Pasillo Secundario P1',
        description: 'Pasillo hacia escaleras y aulas del fondo',
        latitude: -16.5003, longitude: -68.1503, heading: 90,
        floorLevel: '1', buildingId: buildingId, panoramaId: 'P03',
        connectedNodeIds: ['P02', 'P04'],
        zone: NodeZone.pasillo, zoneId: 'z_aulas_p1',
      ),

      // PISO 1 - Escaleras
      NodeModel(
        id: 'P04', name: 'Acceso Escaleras',
        description: 'Zona de escaleras - acceso al piso 2',
        latitude: -16.5004, longitude: -68.1504, heading: 0,
        floorLevel: '1', buildingId: buildingId, panoramaId: 'P04',
        connectedNodeIds: ['P03', 'P05'],
        zone: NodeZone.pasillo, zoneId: 'z_escaleras_p1',
      ),
      NodeModel(
        id: 'P05', name: 'Escalera Principal',
        description: 'Subiendo al segundo piso',
        latitude: -16.50045, longitude: -68.15045, heading: 0,
        floorLevel: '1-2', buildingId: buildingId, panoramaId: 'P05',
        connectedNodeIds: ['P04', 'P06'],
        zone: NodeZone.pasillo, zoneId: 'z_escaleras_p1',
      ),

      // PISO 2 - Vestíbulo
      NodeModel(
        id: 'P06', name: 'Cabeza de Escalera P2',
        description: 'Llegada al segundo piso',
        latitude: -16.5005, longitude: -68.1505, heading: 180,
        floorLevel: '2', buildingId: buildingId, panoramaId: 'P06',
        connectedNodeIds: ['P05', 'P07'],
        zone: NodeZone.inicio, zoneId: 'z_vestibulo_p2',
      ),

      // PISO 2 - Aulas
      NodeModel(
        id: 'P07', name: 'Pasillo Principal P2',
        description: 'Pasillo principal del segundo piso',
        latitude: -16.5006, longitude: -68.1506, heading: 90,
        floorLevel: '2', buildingId: buildingId, panoramaId: 'P07',
        connectedNodeIds: ['P06', 'P08', 'P_AULA_201'],
        zone: NodeZone.pasillo, zoneId: 'z_aulas_p2',
      ),
      NodeModel(
        id: 'P_AULA_201', name: 'Aula 201',
        description: 'Laboratorio de computación',
        latitude: -16.50065, longitude: -68.15065, heading: 45,
        floorLevel: '2', buildingId: buildingId, panoramaId: 'P_AULA_201',
        connectedNodeIds: ['P07'],
        zone: NodeZone.destino, zoneId: 'z_aulas_p2',
        destinationLabel: 'Aula 201',
      ),
      NodeModel(
        id: 'P08', name: 'Pasillo Fondo P2',
        description: 'Pasillo hacia aulas del fondo',
        latitude: -16.5007, longitude: -68.1507, heading: 90,
        floorLevel: '2', buildingId: buildingId, panoramaId: 'P08',
        connectedNodeIds: ['P07', 'P09', 'P_AULA_204'],
        zone: NodeZone.pasillo, zoneId: 'z_aulas_p2',
      ),
      NodeModel(
        id: 'P_AULA_204', name: 'Aula 204',
        description: 'Aula de conferencias - Capacidad: 60 estudiantes',
        latitude: -16.50075, longitude: -68.15075, heading: 45,
        floorLevel: '2', buildingId: buildingId, panoramaId: 'P_AULA_204',
        connectedNodeIds: ['P08'],
        zone: NodeZone.destino, zoneId: 'z_aulas_p2',
        destinationLabel: 'Aula 204',
      ),

      // PISO 2 - Salida
      NodeModel(
        id: 'P09', name: 'Salida de Emergencia P2',
        description: 'Puerta de emergencia del fondo del edificio',
        latitude: -16.5008, longitude: -68.1508, heading: 90,
        floorLevel: '2', buildingId: buildingId, panoramaId: 'P09',
        connectedNodeIds: ['P08'],
        zone: NodeZone.destino, zoneId: 'z_salida_p2',
        destinationLabel: 'Salida Emergencia',
      ),
    ];

    return CampusModel(
      id: 'campus_01',
      name: 'Campus Universitario',
      description: 'Mapa de navegación del campus',
      buildings: [building],
      floors: [piso1, piso2],
      zones: [zVestibuloP1, zAulasP1, zEscalerasP1, zVestibuloP2, zAulasP2, zSalidaP2],
      nodes: nodes,
      version: '2.0.0',
    );
  }

  // ═══════════════════════════════════════════
  // REPOSITORY ACCESS
  // ═══════════════════════════════════════════

  static CampusRepository get repository => _repo;
  static CampusModel get campus => _repo.campus;

  // ═══════════════════════════════════════════
  // PERSISTENCE (multi-plataforma)
  // ═══════════════════════════════════════════

  static const String _campusStorageKey = 'campus_data_json';

  static Future<void> saveToFile() async {
    try {
      final json = _repo.exportToJson(pretty: false);
      await PlatformStorage.instance.write(_campusStorageKey, json);
    } catch (_) {}
  }

  static Future<bool> loadFromFile() async {
    try {
      final json = await PlatformStorage.instance.read(_campusStorageKey);
      if (json == null) return false;
      final campus = CampusRepository.importFromJson(json);
      _repo.updateCampus(campus);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> resetToDefault() async {
    await PlatformStorage.instance.remove(_campusStorageKey);
  }

  // ═══════════════════════════════════════════
  // BACKWARD-COMPATIBLE API
  // ═══════════════════════════════════════════

  static List<NodeModel> get allNodes => List.unmodifiable(_repo.campus.nodes);

  static void addNode(NodeModel node) {
    _repo.addNode(node);
    _safeSave();
  }

  static void updateNode(String nodeId, NodeModel updatedNode) {
    final existing = _repo.campus.getNode(nodeId);
    if (existing != null) {
      _repo.updateNode(updatedNode);
      _safeSave();
    }
  }

  static void removeNode(String nodeId) {
    _repo.removeNode(nodeId);
    _safeSave();
  }

  static void addBuilding(BuildingModel building) {
    _repo.addBuilding(building);
    _safeSave();
  }

  static void updateBuilding(BuildingModel building) {
    _repo.updateBuilding(building);
    _safeSave();
  }

  static void removeBuilding(String buildingId) {
    _repo.removeBuilding(buildingId);
    _safeSave();
  }

  static void addFloor(FloorModel floor) {
    _repo.addFloor(floor);
    _safeSave();
  }

  static void updateFloor(FloorModel floor) {
    _repo.updateFloor(floor);
    _safeSave();
  }

  static void removeFloor(String floorId) {
    _repo.removeFloor(floorId);
    _safeSave();
  }

  static void addZone(ZoneModel zone) {
    _repo.addZone(zone);
    _safeSave();
  }

  static void updateZone(ZoneModel zone) {
    _repo.updateZone(zone);
    _safeSave();
  }

  static void removeZone(String zoneId) {
    _repo.removeZone(zoneId);
    _safeSave();
  }

  static void _safeSave() {
    saveToFile();
  }

  static NodeModel? getNodeById(String id) => _repo.campus.getNode(id);

  static List<NodeModel> getConnectedNodes(String nodeId) {
    final node = getNodeById(nodeId);
    if (node == null) return [];
    return node.connectedNodeIds
        .map((id) => getNodeById(id))
        .where((n) => n != null)
        .cast<NodeModel>()
        .toList();
  }

  static List<NodeModel> getNodesByFloor(String floor) {
    return allNodes.where((n) => n.floorLevel == floor).toList();
  }

  static List<NodeModel> getDestinations() {
    return allNodes.where((n) => n.isDestination).toList();
  }

  static List<NodeModel> getAllNodes() => allNodes;

  static List<NodeModel> findRoute(String startId, String endId) {
    final result = _repo.findRoute(startId, endId);
    return result.nodePath;
  }

  static RouteModel calculateRoute({
    required String startId,
    required String endId,
    RouteMode mode = RouteMode.guidedWalk,
  }) {
    final result = _repo.findRoute(startId, endId);
    if (result.hasError) {
      return RouteModel(
        id: 'route_${startId}_$endId',
        startNodeId: startId,
        endNodeId: endId,
        status: RouteStatus.failed,
        errorMessage: result.error,
      );
    }

    final path = result.nodePath;
    if (path.isEmpty) {
      return RouteModel(
        id: 'route_${startId}_$endId',
        startNodeId: startId,
        endNodeId: endId,
        status: RouteStatus.failed,
        errorMessage: 'No se encontró ruta',
      );
    }

    final steps = <RouteStep>[];
    for (int i = 0; i < path.length - 1; i++) {
      final current = path[i];
      final next = path[i + 1];

      final dLat = next.latitude - current.latitude;
      final dLon = next.longitude - current.longitude;
      final bearing = ((90 - (dLon != 0 ? (dLat / dLon) * 180 / 3.14159 : 0)) % 360).toDouble();
      final distance = _calculateDistance(
        current.latitude, current.longitude,
        next.latitude, next.longitude,
      );

      String? instruction;
      if (next.isDestination) {
        instruction = 'Llegaste a ${next.destinationLabel ?? next.name}';
      } else if (dLat > 0) {
        instruction = 'Avanza hacia el norte';
      } else if (dLat < 0) {
        instruction = 'Avanza hacia el sur';
      } else if (dLon > 0) {
        instruction = 'Gira a la derecha';
      } else {
        instruction = 'Sigue recto';
      }

      steps.add(RouteStep(
        nodeId: next.id,
        instruction: instruction,
        bearingToNext: bearing,
        distanceToNext: distance,
        estimatedSeconds: (distance / 1.4).ceil(),
      ));
    }

    final totalDistance = steps.fold<double>(
      0, (sum, s) => sum + (s.distanceToNext ?? 0),
    );
    final totalTime = steps.fold<int>(
      0, (sum, s) => sum + s.estimatedSeconds,
    );

    return RouteModel(
      id: 'route_${startId}_$endId',
      startNodeId: startId,
      endNodeId: endId,
      nodeIds: path.map((n) => n.id).toList(),
      nodes: path,
      steps: steps,
      totalDistance: totalDistance,
      estimatedTimeSeconds: totalTime,
      mode: mode,
      status: RouteStatus.active,
      currentStepIndex: 0,
    );
  }

  static double _calculateDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const earthRadius = 6371000;
    final dLat = (lat2 - lat1) * 3.14159 / 180;
    final dLon = (lon2 - lon1) * 3.14159 / 180;
    final a = (dLat / 2) * (dLat / 2) +
        (lat1 * 3.14159 / 180).cos() *
            (lat2 * 3.14159 / 180).cos() *
            (dLon / 2) * (dLon / 2);
    return earthRadius * 2 * _atan2(a.sqrt(), (1 - a).sqrt());
  }

  static double _atan2(double y, double x) {
    return x >= 0
        ? (y / x).atan()
        : (y / x).atan() + 3.14159;
  }
}

extension _DoubleExt on double {
  double cos() => _cos(this);
  double sqrt() => _sqrt(this);
  double atan() => _atan(this);

  static double _cos(double x) {
    final xi = x % (2 * 3.14159);
    if (xi < 0) return _cos(x + 2 * 3.14159);
    final seg = (xi / (3.14159 / 2)).floor();
    final frac = xi / (3.14159 / 2) - seg;
    final base = 1 - frac * frac * (3 - frac * frac * 2) / 12;
    return seg % 2 == 0 ? base : -base;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan(double x) {
    if (x > 1) return 1.5708 - _atan(1 / x);
    if (x < -1) return -1.5708 - _atan(1 / x);
    final x2 = x * x;
    return x * (1 + x2 * (0.33333 + x2 * 0.2)) /
        (1 + x2 * (1 + x2 * (0.66666 + x2 * 0.13333)));
  }
}