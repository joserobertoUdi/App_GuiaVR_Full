import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';

class MockNodesData {
  MockNodesData._();

  static const List<NodeModel> testNodes = [
    NodeModel(
      id: 'node_001',
      name: 'Entrada Principal',
      description: 'Entrada principal del edificio A - Vestíbulo',
      latitude: 19.3370,
      longitude: -99.1920,
      floorLevel: '1',
      buildingId: 'building_A',
      panoramaId: 'panorama_001',
      connectedNodeIds: ['node_002'],
    ),
    NodeModel(
      id: 'node_002',
      name: 'Cruce de Pasillo',
      description: 'Intersección del pasillo principal con ala este',
      latitude: 19.3372,
      longitude: -99.1918,
      floorLevel: '1',
      buildingId: 'building_A',
      panoramaId: 'panorama_002',
      connectedNodeIds: ['node_001', 'node_003'],
    ),
    NodeModel(
      id: 'node_003',
      name: 'Escaleras',
      description: 'Escaleras principales al segundo piso',
      latitude: 19.3374,
      longitude: -99.1916,
      floorLevel: '1',
      buildingId: 'building_A',
      panoramaId: 'panorama_003',
      connectedNodeIds: ['node_002', 'node_004'],
    ),
    NodeModel(
      id: 'node_004',
      name: 'Sala de Estudios',
      description: 'Sala de estudio grupal - Destino final',
      latitude: 19.3376,
      longitude: -99.1914,
      floorLevel: '2',
      buildingId: 'building_A',
      panoramaId: 'panorama_004',
      connectedNodeIds: ['node_003'],
    ),
  ];

  static NodeModel? getNodeById(String id) {
    try {
      return testNodes.firstWhere((node) => node.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<NodeModel> getConnectedNodes(String nodeId) {
    final node = getNodeById(nodeId);
    if (node == null) return [];
    return node.connectedNodeIds
        .map((id) => getNodeById(id))
        .where((n) => n != null)
        .cast<NodeModel>()
        .toList();
  }

  static List<NodeModel> getAllNodes() => testNodes;
}
