import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/core/utils/panorama_geometry.dart';

void main() {
  group('yawToLongitude', () {
    test('convierte yaw 0 a longitud 0 (frente, centro de la imagen)', () {
      expect(yawToLongitude(0), 0);
    });

    test('yaw 90 queda a la derecha (longitud +90)', () {
      expect(yawToLongitude(90), 90);
    });

    test('yaw 180 queda exactamente detrás', () {
      expect(yawToLongitude(180), 180);
    });

    test('yaw 270 se mapea a longitud -90 (izquierda)', () {
      expect(yawToLongitude(270), -90);
    });

    test('yaw 360 envuelve de vuelta a 0', () {
      expect(yawToLongitude(360), 0);
    });

    test('yaw fuera de rango siempre se normaliza al rango (-180, 180]', () {
      expect(yawToLongitude(540), 180); // 540 % 360 = 180
      expect(yawToLongitude(-90), -90);
      expect(yawToLongitude(-90 + 180), 90);
    });
  });

  group('angularDifferenceDegrees', () {
    test('diferencia 0 cuando apuntan al mismo rumbo', () {
      expect(angularDifferenceDegrees(0, 0), 0);
      expect(angularDifferenceDegrees(45, 45), 0);
    });

    test('diferencia corta respeta el signo (izq/der)', () {
      expect(angularDifferenceDegrees(90, 0), 90); // rumbo a la derecha
      expect(angularDifferenceDegrees(-90, 0), -90); // rumbo a la izquierda
    });

    test('el rumbo detrás (180) devuelve la vuelta más corta (±180)', () {
      expect(angularDifferenceDegrees(180, 0).abs(), 180);
      expect(angularDifferenceDegrees(0, 180).abs(), 180);
    });

    test('envuelve correctamente por el límite ±180', () {
      expect(angularDifferenceDegrees(-179, 179), 2);
      expect(angularDifferenceDegrees(179, -179), -2);
    });
  });

  group('computeInitialBearing', () {
    test('destino al norte devuelve 0', () {
      expect(
        computeInitialBearing(
          lat1: 0, lon1: 0, lat2: 10, lon2: 0,
        ),
        closeTo(0, 0.001),
      );
    });

    test('destino al este devuelve 90', () {
      expect(
        computeInitialBearing(
          lat1: 0, lon1: 0, lat2: 0, lon2: 10,
        ),
        closeTo(90, 0.001),
      );
    });

    test('destino al sur devuelve 180', () {
      expect(
        computeInitialBearing(
          lat1: 0, lon1: 0, lat2: -10, lon2: 0,
        ),
        closeTo(180, 0.001),
      );
    });

    test('destino al oeste devuelve 270', () {
      expect(
        computeInitialBearing(
          lat1: 0, lon1: 0, lat2: 0, lon2: -10,
        ),
        closeTo(270, 0.001),
      );
    });

    test('siempre queda en [0, 360)', () {
      for (var i = 0; i < 100; i++) {
        final b = computeInitialBearing(
          lat1: -10 + i.toDouble(),
          lon1: -80 + i.toDouble(),
          lat2: 30 + i.toDouble(),
          lon2: 40 + i.toDouble(),
        );
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
      }
    });
  });

  group('yawFromBearing', () {
    test('heading 0 mantiene el bearing como yaw', () {
      expect(yawFromBearing(bearing: 90, heading: 0), 90);
    });

    test('destino al frente cuando el frente apunta al destino', () {
      expect(yawFromBearing(bearing: 90, heading: 90), 0);
    });

    test('destino a la izquierda (bearing 0, heading 90 → yaw 270)', () {
      expect(yawFromBearing(bearing: 0, heading: 90), 270);
    });

    test('destino a la derecha (bearing 180, heading 90 → yaw 90)', () {
      expect(yawFromBearing(bearing: 180, heading: 90), 90);
    });

    test('destino detrás (bearing 180, heading 0 → yaw 180)', () {
      expect(yawFromBearing(bearing: 180, heading: 0), 180);
    });

    test('envuelve correctamente por 360', () {
      expect(yawFromBearing(bearing: 0, heading: 180), 180);
      expect(yawFromBearing(bearing: 90, heading: 180), 270);
      expect(yawFromBearing(bearing: 90, heading: 270), 180);
    });
  });
}