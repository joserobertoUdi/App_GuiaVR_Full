import 'package:equatable/equatable.dart';

import 'hotspot_model.dart';

class PanoramaModel extends Equatable {
  final String id;
  final String nodeId;
  final String imageUrl;
  final String? thumbnailUrl;
  final double initialYaw;
  final double initialPitch;
  final List<HotspotModel> hotspots;
  final Map<String, dynamic>? metadata;

  const PanoramaModel({
    required this.id,
    required this.nodeId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.initialYaw = 0,
    this.initialPitch = 0,
    this.hotspots = const [],
    this.metadata,
  });

  PanoramaModel copyWith({
    String? id,
    String? nodeId,
    String? imageUrl,
    String? thumbnailUrl,
    double? initialYaw,
    double? initialPitch,
    List<HotspotModel>? hotspots,
    Map<String, dynamic>? metadata,
  }) {
    return PanoramaModel(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      initialYaw: initialYaw ?? this.initialYaw,
      initialPitch: initialPitch ?? this.initialPitch,
      hotspots: hotspots ?? this.hotspots,
      metadata: metadata ?? this.metadata,
    );
  }

  HotspotModel? getHotspotById(String hotspotId) {
    try {
      return hotspots.firstWhere((h) => h.id == hotspotId);
    } catch (_) {
      return null;
    }
  }

  List<HotspotModel> getHotspotsForNode(String targetNodeId) {
    return hotspots.where((h) => h.targetNodeId == targetNodeId).toList();
  }

  factory PanoramaModel.fromJson(Map<String, dynamic> json) {
    return PanoramaModel(
      id: json['id'] as String,
      nodeId: json['nodeId'] as String,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      initialYaw: (json['initialYaw'] as num?)?.toDouble() ?? 0,
      initialPitch: (json['initialPitch'] as num?)?.toDouble() ?? 0,
      hotspots: (json['hotspots'] as List?)
              ?.map((e) => HotspotModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodeId': nodeId,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'initialYaw': initialYaw,
      'initialPitch': initialPitch,
      'hotspots': hotspots.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        nodeId,
        imageUrl,
        thumbnailUrl,
        initialYaw,
        initialPitch,
        hotspots,
        metadata,
      ];
}