import 'package:equatable/equatable.dart';

enum NodeZone { inicio, pasillo, destino }

class NodeModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double heading;
  final String? floorLevel;
  final String? buildingId;
  final String panoramaId;
  final List<String> connectedNodeIds;
  final NodeZone zone;
  final String? zoneId;
  final String? destinationLabel;
  final double? accuracy;
  final Map<String, dynamic>? metadata;

  const NodeModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.latitude,
    required this.longitude,
    this.heading = 0,
    this.floorLevel,
    this.buildingId,
    required this.panoramaId,
    this.connectedNodeIds = const [],
    this.zone = NodeZone.pasillo,
    this.zoneId,
    this.destinationLabel,
    this.accuracy,
    this.metadata,
  });

  bool get isDestination => zone == NodeZone.destino;
  bool get isTransition => false;
  bool get hasDestination => destinationLabel != null;

  NodeModel copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    double? heading,
    String? floorLevel,
    String? buildingId,
    String? panoramaId,
    List<String>? connectedNodeIds,
    NodeZone? zone,
    String? zoneId,
    String? destinationLabel,
    double? accuracy,
    Map<String, dynamic>? metadata,
  }) {
    return NodeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      floorLevel: floorLevel ?? this.floorLevel,
      buildingId: buildingId ?? this.buildingId,
      panoramaId: panoramaId ?? this.panoramaId,
      connectedNodeIds: connectedNodeIds ?? this.connectedNodeIds,
      zone: zone ?? this.zone,
      zoneId: zoneId ?? this.zoneId,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      accuracy: accuracy ?? this.accuracy,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      floorLevel: json['floorLevel'] as String?,
      buildingId: json['buildingId'] as String?,
      panoramaId: json['panoramaId'] as String,
      connectedNodeIds: List<String>.from(json['connectedNodeIds'] ?? []),
      zone: NodeZone.values.firstWhere(
        (e) => e.name == json['zone'],
        orElse: () => NodeZone.pasillo,
      ),
      zoneId: json['zoneId'] as String?,
      destinationLabel: json['destinationLabel'] as String?,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'floorLevel': floorLevel,
      'buildingId': buildingId,
      'panoramaId': panoramaId,
      'connectedNodeIds': connectedNodeIds,
      'zone': zone.name,
      'zoneId': zoneId,
      'destinationLabel': destinationLabel,
      'accuracy': accuracy,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id, name, description, latitude, longitude, heading,
        floorLevel, buildingId, panoramaId, connectedNodeIds,
        zone, zoneId, destinationLabel, accuracy, metadata,
      ];
}