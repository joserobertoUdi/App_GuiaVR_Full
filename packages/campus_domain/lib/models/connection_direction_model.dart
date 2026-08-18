import 'package:equatable/equatable.dart';

/// Dirección (en coordenadas de la imagen 360) hacia la que debe apuntar la
/// guía desde un nodo hacia otro nodo conectado. La define el operador para
/// ajustar de forma simple la orientación de cada salida (derecha, izquierda,
/// frente, atrás) y sirve como fuente de verdad para la flecha de guía y para
/// la auto-rotación de la cámara al entrar al nodo.
class ConnectionDirection extends Equatable {
  final String nodeId;
  final String targetNodeId;
  final double yaw;
  final double pitch;

  const ConnectionDirection({
    required this.nodeId,
    required this.targetNodeId,
    required this.yaw,
    required this.pitch,
  });

  ConnectionDirection copyWith({
    String? nodeId,
    String? targetNodeId,
    double? yaw,
    double? pitch,
  }) {
    return ConnectionDirection(
      nodeId: nodeId ?? this.nodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
    );
  }

  factory ConnectionDirection.fromJson(Map<String, dynamic> json) {
    return ConnectionDirection(
      nodeId: json['nodeId'] as String,
      targetNodeId: json['targetNodeId'] as String,
      yaw: (json['yaw'] as num).toDouble(),
      pitch: (json['pitch'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'targetNodeId': targetNodeId,
      'yaw': yaw,
      'pitch': pitch,
    };
  }

  @override
  List<Object?> get props => [nodeId, targetNodeId, yaw, pitch];
}