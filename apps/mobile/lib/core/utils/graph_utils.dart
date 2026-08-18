import 'dart:math';

class GraphUtils {
  GraphUtils._();

  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  static List<String> dijkstra({
    required Map<String, Map<String, double>> graph,
    required String startNodeId,
    required String endNodeId,
  }) {
    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (final nodeId in graph.keys) {
      distances[nodeId] = double.infinity;
      previous[nodeId] = null;
      unvisited.add(nodeId);
    }

    distances[startNodeId] = 0;

    while (unvisited.isNotEmpty) {
      final current = unvisited
          .reduce((a, b) => distances[a]! <= distances[b]! ? a : b);

      if (current == endNodeId) break;

      unvisited.remove(current);

      final neighbors = graph[current] ?? {};
      for (final entry in neighbors.entries) {
        final neighborId = entry.key;
        final weight = entry.value;

        if (!unvisited.contains(neighborId)) continue;

        final newDistance = distances[current]! + weight;
        if (newDistance < distances[neighborId]!) {
          distances[neighborId] = newDistance;
          previous[neighborId] = current;
        }
      }
    }

    return _reconstructPath(previous, endNodeId);
  }

  static List<String> aStar({
    required Map<String, Map<String, double>> graph,
    required Map<String, List<double>> nodeCoordinates,
    required String startNodeId,
    required String endNodeId,
  }) {
    final gScore = <String, double>{};
    final fScore = <String, double>{};
    final previous = <String, String?>{};
    final openSet = <String>{};

    for (final nodeId in graph.keys) {
      gScore[nodeId] = double.infinity;
      fScore[nodeId] = double.infinity;
      previous[nodeId] = null;
    }

    gScore[startNodeId] = 0;
    fScore[startNodeId] = _heuristic(
      nodeCoordinates[startNodeId],
      nodeCoordinates[endNodeId],
    );
    openSet.add(startNodeId);

    while (openSet.isNotEmpty) {
      final current = openSet.reduce(
        (a, b) => fScore[a]! <= fScore[b]! ? a : b,
      );

      if (current == endNodeId) break;

      openSet.remove(current);

      final neighbors = graph[current] ?? {};
      for (final entry in neighbors.entries) {
        final neighborId = entry.key;
        final weight = entry.value;

        final tentativeGScore = gScore[current]! + weight;

        if (tentativeGScore < gScore[neighborId]!) {
          previous[neighborId] = current;
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] =
              gScore[neighborId]! +
              _heuristic(
                nodeCoordinates[neighborId],
                nodeCoordinates[endNodeId],
              );
          openSet.add(neighborId);
        }
      }
    }

    return _reconstructPath(previous, endNodeId);
  }

  static double _heuristic(List<double>? a, List<double>? b) {
    if (a == null || b == null) return 0;
    return calculateDistance(
      lat1: a[0],
      lon1: a[1],
      lat2: b[0],
      lon2: b[1],
    );
  }

  static List<String> _reconstructPath(
    Map<String, String?> previous,
    String endNodeId,
  ) {
    final path = <String>[];
    String? current = endNodeId;

    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    if (path.isEmpty || path.first != endNodeId) {
      return [];
    }

    return path;
  }

  static double calculatePathDistance({
    required Map<String, Map<String, double>> graph,
    required List<String> path,
  }) {
    if (path.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final weight = graph[path[i]]?[path[i + 1]] ?? 0;
      totalDistance += weight;
    }

    return totalDistance;
  }

  static int estimateWalkingTime(double distanceInMeters) {
    const walkingSpeedMps = 1.4;
    return (distanceInMeters / walkingSpeedMps).ceil();
  }
}
