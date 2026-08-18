import '../models/node_model.dart';

abstract class NodeRepository {
  Future<List<NodeModel>> getAllNodes();
  Future<NodeModel?> getNodeById(String id);
  Future<List<NodeModel>> getNodesByBuilding(String buildingId);
  Future<List<NodeModel>> getNodesByFloor(String floorLevel);
  Future<List<NodeModel>> getConnectedNodes(String nodeId);
  Future<void> saveNode(NodeModel node);
  Future<void> deleteNode(String id);
  Future<void> updateNode(NodeModel node);
  Stream<List<NodeModel>> watchAllNodes();
  Stream<NodeModel?> watchNodeById(String id);
}
