import 'package:equatable/equatable.dart';

class HotspotModel extends Equatable {
  final String id;
  final String nodeId;
  final String targetNodeId;
  final double yaw;
  final double pitch;
  final double? radius;
  final String label;
  final String? iconPath;
  final Map<String, dynamic>? metadata;

  const HotspotModel({
    required this.id,
    required this.nodeId,
    required this.targetNodeId,
    required this.yaw,
    required this.pitch,
    this.radius,
    this.label = '',
    this.iconPath,
    this.metadata,
  });

  HotspotModel copyWith({
    String? id,
    String? nodeId,
    String? targetNodeId,
    double? yaw,
    double? pitch,
    double? radius,
    String? label,
    String? iconPath,
    Map<String, dynamic>? metadata,
  }) {
    return HotspotModel(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      radius: radius ?? this.radius,
      label: label ?? this.label,
      iconPath: iconPath ?? this.iconPath,
      metadata: metadata ?? this.metadata,
    );
  }

  factory HotspotModel.fromJson(Map<String, dynamic> json) {
    return HotspotModel(
      id: json['id'] as String,
      nodeId: json['nodeId'] as String,
      targetNodeId: json['targetNodeId'] as String,
      yaw: (json['yaw'] as num).toDouble(),
      pitch: (json['pitch'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      label: json['label'] as String? ?? '',
      iconPath: json['iconPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodeId': nodeId,
      'targetNodeId': targetNodeId,
      'yaw': yaw,
      'pitch': pitch,
      'radius': radius,
      'label': label,
      'iconPath': iconPath,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        nodeId,
        targetNodeId,
        yaw,
        pitch,
        radius,
        label,
        iconPath,
        metadata,
      ];
}
