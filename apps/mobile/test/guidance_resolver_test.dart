import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/hotspot_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/connection_direction_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/connection_direction_storage.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/utils/guidance_resolver.dart';

void main() {
  // Escenario "patio": nodo central con 4 salidas en 4 direcciones.
  final patio = NodeModel(
    id: 'patio',
    name: 'Patio',
    latitude: 0,
    longitude: 0,
    heading: 0,
    panoramaId: 'patio',
    connectedNodeIds: ['caja', 'aulas', 'cancha', 'biblioteca'],
  );

  final caja = NodeModel(
    id: 'caja', name: 'Caja', latitude: 1, longitude: 0, panoramaId: 'caja',
  );
  final aulas = NodeModel(
    id: 'aulas', name: 'Aulas', latitude: 0, longitude: 1, panoramaId: 'aulas',
  );
  final cancha = NodeModel(
    id: 'cancha', name: 'Cancha', latitude: -1, longitude: 0, panoramaId: 'cancha',
  );
  final biblioteca = NodeModel(
    id: 'biblioteca', name: 'Biblioteca', latitude: 0, longitude: -1, panoramaId: 'biblioteca',
  );

  tearDown(ConnectionDirectionStorage.clear);

  group('GuidanceResolver.autoYawFor', () {
    test('salidas cardinales obtienen direcciones distintas desde el patio', () {
      final haciaCaja = GuidanceResolver.autoYawFor(node: patio, nextNode: caja);
      final haciaAulas = GuidanceResolver.autoYawFor(node: patio, nextNode: aulas);
      final haciaCancha = GuidanceResolver.autoYawFor(node: patio, nextNode: cancha);
      final haciaBiblioteca = GuidanceResolver.autoYawFor(node: patio, nextNode: biblioteca);

      expect(haciaCaja, closeTo(0, 0.001)); // al frente
      expect(haciaAulas, closeTo(90, 0.001)); // derecha
      expect(haciaCancha, closeTo(180, 0.001)); // detrás
      expect(haciaBiblioteca, closeTo(270, 0.001)); // izquierda
    });

    test('usa el heading del nodo para trasladar el rumbo a la foto 360°', () {
      final patioConHeading90 = patio.copyWith(heading: 90);
      final haciaCaja = GuidanceResolver.autoYawFor(
        node: patioConHeading90,
        nextNode: caja,
      );
      // bearing 0 - heading 90 = -90 → 270: la salida al norte queda a la izquierda.
      expect(haciaCaja, closeTo(270, 0.001));
    });
  });

  group('GuidanceResolver.resolve', () {
    test('usa el hotspot de la conexión cuando no hay configuración', () {
      final panorama = PanoramaModel(
        id: 'patio',
        nodeId: 'patio',
        imageUrl: 'assets/panoramas/panorama_001.jpg',
        hotspots: [
          HotspotModel(
            id: 'h_patio_aulas',
            nodeId: 'patio',
            targetNodeId: 'aulas',
            yaw: 120,
            pitch: -5,
          ),
        ],
      );

      final resolved = GuidanceResolver.resolve(
        node: patio,
        nextNode: aulas,
        panorama: panorama,
      );

      expect(resolved, isNotNull);
      expect(resolved!.yaw, 120);
      expect(resolved.pitch, -5);
      expect(resolved.isOverride, isFalse);
    });

    test('la dirección del operador tiene prioridad sobre el hotspot', () {
      ConnectionDirectionStorage.setDirection(
        const ConnectionDirection(
          nodeId: 'patio',
          targetNodeId: 'aulas',
          yaw: 45,
          pitch: 10,
        ),
      );

      final panorama = PanoramaModel(
        id: 'patio',
        nodeId: 'patio',
        imageUrl: 'assets/panoramas/panorama_001.jpg',
        hotspots: [
          HotspotModel(
            id: 'h_patio_aulas',
            nodeId: 'patio',
            targetNodeId: 'aulas',
            yaw: 120,
            pitch: -5,
          ),
        ],
      );

      final resolved = GuidanceResolver.resolve(
        node: patio,
        nextNode: aulas,
        panorama: panorama,
      );

      expect(resolved, isNotNull);
      expect(resolved!.yaw, 45);
      expect(resolved.pitch, 10);
      expect(resolved.isOverride, isTrue);
    });

    test('cae al rumbo geográfico sin hotspot ni configuración', () {
      final resolved = GuidanceResolver.resolve(
        node: patio,
        nextNode: aulas,
        panorama: PanoramaModel(
          id: 'patio',
          nodeId: 'patio',
          imageUrl: 'assets/panoramas/panorama_001.jpg',
        ),
      );

      expect(resolved, isNotNull);
      expect(resolved!.yaw, closeTo(90, 0.001));
      expect(resolved.pitch, 0);
    });

    test('al quitar la configuración vuelve a usar el hotspot', () {
      ConnectionDirectionStorage.setDirection(
        const ConnectionDirection(
          nodeId: 'patio',
          targetNodeId: 'aulas',
          yaw: 45,
          pitch: 10,
        ),
      );
      ConnectionDirectionStorage.removeDirection('patio', 'aulas');

      final panorama = PanoramaModel(
        id: 'patio',
        nodeId: 'patio',
        imageUrl: 'assets/panoramas/panorama_001.jpg',
        hotspots: [
          HotspotModel(
            id: 'h_patio_aulas',
            nodeId: 'patio',
            targetNodeId: 'aulas',
            yaw: 120,
            pitch: -5,
          ),
        ],
      );

      final resolved = GuidanceResolver.resolve(
        node: patio,
        nextNode: aulas,
        panorama: panorama,
      );

      expect(resolved, isNotNull);
      expect(resolved!.yaw, 120);
      expect(resolved.isOverride, isFalse);
    });
  });

  group('ConnectionDirectionStorage', () {
    test('set/get/remove de una dirección', () {
      const direction = ConnectionDirection(
        nodeId: 'patio',
        targetNodeId: 'caja',
        yaw: 10,
        pitch: 0,
      );
      ConnectionDirectionStorage.setDirection(direction);
      expect(
        ConnectionDirectionStorage.getDirection('patio', 'caja'),
        direction,
      );
      expect(ConnectionDirectionStorage.hasDirection('patio', 'caja'), isTrue);
      expect(ConnectionDirectionStorage.getDirectionsForNode('patio'), hasLength(1));

      ConnectionDirectionStorage.removeDirection('patio', 'caja');
      expect(ConnectionDirectionStorage.getDirection('patio', 'caja'), isNull);
    });

    test('exportar e importar conserva las direcciones', () {
      ConnectionDirectionStorage.setDirection(
        const ConnectionDirection(
          nodeId: 'patio',
          targetNodeId: 'caja',
          yaw: 10,
          pitch: 5,
        ),
      );
      ConnectionDirectionStorage.setDirection(
        const ConnectionDirection(
          nodeId: 'patio',
          targetNodeId: 'aulas',
          yaw: 90,
          pitch: 0,
        ),
      );

      final json = ConnectionDirectionStorage.exportToJson();
      ConnectionDirectionStorage.clear();
      expect(ConnectionDirectionStorage.getDirectionsForNode('patio'), isEmpty);

      ConnectionDirectionStorage.importFromJson(json);
      expect(
        ConnectionDirectionStorage.getDirection('patio', 'caja')!.yaw,
        10,
      );
      expect(
        ConnectionDirectionStorage.getDirection('patio', 'aulas')!.yaw,
        90,
      );
    });
  });
}
