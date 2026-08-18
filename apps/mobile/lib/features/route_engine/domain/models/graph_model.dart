import 'package:equatable/equatable.dart';

class GraphEdge extends Equatable {
  final String startNodeId;
  final String endNodeId;
  final double weight;
  final double distance;
  final bool isBidirectional;

  const GraphEdge({
    required this.startNodeId,
    required this.endNodeId,
    this.weight = 1,
    required this.distance,
    this.isBidirectional = true,
  });

  GraphEdge copyWith({
    String? startNodeId,
    String? endNodeId,
    double? weight,
    double? distance,
    bool? isBidirectional,
  }) {
    return GraphEdge(
      startNodeId: startNodeId ?? this.startNodeId,
      endNodeId: endNodeId ?? this.endNodeId,
      weight: weight ?? this.weight,
      distance: distance ?? this.distance,
      isBidirectional: isBidirectional ?? this.isBidirectional,
    );
  }

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      startNodeId: json['startNodeId'] as String,
      endNodeId: json['endNodeId'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      distance: (json['distance'] as num).toDouble(),
      isBidirectional: json['isBidirectional'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startNodeId': startNodeId,
      'endNodeId': endNodeId,
      'weight': weight,
      'distance': distance,
      'isBidirectional': isBidirectional,
    };
  }

  @override
  List<Object?> get props => [
        startNodeId,
        endNodeId,
        weight,
        distance,
        isBidirectional,
      ];
}

class GraphModel extends Equatable {
  final Map<String, Map<String, double>> adjacencyList;
  final List<GraphEdge> edges;
  final Map<String, List<double>> nodeCoordinates;

  const GraphModel({
    required this.adjacencyList,
    this.edges = const [],
    this.nodeCoordinates = const {},
  });

  factory GraphModel.empty() {
    return const GraphModel(
      adjacencyList: {},
      edges: [],
      nodeCoordinates: {},
    );
  }

  List<String> get nodeIds => adjacencyList.keys.toList();

  int get nodeCount => adjacencyList.length;

  int get edgeCount => edges.length;

  bool containsNode(String nodeId) => adjacencyList.containsKey(nodeId);

  List<String> getNeighbors(String nodeId) {
    return adjacencyList[nodeId]?.keys.toList() ?? [];
  }

  double? getEdgeWeight(String fromNodeId, String toNodeId) {
    return adjacencyList[fromNodeId]?[toNodeId];
  }

  GraphModel addNode(String nodeId, {List<double>? coordinates}) {
    final newAdjacency = Map<String, Map<String, double>>.from(adjacencyList);
    if (!newAdjacency.containsKey(nodeId)) {
      newAdjacency[nodeId] = {};
    }
    final newCoordinates = Map<String, List<double>>.from(nodeCoordinates);
    if (coordinates != null) {
      newCoordinates[nodeId] = coordinates;
    }
    return GraphModel(
      adjacencyList: newAdjacency,
      edges: edges,
      nodeCoordinates: newCoordinates,
    );
  }

  GraphModel addEdge({
    required String fromNodeId,
    required String toNodeId,
    required double distance,
    double weight = 1,
    bool bidirectional = true,
  }) {
    final newAdjacency = Map<String, Map<String, double>>.from(adjacencyList);
    
    newAdjacency[fromNodeId] ??= {};
    newAdjacency[fromNodeId]![toNodeId] = weight;

    if (bidirectional) {
      newAdjacency[toNodeId] ??= {};
      newAdjacency[toNodeId]![fromNodeId] = weight;
    }

    final newEdges = List<GraphEdge>.from(edges);
    newEdges.add(GraphEdge(
      startNodeId: fromNodeId,
      endNodeId: toNodeId,
      weight: weight,
      distance: distance,
      isBidirectional: bidirectional,
    ));

    return GraphModel(
      adjacencyList: newAdjacency,
      edges: newEdges,
      nodeCoordinates: nodeCoordinates,
    );
  }

  factory GraphModel.fromJson(Map<String, dynamic> json) {
    final adjacencyRaw = json['adjacencyList'] as Map<String, dynamic>;
    final adjacencyList = <String, Map<String, double>>{};
    
    for (final entry in adjacencyRaw.entries) {
      final neighbors = entry.value as Map<String, dynamic>;
      adjacencyList[entry.key] = neighbors.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    final edgesRaw = json['edges'] as List? ?? [];
    final edges = edgesRaw
        .map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
        .toList();

    final coordinatesRaw = json['nodeCoordinates'] as Map<String, dynamic>? ?? {};
    final nodeCoordinates = <String, List<double>>{};
    for (final entry in coordinatesRaw.entries) {
      nodeCoordinates[entry.key] =
          (entry.value as List).map((e) => (e as num).toDouble()).toList();
    }

    return GraphModel(
      adjacencyList: adjacencyList,
      edges: edges,
      nodeCoordinates: nodeCoordinates,
    );
  }

  Map<String, dynamic> toJson() {
    final adjacencyJson = <String, dynamic>{};
    for (final entry in adjacencyList.entries) {
      adjacencyJson[entry.key] = entry.value.map(
        (key, value) => MapEntry(key, value),
      );
    }

    return {
      'adjacencyList': adjacencyJson,
      'edges': edges.map((e) => e.toJson()).toList(),
      'nodeCoordinates': nodeCoordinates,
    };
  }

  @override
  List<Object?> get props => [adjacencyList, edges, nodeCoordinates];
}
