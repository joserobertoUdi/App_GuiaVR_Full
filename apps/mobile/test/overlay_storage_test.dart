import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/core/utils/panorama_geometry.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_overlay_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/overlay_storage.dart';

void main() {
  tearDown(OverlayStorage.clear);

  group('OverlayStorage - texto anclado a un punto de la imagen 360', () {
    final etiquetaSalaSoporte = PanoramaOverlay(
      id: 'ov_sala_soporte',
      nodeId: 'patio',
      type: OverlayType.text,
      text: 'Sala de Soporte',
      yaw: 135,
      pitch: 20,
      colorValue: 0xFF2196F3,
    );

    test('crea, consulta y actualiza un texto para un nodo', () {
      OverlayStorage.addOverlay(etiquetaSalaSoporte);
      final overlays = OverlayStorage.getOverlaysForNode('patio');
      expect(overlays, hasLength(1));
      expect(overlays.first.text, 'Sala de Soporte');
      expect(overlays.first.type, OverlayType.text);

      final actualizado = etiquetaSalaSoporte.copyWith(text: 'Sala Soporte');
      OverlayStorage.updateOverlay(actualizado);
      expect(
        OverlayStorage.getOverlaysForNode('patio').first.text,
        'Sala Soporte',
      );
    });

    test('el texto no se mezcla con los overlays de otros nodos', () {
      OverlayStorage.addOverlay(etiquetaSalaSoporte);
      OverlayStorage.addOverlay(
        etiquetaSalaSoporte.copyWith(id: 'ov_otro', nodeId: 'caja'),
      );
      expect(OverlayStorage.getOverlaysForNode('patio'), hasLength(1));
      expect(OverlayStorage.getOverlaysForNode('caja'), hasLength(1));
      expect(
        OverlayStorage.getNodeIdsWithOverlays(),
        unorderedEquals(['patio', 'caja']),
      );
    });

    test('elimina un texto por id', () {
      OverlayStorage.addOverlay(etiquetaSalaSoporte);
      OverlayStorage.removeOverlay('patio', etiquetaSalaSoporte.id);
      expect(OverlayStorage.getOverlaysForNode('patio'), isEmpty);
    });

    test('exportar e importar conserva textos y posiciones', () {
      OverlayStorage.addOverlay(etiquetaSalaSoporte);
      final json = OverlayStorage.exportToJson();
      OverlayStorage.clear();
      expect(OverlayStorage.getOverlaysForNode('patio'), isEmpty);

      OverlayStorage.importFromJson(json);
      final restored = OverlayStorage.getOverlaysForNode('patio').first;
      expect(restored.text, 'Sala de Soporte');
      expect(restored.yaw, 135);
      expect(restored.pitch, 20);
      expect(restored.colorValue, 0xFF2196F3);
    });

    test('toJson/fromJson ida y vuelta conserva el modelo', () {
      final restored = PanoramaOverlay.fromJson(etiquetaSalaSoporte.toJson());
      expect(restored, etiquetaSalaSoporte);
    });

    test('overlayAnchor fija el texto a un punto de la esfera 360', () {
      final anchor = overlayAnchor(yaw: 135, pitch: 20);
      // yaw 135 → longitud +135 (delante a la derecha), pitch 20 → latitud 20.
      expect(anchor.$2, 135);
      expect(anchor.$1, 20);
    });

    test('overlayAnchor respeta el rango del visor (sin anclas fuera de rango)', () {
      final anchor = overlayAnchor(yaw: 720, pitch: 130);
      // yaw se normaliza a [0, 360); pitch se limita a [-90, 90].
      expect(anchor.$2, 0);
      expect(anchor.$1, 90);
    });

    test('una etiqueta detrás no se confunde con una al frente', () {
      final frente = overlayAnchor(yaw: 0, pitch: 0);
      final detras = overlayAnchor(yaw: 180, pitch: 0);
      expect(frente.$2, 0);
      expect(detras.$2, 180);
      expect(frente.$2 == detras.$2, isFalse);
    });

    test('la altura sube con pitch positivo y baja con pitch negativo', () {
      final arriba = overlayAnchor(yaw: 0, pitch: 45);
      final abajo = overlayAnchor(yaw: 0, pitch: -45);
      expect(arriba.$1, greaterThan(0)); // latitud positiva = arriba en la imagen
      expect(abajo.$1, lessThan(0)); // latitud negativa = abajo
      expect(abajo.$1.abs(), arriba.$1);
    });
  });
}