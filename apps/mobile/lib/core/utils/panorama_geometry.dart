import 'dart:math';

/// Convierte un valor de yaw [0, 360) al rango de longitud usado por el
/// visor 360 (panorama_viewer), que va de -180 a 180 grados.
/// Utilizada para fijar objetos (flechas, hotspots, overlays) a un punto
/// concreto de la imagen 360 y no a la pantalla, de modo que solo se
/// muestran cuando quedan frente a la cámara.
double yawToLongitude(double yaw) {
  final normalized = yaw % 360.0;
  return normalized > 180 ? normalized - 360 : normalized;
}

/// Diferencia angular más corta entre dos ángulos en grados, normalizada a
/// (-180, 180]. Usada por la brújula de orientación para decidir si el rumbo
/// de guía queda a la izquierda, a la derecha o fuera de vista.
double angularDifferenceDegrees(double a, double b) {
  var d = (a - b) % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}

/// Rumbo inicial (bearing) entre dos puntos geográficos en grados [0, 360),
/// calculado con la fórmula del rumbo inicial de la haversine.
/// 0 = norte, 90 = este, 180 = sur, 270 = oeste.
double computeInitialBearing({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  final lat1Rad = _toRadians(lat1);
  final lat2Rad = _toRadians(lat2);
  final dLonRad = _toRadians(lon2 - lon1);
  final y = sin(dLonRad) * cos(lat2Rad);
  final x = cos(lat1Rad) * sin(lat2Rad) -
      sin(lat1Rad) * cos(lat2Rad) * cos(dLonRad);
  final bearingRad = atan2(y, x);
  return (_toDegrees(bearingRad) + 360) % 360;
}

/// Convierte un rumbo geográfico en el yaw de la imagen 360, teniendo en
/// cuenta el heading del nodo (la dirección geográfica que corresponde al
/// frente de la foto, yaw = 0). Resultado en [0, 360).
double yawFromBearing({
  required double bearing,
  required double heading,
}) {
  return (bearing - heading + 360) % 360;
}

double _toRadians(double degree) => degree * pi / 180;

double _toDegrees(double radian) => radian * 180 / pi;

/// Dirección relativa de un punto de la imagen 360° respecto a la vista actual
/// de la cámara. Usada por la brújula de borde para decidir dónde y cómo
/// avisar al usuario hacia dónde rotar la vista (izquierda/derecha/arriba/abajo).
class OffscreenDirection {
  /// Componente horizontal normalizada a [-1, 1]. Positiva = el destino está
  /// a la derecha de la vista actual.
  final double horizontal;

  /// Componente vertical normalizada a [-1, 1]. Positiva = el destino está
  /// por encima de la vista actual.
  final double vertical;

  /// `true` si el destino queda fuera del cono de visión actual de la cámara.
  final bool outsideView;

  /// Rotación (radianes, sentido horario) que debe aplicarse a una flecha que
  /// apunta hacia arriba para que indique la dirección del destino.
  final double arrowRotation;

  const OffscreenDirection({
    required this.horizontal,
    required this.vertical,
    required this.outsideView,
    required this.arrowRotation,
  });
}

/// Calcula hacia dónde queda el destino (yaw/pitch) respecto a la vista actual
/// de la cámara (longitud/latitud reportadas por el visor). Devuelve componentes
/// normalizadas al cono de visión: si `outsideView` es `true`, el destino está
/// fuera de pantalla y debe mostrarse la brújula de borde.
OffscreenDirection computeOffscreenDirection({
  required double targetYaw,
  required double targetPitch,
  required double viewLongitude,
  required double viewLatitude,
  double horizontalHalfFov = 65,
  double verticalHalfFov = 38,
}) {
  final hDelta = angularDifferenceDegrees(
    yawToLongitude(targetYaw),
    viewLongitude,
  );
  final vDelta = targetPitch - viewLatitude;
  final hRaw = hDelta / horizontalHalfFov;
  final vRaw = vDelta / verticalHalfFov;

  final outsideView = hRaw.abs() > 1.0 || vRaw.abs() > 1.0;

  double h = hRaw.clamp(-1.0, 1.0).toDouble();
  double v = vRaw.clamp(-1.0, 1.0).toDouble();
  // Pequeña zona muerta para que el botón no "brinque" al cruzar el centro
  // horizontal o vertical de la vista.
  if (h.abs() < 0.15) h = 0;
  if (v.abs() < 0.15) v = 0;

  return OffscreenDirection(
    horizontal: h,
    vertical: v,
    outsideView: outsideView,
    arrowRotation: atan2(h, v),
  );
}

/// Describe con palabras la dirección hacia el destino (ej: "Gira a la
/// derecha", "Gira hacia arriba", "Sigue hacia arriba a la derecha").
String describeGuidanceDirection(OffscreenDirection direction) {
  final h = direction.horizontal.abs() > 0.35
      ? (direction.horizontal > 0 ? 'derecha' : 'izquierda')
      : null;
  final v = direction.vertical.abs() > 0.35
      ? (direction.vertical > 0 ? 'arriba' : 'abajo')
      : null;
  if (h == null && v == null) return 'Sigue el rumbo';
  if (h != null && v != null) return 'Sigue hacia $v a la $h';
  if (h != null) return 'Gira a la $h';
  return 'Gira hacia $v';
}

/// Convierte la posición (yaw/pitch) de un overlay en el ancla fija sobre la
/// esfera 360° en las coordenadas (latitud, longitud) que usa el visor.
/// Garantiza que un texto o botón quede "pegado" a un punto concreto de la
/// imagen y no a la pantalla.
(double latitude, double longitude) overlayAnchor({
  required double yaw,
  required double pitch,
}) {
  return (pitch.clamp(-90, 90).toDouble(), yawToLongitude(yaw));
}
