import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:app_guia_ar/core/utils/panorama_geometry.dart';

void main() {
  group('computeOffscreenDirection', () {
    test('destino al frente y nivelado: dentro de vista, sin brújula', () {
      final dir = computeOffscreenDirection(
        targetYaw: 0,
        targetPitch: 0,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isFalse);
    });

    test('destino ligeramente a la derecha: dentro de vista', () {
      final dir = computeOffscreenDirection(
        targetYaw: 30,
        targetPitch: 0,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isFalse);
    });

    test('destino a la derecha fuera de vista: brújula hacia la derecha', () {
      final dir = computeOffscreenDirection(
        targetYaw: 120,
        targetPitch: 0,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isTrue);
      expect(dir.horizontal, greaterThan(0));
      expect(dir.vertical, 0);
      // Flecha (base hacia arriba) debe girar +90° (horario) para apuntar a la derecha.
      expect(dir.arrowRotation, closeTo(pi / 2, 0.001));
    });

    test('destino a la izquierda fuera de vista: brújula hacia la izquierda', () {
      final dir = computeOffscreenDirection(
        targetYaw: 270,
        targetPitch: 0,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isTrue);
      expect(dir.horizontal, lessThan(0));
      expect(dir.arrowRotation, closeTo(-pi / 2, 0.001));
    });

    test('destino por encima de la vista: brújula hacia arriba', () {
      final dir = computeOffscreenDirection(
        targetYaw: 0,
        targetPitch: 80,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isTrue);
      expect(dir.vertical, greaterThan(0));
      expect(dir.arrowRotation, closeTo(0, 0.001));
    });

    test('destino por debajo de la vista: brújula hacia abajo', () {
      final dir = computeOffscreenDirection(
        targetYaw: 0,
        targetPitch: -80,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isTrue);
      expect(dir.vertical, lessThan(0));
    });

    test('destino diagonal arriba-derecha: flecha con ángulo intermedio', () {
      final dir = computeOffscreenDirection(
        targetYaw: 60,
        targetPitch: 60,
        viewLongitude: 0,
        viewLatitude: 0,
      );
      expect(dir.outsideView, isTrue);
      expect(dir.horizontal, greaterThan(0));
      expect(dir.vertical, greaterThan(0));
      expect(dir.arrowRotation, greaterThan(0));
      expect(dir.arrowRotation, lessThan(pi / 2));
    });

    test('ángulos envuelven por el límite ±180', () {
      // Mirada a 170°, destino a -170°: el destino está apenas a la derecha.
      final dir = computeOffscreenDirection(
        targetYaw: 190, // yaw 190 → longitud -170
        targetPitch: 0,
        viewLongitude: 170,
        viewLatitude: 0,
      );
      expect(dir.horizontal, greaterThan(0));
    });
  });

  group('describeGuidanceDirection', () {
    OffscreenDirection _dir(double h, double v) => OffscreenDirection(
          horizontal: h,
          vertical: v,
          outsideView: true,
          arrowRotation: atan2(h, v),
        );

    test('nombra izquierda', () {
      expect(describeGuidanceDirection(_dir(-1, 0)), 'Gira a la izquierda');
    });

    test('nombra derecha', () {
      expect(describeGuidanceDirection(_dir(1, 0)), 'Gira a la derecha');
    });

    test('nombra arriba', () {
      expect(describeGuidanceDirection(_dir(0, 1)), 'Gira hacia arriba');
    });

    test('nombra abajo', () {
      expect(describeGuidanceDirection(_dir(0, -1)), 'Gira hacia abajo');
    });

    test('combina diagonal', () {
      expect(
        describeGuidanceDirection(_dir(1, 1)),
        'Sigue hacia arriba a la derecha',
      );
      expect(
        describeGuidanceDirection(_dir(-1, -1)),
        'Sigue hacia abajo a la izquierda',
      );
    });

    test('valor por defecto cuando es proporcionalmente menor a 0.35', () {
      expect(describeGuidanceDirection(_dir(0.2, 0.2)), 'Sigue el rumbo');
    });
  });
}