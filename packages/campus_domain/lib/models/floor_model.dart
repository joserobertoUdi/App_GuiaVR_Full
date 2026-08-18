import 'package:equatable/equatable.dart';

class FloorModel extends Equatable {
  final String id;
  final String name;
  final int level;
  final String buildingId;
  final List<String> zoneIds;
  final String? stairNodeId;
  final Map<String, dynamic>? metadata;

  const FloorModel({
    required this.id,
    required this.name,
    required this.level,
    required this.buildingId,
    this.zoneIds = const [],
    this.stairNodeId,
    this.metadata,
  });

  bool get hasZones => zoneIds.isNotEmpty;

  FloorModel copyWith({
    String? id,
    String? name,
    int? level,
    String? buildingId,
    List<String>? zoneIds,
    String? stairNodeId,
    Map<String, dynamic>? metadata,
  }) {
    return FloorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      buildingId: buildingId ?? this.buildingId,
      zoneIds: zoneIds ?? this.zoneIds,
      stairNodeId: stairNodeId ?? this.stairNodeId,
      metadata: metadata ?? this.metadata,
    );
  }

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      buildingId: json['buildingId'] as String,
      zoneIds: List<String>.from(json['zoneIds'] ?? []),
      stairNodeId: json['stairNodeId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'buildingId': buildingId,
      'zoneIds': zoneIds,
      'stairNodeId': stairNodeId,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, name, level, buildingId, zoneIds, stairNodeId, metadata];
}