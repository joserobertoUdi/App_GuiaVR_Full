import '../models/graph_model.dart';

abstract class GraphRepository {
  Future<GraphModel> getGraph();
  Future<GraphModel> getGraphByBuilding(String buildingId);
  Future<void> saveGraph(GraphModel graph);
  Future<void> addNode(String nodeId, {List<double>? coordinates});
  Future<void> addEdge({
    required String fromNodeId,
    required String toNodeId,
    required double distance,
    double weight = 1,
    bool bidirectional = true,
  });
  Future<void> removeNode(String nodeId);
  Future<void> removeEdge(String fromNodeId, String toNodeId);
  Stream<GraphModel> watchGraph();
}
