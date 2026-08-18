import 'package:equatable/equatable.dart';
import 'building_model.dart';
import 'floor_model.dart';
import 'zone_model.dart';
import 'node_model.dart';

class CampusModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<BuildingModel> buildings;
  final List<FloorModel> floors;
  final List<ZoneModel> zones;
  final List<NodeModel> nodes;
  final String? version;
  final Map<String, dynamic>? metadata;

  const CampusModel({
    required this.id,
    required this.name,
    this.description = '',
    this.buildings = const [],
    this.floors = const [],
    this.zones = const [],
    this.nodes = const [],
    this.version,
    this.metadata,
  });

  CampusModel copyWith({
    String? id,
    String? name,
    String? description,
    List<BuildingModel>? buildings,
    List<FloorModel>? floors,
    List<ZoneModel>? zones,
    List<NodeModel>? nodes,
    String? version,
    Map<String, dynamic>? metadata,
  }) {
    return CampusModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      buildings: buildings ?? this.buildings,
      floors: floors ?? this.floors,
      zones: zones ?? this.zones,
      nodes: nodes ?? this.nodes,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
    );
  }

  BuildingModel? getBuilding(String buildingId) {
    try {
      return buildings.firstWhere((b) => b.id == buildingId);
    } catch (_) {
      return null;
    }
  }

  FloorModel? getFloor(String floorId) {
    try {
      return floors.firstWhere((f) => f.id == floorId);
    } catch (_) {
      return null;
    }
  }

  ZoneModel? getZone(String zoneId) {
    try {
      return zones.firstWhere((z) => z.id == zoneId);
    } catch (_) {
      return null;
    }
  }

  NodeModel? getNode(String nodeId) {
    try {
      return nodes.firstWhere((n) => n.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  List<FloorModel> getFloorsForBuilding(String buildingId) {
    return floors.where((f) => f.buildingId == buildingId).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
  }

  List<ZoneModel> getZonesForFloor(String floorId) {
    return zones.where((z) => z.floorId == floorId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<NodeModel> getNodesForZone(String zoneId) {
    return nodes.where((n) => n.zoneId == zoneId).toList();
  }

  factory CampusModel.fromJson(Map<String, dynamic> json) {
    return CampusModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      buildings: (json['buildings'] as List?)
              ?.map((e) => BuildingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      floors: (json['floors'] as List?)
              ?.map((e) => FloorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      zones: (json['zones'] as List?)
              ?.map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nodes: (json['nodes'] as List?)
              ?.map((e) => NodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      version: json['version'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'buildings': buildings.map((e) => e.toJson()).toList(),
      'floors': floors.map((e) => e.toJson()).toList(),
      'zones': zones.map((e) => e.toJson()).toList(),
      'nodes': nodes.map((e) => e.toJson()).toList(),
      'version': version,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id, name, description, buildings, floors, zones,
        nodes, version, metadata,
      ];
}