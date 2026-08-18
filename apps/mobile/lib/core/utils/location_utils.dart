import 'dart:math';

class LocationUtils {
  LocationUtils._();

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

  static String? findNearestNode({
    required double userLat,
    required double userLon,
    required Map<String, List<double>> nodeCoordinates,
    double maxDistance = 50,
  }) {
    String? nearestNodeId;
    double minDistance = double.infinity;

    for (final entry in nodeCoordinates.entries) {
      final distance = calculateDistance(
        lat1: userLat,
        lon1: userLon,
        lat2: entry.value[0],
        lon2: entry.value[1],
      );

      if (distance < minDistance && distance <= maxDistance) {
        minDistance = distance;
        nearestNodeId = entry.key;
      }
    }

    return nearestNodeId;
  }

  static double getBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);
    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  static double _toDegrees(double radians) {
    return radians * 180 / pi;
  }

  static String getDirectionString(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'N';
    if (bearing >= 22.5 && bearing < 67.5) return 'NE';
    if (bearing >= 67.5 && bearing < 112.5) return 'E';
    if (bearing >= 112.5 && bearing < 157.5) return 'SE';
    if (bearing >= 157.5 && bearing < 202.5) return 'S';
    if (bearing >= 202.5 && bearing < 247.5) return 'SW';
    if (bearing >= 247.5 && bearing < 292.5) return 'W';
    return 'NW';
  }

  static bool isInsideBounds({
    required double lat,
    required double lon,
    required double northEastLat,
    required double northEastLon,
    required double southWestLat,
    required double southWestLon,
  }) {
    return lat >= southWestLat &&
        lat <= northEastLat &&
        lon >= southWestLon &&
        lon <= northEastLon;
  }
}
