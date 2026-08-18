import 'package:equatable/equatable.dart';

enum OverlayType { arrow, text, button }

enum OverlayAction { none, navigateToNode }

class PanoramaOverlay extends Equatable {
  final String id;
  final String nodeId;
  final OverlayType type;
  final double yaw;
  final double pitch;
  final String text;
  final String iconCodePoint;
  final int colorValue;
  final double scale;
  final double opacity;
  final OverlayAction action;
  final String? actionTarget;
  final double rotation;
  final Map<String, dynamic>? metadata;

  const PanoramaOverlay({
    required this.id,
    required this.nodeId,
    required this.type,
    this.yaw = 0,
    this.pitch = 0,
    this.text = '',
    this.iconCodePoint = '0xe3af',
    this.colorValue = 0xFF2196F3,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.action = OverlayAction.none,
    this.actionTarget,
    this.rotation = 0,
    this.metadata,
  });

  PanoramaOverlay copyWith({
    String? id,
    String? nodeId,
    OverlayType? type,
    double? yaw,
    double? pitch,
    String? text,
    String? iconCodePoint,
    int? colorValue,
    double? scale,
    double? opacity,
    OverlayAction? action,
    String? actionTarget,
    double? rotation,
    Map<String, dynamic>? metadata,
  }) {
    return PanoramaOverlay(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      type: type ?? this.type,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      text: text ?? this.text,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      action: action ?? this.action,
      actionTarget: actionTarget ?? this.actionTarget,
      rotation: rotation ?? this.rotation,
      metadata: metadata ?? this.metadata,
    );
  }

  factory PanoramaOverlay.fromJson(Map<String, dynamic> json) {
    return PanoramaOverlay(
      id: json['id'] as String,
      nodeId: json['nodeId'] as String,
      type: OverlayType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OverlayType.arrow,
      ),
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0,
      text: json['text'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as String? ?? '0xe3af',
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      action: OverlayAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => OverlayAction.none,
      ),
      actionTarget: json['actionTarget'] as String?,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodeId': nodeId,
      'type': type.name,
      'yaw': yaw,
      'pitch': pitch,
      'text': text,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'scale': scale,
      'opacity': opacity,
      'action': action.name,
      'actionTarget': actionTarget,
      'rotation': rotation,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id, nodeId, type, yaw, pitch, text, iconCodePoint,
        colorValue, scale, opacity, action, actionTarget,
        rotation, metadata,
      ];
}