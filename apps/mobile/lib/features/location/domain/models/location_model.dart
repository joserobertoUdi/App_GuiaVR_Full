import 'package:equatable/equatable.dart';

enum LocationMethod { gps, qr, manual, ble, wifiRtt }

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final String? nodeId;
  final LocationMethod method;
  final DateTime timestamp;
  final String? floorLevel;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.nodeId,
    required this.method,
    required this.timestamp,
    this.floorLevel,
  });

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    String? nodeId,
    LocationMethod? method,
    DateTime? timestamp,
    String? floorLevel,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      nodeId: nodeId ?? this.nodeId,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      floorLevel: floorLevel ?? this.floorLevel,
    );
  }

  bool get isFromGPS => method == LocationMethod.gps;
  bool get isFromQR => method == LocationMethod.qr;
  bool get isManual => method == LocationMethod.manual;
  bool get hasNodeId => nodeId != null;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      nodeId: json['nodeId'] as String?,
      method: LocationMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => LocationMethod.manual,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      floorLevel: json['floorLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'nodeId': nodeId,
      'method': method.name,
      'timestamp': timestamp.toIso8601String(),
      'floorLevel': floorLevel,
    };
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracy,
        altitude,
        nodeId,
        method,
        timestamp,
        floorLevel,
      ];
}
