import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

/// Valida el filtro piso → zona → nodo del editor de overlays: garantiza que
/// ningún nodo del campus quede "invisible" para el selector.
void main() {
  final campus = MockCampusData.campus;

  group('Selector de nodo (filtro piso → zona → nodo)', () {
    test('todo nodo del campus pertenece a una zona', () {
      for (final node in campus.nodes) {
        expect(
          node.zoneId,
          isNotNull,
          reason: 'El nodo ${node.id} debe tener zona para aparecer en el selector',
        );
        expect(
          campus.getZone(node.zoneId!),
          isNotNull,
          reason: 'La zona de ${node.id} debe existir',
        );
      }
    });

    test('la unión de los nodos de todas las zonas cubre el campus completo', () {
      final zoneNodeIds = <String>{};
      for (final zone in campus.zones) {
        zoneNodeIds.addAll(
          campus.getNodesForZone(zone.id).map((n) => n.id),
        );
      }
      final allNodeIds = campus.nodes.map((n) => n.id).toSet();
      expect(zoneNodeIds, allNodeIds);
    });

    test('ningún nodo se repite entre zonas (sin duplicados en el selector)', () {
      final seen = <String>{};
      for (final zone in campus.zones) {
        for (final node in campus.getNodesForZone(zone.id)) {
          expect(seen.add(node.id), isTrue,
              reason: 'El nodo ${node.id} aparece en más de una zona');
        }
      }
    });

    test('cada zona cuelga del piso correcto y cada nodo de su zona', () {
      for (final floor in campus.floors) {
        for (final zone in campus.getZonesForFloor(floor.id)) {
          expect(zone.floorId, floor.id);
          for (final node in campus.getNodesForZone(zone.id)) {
            expect(node.floorLevel, isNotNull,
                reason: 'El nodo ${node.id} debe indicar su piso');
          }
        }
      }
    });

    test('el campus expone al menos un nodo para editar overlays', () {
      expect(campus.nodes, isNotEmpty);
    });
  });
}
