import 'package:app_guia_ar/features/navigation/data/datasources/mock_nodes_data.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/repositories/node_repository.dart';

class NodeRepositoryImpl implements NodeRepository {
  final List<NodeModel> _nodes = List.from(MockNodesData.testNodes);

  @override
  Future<List<NodeModel>> getAllNodes() async {
    return List.unmodifiable(_nodes);
  }

  @override
  Future<NodeModel?> getNodeById(String id) async {
    try {
      return _nodes.firstWhere((node) => node.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NodeModel>> getNodesByBuilding(String buildingId) async {
    return _nodes.where((node) => node.buildingId == buildingId).toList();
  }

  @override
  Future<List<NodeModel>> getNodesByFloor(String floorLevel) async {
    return _nodes.where((node) => node.floorLevel == floorLevel).toList();
  }

  @override
  Future<List<NodeModel>> getConnectedNodes(String nodeId) async {
    final node = await getNodeById(nodeId);
    if (node == null) return [];
    
    final connectedNodes = <NodeModel>[];
    for (final connectedId in node.connectedNodeIds) {
      final connectedNode = await getNodeById(connectedId);
      if (connectedNode != null) {
        connectedNodes.add(connectedNode);
      }
    }
    return connectedNodes;
  }

  @override
  Future<void> saveNode(NodeModel node) async {
    final index = _nodes.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      _nodes[index] = node;
    } else {
      _nodes.add(node);
    }
  }

  @override
  Future<void> deleteNode(String id) async {
    _nodes.removeWhere((node) => node.id == id);
  }

  @override
  Future<void> updateNode(NodeModel node) async {
    final index = _nodes.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      _nodes[index] = node;
    }
  }

  @override
  Stream<List<NodeModel>> watchAllNodes() async* {
    yield List.unmodifiable(_nodes);
  }

  @override
  Stream<NodeModel?> watchNodeById(String id) async* {
    yield await getNodeById(id);
  }
}
