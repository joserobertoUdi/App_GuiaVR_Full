import 'package:admin_web/core/utils/panorama_geometry.dart';
import 'package:admin_web/features/navigation/domain/models/node_model.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/connection_direction_storage.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/panorama_model.dart';

/// Resultado de resolver la dirección de guía hacia el siguiente nodo.
class ResolvedGuidance {
  final double yaw;
  final double pitch;

  /// `true` si la dirección viene de una configuración explícita del operador.
  final bool isOverride;

  const ResolvedGuidance({
    required this.yaw,
    required this.pitch,
    this.isOverride = false,
  });
}

/// Resuelve, para un nodo y el siguiente nodo de la ruta, el punto de la
/// imagen 360° (yaw/pitch) hacia donde debe apuntar la guía.
///
/// Prioridad:
///  1. Dirección definida por el operador (ConnectionDirectionStorage).
///  2. Hotspot de navegación ya definido en el panorama para esa conexión.
///  3. Cálculo automático: rumbo geográfico (haversine) − heading del nodo.
///
/// De este modo, un mismo nodo tipo "patio" puede tener salidas distintas
/// (frente → caja, izquierda → aulas, derecha → cancha, atrás → biblioteca)
/// y cada ruta obtiene su flecha y su auto-rotación correctas sin trabajo manual.
class GuidanceResolver {
  GuidanceResolver._();

  static ResolvedGuidance? resolve({
    required NodeModel node,
    required NodeModel nextNode,
    PanoramaModel? panorama,
  }) {
    final override = ConnectionDirectionStorage.getDirection(node.id, nextNode.id);
    if (override != null) {
      return ResolvedGuidance(
        yaw: override.yaw,
        pitch: override.pitch,
        isOverride: true,
      );
    }

    if (panorama != null) {
      for (final hotspot in panorama.hotspots) {
        if (hotspot.targetNodeId == nextNode.id) {
          return ResolvedGuidance(yaw: hotspot.yaw, pitch: hotspot.pitch);
        }
      }
    }

    final bearing = computeInitialBearing(
      lat1: node.latitude,
      lon1: node.longitude,
      lat2: nextNode.latitude,
      lon2: nextNode.longitude,
    );
    return ResolvedGuidance(
      yaw: yawFromBearing(bearing: bearing, heading: node.heading),
      pitch: 0,
    );
  }

  /// Dirección automática (rumbo geográfico) hacia un nodo conectado, usada
  /// por la UI del operador como valor sugerido cuando no hay configuración.
  static double autoYawFor({
    required NodeModel node,
    required NodeModel nextNode,
  }) {
    final bearing = computeInitialBearing(
      lat1: node.latitude,
      lon1: node.longitude,
      lat2: nextNode.latitude,
      lon2: nextNode.longitude,
    );
    return yawFromBearing(bearing: bearing, heading: node.heading);
  }
}