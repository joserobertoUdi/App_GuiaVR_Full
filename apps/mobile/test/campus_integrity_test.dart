import 'package:flutter_test/flutter_test.dart';

import 'package:app_guia_ar/features/navigation/domain/models/campus_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/building_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/floor_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/zone_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/data/repositories/campus_repository.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

void main() {
  group('Integridad del campus (creación infalible)', () {
    test('addNode crea conexiones bidireccionales', () {
      final repo = CampusRepository(MockCampusData.campus);
      repo.addNode(const NodeModel(
        id: 'NEW', name: 'Nodo nuevo', latitude: 0, longitude: 0,
        panoramaId: 'NEW', zoneId: 'z_vestibulo_p1', connectedNodeIds: ['P01'],
      ));

      expect(repo.campus.getNode('NEW')!.connectedNodeIds, contains('P01'));
      expect(repo.campus.getNode('P01')!.connectedNodeIds, contains('NEW'));
    });

    test('addNode asigna entry/exit automáticos a una zona vacía', () {
      final campus = MockCampusData.campus.copyWith(
        zones: [...MockCampusData.campus.zones, const ZoneModel(
          id: 'z_nueva', name: 'Zona nueva', floorId: 'piso_1',
          buildingId: 'edificio_A', type: ZoneType.aula,
        )],
      );
      final repo = CampusRepository(campus);
      repo.addNode(const NodeModel(
        id: 'N1', name: 'Nodo 1', latitude: 0, longitude: 0,
        panoramaId: 'N1', zoneId: 'z_nueva',
      ));

      final zone = repo.campus.getZone('z_nueva')!;
      expect(zone.entryNodeId, 'N1');
      expect(zone.exitNodeId, 'N1');
    });

    test('addZone sincroniza conexiones en ambas direcciones', () {
      final repo = CampusRepository(MockCampusData.campus);
      repo.addZone(const ZoneModel(
        id: 'z_ala', name: 'Ala nueva', floorId: 'piso_2',
        buildingId: 'edificio_A', type: ZoneType.aula,
        connectedZoneIds: ['z_aulas_p2'],
      ));

      expect(repo.campus.getZone('z_ala')!.connectedZoneIds, contains('z_aulas_p2'));
      expect(repo.campus.getZone('z_aulas_p2')!.connectedZoneIds, contains('z_ala'));
    });

    test('updateNode quita la referencia inversa al eliminar una conexión', () {
      final repo = CampusRepository(MockCampusData.campus);
      final p02 = repo.campus.getNode('P02')!;
      repo.updateNode(p02.copyWith(
        connectedNodeIds: p02.connectedNodeIds.where((id) => id != 'P01').toList(),
      ));

      expect(repo.campus.getNode('P01')!.connectedNodeIds, isNot(contains('P02')));
    });

    test('removeNode reasigna entry/exit de la zona', () {
      final repo = CampusRepository(MockCampusData.campus);
      repo.removeNode('P02');

      final zone = repo.campus.getZone('z_aulas_p1')!;
      expect(zone.entryNodeId, isNotNull);
      expect(zone.nodeIds, contains(zone.entryNodeId));
      expect(zone.entryNodeId, isNot('P02'));
    });

    test('flujo completo: crear piso 3, zona y nodo → ruta calculable', () {
      final repo = CampusRepository(MockCampusData.campus);

      repo.addFloor(const FloorModel(
        id: 'piso_3', name: 'Piso 3', level: 3, buildingId: 'edificio_A',
      ));
      repo.addZone(const ZoneModel(
        id: 'z_aulas_p3', name: 'Aulas P3', floorId: 'piso_3',
        buildingId: 'edificio_A', type: ZoneType.aula,
        connectedZoneIds: ['z_escaleras_p1'],
      ));
      repo.addNode(const NodeModel(
        id: 'P30', name: 'Pasillo P3', latitude: -16.5009, longitude: -68.1509,
        panoramaId: 'P30', zoneId: 'z_aulas_p3',
        connectedNodeIds: ['P05'], zone: NodeZone.pasillo,
      ));

      // Estructura quedó consistente
      expect(repo.campus.getFloor('piso_3')!.zoneIds, contains('z_aulas_p3'));
      expect(repo.campus.getZone('z_escaleras_p1')!.connectedZoneIds, contains('z_aulas_p3'));
      expect(repo.campus.getNode('P05')!.connectedNodeIds, contains('P30'));
      final zone = repo.campus.getZone('z_aulas_p3')!;
      expect(zone.entryNodeId, 'P30');
      expect(zone.exitNodeId, 'P30');

      // La ruta se puede calcular sin errores
      final result = repo.findRoute('P05', 'P30');
      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.nodePath.first.id, 'P05');
      expect(result.nodePath.last.id, 'P30');

      // Y el campus valida sin errores
      final errors = repo.validate();
      expect(errors.where((e) => e.severity == 'error'), isEmpty, reason: '${errors.length} errores');
    });
  });

  group('Validaciones reforzadas', () {
    CampusModel minimalCampus({
      String? zoneEntry = 'A',
      String? zoneExit = 'B',
      List<String> zoneNodeIds = const ['A', 'B'],
      List<String> aConnections = const ['B'],
      List<String> bConnections = const ['A'],
    }) {
      return CampusModel(
        id: 'c', name: 'Campus test',
        buildings: [const BuildingModel(id: 'b', name: 'B', latitude: 0, longitude: 0, floorIds: ['f'])],
        floors: [const FloorModel(id: 'f', name: 'Piso 1', level: 1, buildingId: 'b', zoneIds: ['z'])],
        zones: [ZoneModel(
          id: 'z', name: 'Zona', floorId: 'f', buildingId: 'b',
          nodeIds: zoneNodeIds, entryNodeId: zoneEntry, exitNodeId: zoneExit,
        )],
        nodes: [
          NodeModel(id: 'A', name: 'A', latitude: 0, longitude: 0, panoramaId: 'A',
              zoneId: 'z', connectedNodeIds: aConnections),
          NodeModel(id: 'B', name: 'B', latitude: 0, longitude: 0, panoramaId: 'B',
              zoneId: 'z', connectedNodeIds: bConnections),
        ],
      );
    }

    test('detecta conexión unidireccional', () {
      final repo = CampusRepository(minimalCampus(aConnections: const ['B'], bConnections: const []));
      final errors = repo.validate();
      expect(errors.any((e) => e.message.contains('unidireccional')), isTrue);
    });

    test('detecta nodo de entrada fuera de la zona', () {
      final repo = CampusRepository(minimalCampus(zoneEntry: 'X'));
      final errors = repo.validate();
      expect(errors.any((e) => e.message.contains('entrada')), isTrue);
    });

    test('detecta piso que referencia zona inexistente', () {
      final campus = minimalCampus();
      final broken = campus.copyWith(
        floors: [campus.floors.first.copyWith(zoneIds: ['z_inexistente'])],
      );
      final errors = CampusRepository(broken).validate();
      expect(errors.any((e) => e.message.contains('zona inexistente')), isTrue);
    });

    test('detecta zona con nodo que pertenece a otra zona', () {
      final campus = minimalCampus();
      final broken = campus.copyWith(
        zones: [campus.zones.first.copyWith(nodeIds: ['A', 'C'])],
        nodes: [
          campus.nodes[0],
          campus.nodes[1],
          const NodeModel(id: 'C', name: 'C', latitude: 0, longitude: 0, panoramaId: 'C'),
        ],
      );
      final errors = CampusRepository(broken).validate();
      expect(errors.any((e) => e.message.contains('pertenece a otra zona')), isTrue);
    });
  });
}
