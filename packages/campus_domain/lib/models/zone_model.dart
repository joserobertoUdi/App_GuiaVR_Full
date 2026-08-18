import 'package:equatable/equatable.dart';

enum ZoneType { vesticulo, pasillo, aula, laboratorio, biblioteca, deporte, servicio, destino, transicion }

class ZoneModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String floorId;
  final String buildingId;
  final ZoneType type;
  final List<String> connectedZoneIds;
  final List<String> nodeIds;
  final String? entryNodeId;
  final String? exitNodeId;
  final int order;
  final Map<String, dynamic>? metadata;

  const ZoneModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.floorId,
    required this.buildingId,
    this.type = ZoneType.pasillo,
    this.connectedZoneIds = const [],
    this.nodeIds = const [],
    this.entryNodeId,
    this.exitNodeId,
    this.order = 0,
    this.metadata,
  });

  bool get hasNodes => nodeIds.isNotEmpty;
  bool get hasEntry => entryNodeId != null;
  bool get hasExit => exitNodeId != null;

  ZoneModel copyWith({
    String? id,
    String? name,
    String? description,
    String? floorId,
    String? buildingId,
    ZoneType? type,
    List<String>? connectedZoneIds,
    List<String>? nodeIds,
    String? entryNodeId,
    String? exitNodeId,
    int? order,
    Map<String, dynamic>? metadata,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      floorId: floorId ?? this.floorId,
      buildingId: buildingId ?? this.buildingId,
      type: type ?? this.type,
      connectedZoneIds: connectedZoneIds ?? this.connectedZoneIds,
      nodeIds: nodeIds ?? this.nodeIds,
      entryNodeId: entryNodeId ?? this.entryNodeId,
      exitNodeId: exitNodeId ?? this.exitNodeId,
      order: order ?? this.order,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      floorId: json['floorId'] as String,
      buildingId: json['buildingId'] as String,
      type: ZoneType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ZoneType.pasillo,
      ),
      connectedZoneIds: List<String>.from(json['connectedZoneIds'] ?? []),
      nodeIds: List<String>.from(json['nodeIds'] ?? []),
      entryNodeId: json['entryNodeId'] as String?,
      exitNodeId: json['exitNodeId'] as String?,
      order: json['order'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'floorId': floorId,
      'buildingId': buildingId,
      'type': type.name,
      'connectedZoneIds': connectedZoneIds,
      'nodeIds': nodeIds,
      'entryNodeId': entryNodeId,
      'exitNodeId': exitNodeId,
      'order': order,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id, name, description, floorId, buildingId, type,
        connectedZoneIds, nodeIds, entryNodeId, exitNodeId,
        order, metadata,
      ];
}