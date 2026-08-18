import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/features/navigation/domain/models/campus_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/zone_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/data/repositories/campus_repository.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

void main() {
  group('CampusModel', () {
    test('getBuilding returns correct building', () {
      final campus = MockCampusData.campus;
      final building = campus.getBuilding('edificio_A');
      expect(building, isNotNull);
      expect(building!.name, 'Edificio A');
    });

    test('getFloor returns correct floor', () {
      final campus = MockCampusData.campus;
      final floor = campus.getFloor('piso_1');
      expect(floor, isNotNull);
      expect(floor!.level, 1);
    });

    test('getZone returns correct zone', () {
      final campus = MockCampusData.campus;
      final zone = campus.getZone('z_vestibulo_p1');
      expect(zone, isNotNull);
      expect(zone!.name, 'Vestíbulo');
    });

    test('getNode returns correct node', () {
      final campus = MockCampusData.campus;
      final node = campus.getNode('P01');
      expect(node, isNotNull);
      expect(node!.name, 'Entrada Principal');
    });

    test('getFloorsForBuilding returns sorted floors', () {
      final campus = MockCampusData.campus;
      final floors = campus.getFloorsForBuilding('edificio_A');
      expect(floors.length, 2);
      expect(floors[0].level, 1);
      expect(floors[1].level, 2);
    });

    test('getZonesForFloor returns sorted zones by order', () {
      final campus = MockCampusData.campus;
      final zones = campus.getZonesForFloor('piso_1');
      expect(zones.length, 3);
      expect(zones[0].order, 0);
      expect(zones[1].order, 1);
      expect(zones[2].order, 2);
    });

    test('getNodesForZone returns zone nodes', () {
      final campus = MockCampusData.campus;
      final nodes = campus.getNodesForZone('z_aulas_p2');
      expect(nodes.length, 4);
      expect(nodes.map((n) => n.id), containsAll(['P07', 'P_AULA_201', 'P08', 'P_AULA_204']));
    });

    test('serialization roundtrip preserves data', () {
      final campus = MockCampusData.campus;
      final json = campus.toJson();
      final restored = CampusModel.fromJson(json);
      expect(restored.id, campus.id);
      expect(restored.buildings.length, campus.buildings.length);
      expect(restored.floors.length, campus.floors.length);
      expect(restored.zones.length, campus.zones.length);
      expect(restored.nodes.length, campus.nodes.length);
    });
  });

  group('ZoneModel', () {
    test('hasNodes returns true when nodeIds not empty', () {
      final zone = const ZoneModel(
        id: 'z1', name: 'Test', floorId: 'f1', buildingId: 'b1',
        nodeIds: ['n1'],
      );
      expect(zone.hasNodes, true);
    });

    test('hasNodes returns false when nodeIds empty', () {
      final zone = const ZoneModel(
        id: 'z1', name: 'Test', floorId: 'f1', buildingId: 'b1',
        nodeIds: [],
      );
      expect(zone.hasNodes, false);
    });

    test('serialization roundtrip', () {
      final zone = const ZoneModel(
        id: 'z1', name: 'Lab', floorId: 'f1', buildingId: 'b1',
        type: ZoneType.laboratorio, connectedZoneIds: ['z2', 'z3'],
        nodeIds: ['n1', 'n2'], order: 2,
      );
      final json = zone.toJson();
      final restored = ZoneModel.fromJson(json);
      expect(restored.id, zone.id);
      expect(restored.type, ZoneType.laboratorio);
      expect(restored.connectedZoneIds, ['z2', 'z3']);
      expect(restored.order, 2);
    });
  });

  group('NodeModel zoneId', () {
    test('zoneId is preserved in serialization', () {
      final node = NodeModel(
        id: 'N1', name: 'Test', latitude: 0, longitude: 0,
        panoramaId: 'P1', zoneId: 'z_aulas_p1',
      );
      final json = node.toJson();
      expect(json['zoneId'], 'z_aulas_p1');
      final restored = NodeModel.fromJson(json);
      expect(restored.zoneId, 'z_aulas_p1');
    });

    test('zoneId is optional', () {
      final node = NodeModel(
        id: 'N1', name: 'Test', latitude: 0, longitude: 0,
        panoramaId: 'P1',
      );
      expect(node.zoneId, isNull);
    });
  });

  group('CampusRepository - Search', () {
    late CampusRepository repo;

    setUp(() {
      repo = CampusRepository(MockCampusData.campus);
    });

    test('searchByNodeId finds node with full hierarchy', () {
      final result = repo.searchByNodeId('P_AULA_201');
      expect(result, isNotNull);
      expect(result!.node!.name, 'Aula 201');
      expect(result.zone, isNotNull);
      expect(result.zone!.name, 'Aulas P2');
      expect(result.floor, isNotNull);
      expect(result.floor!.level, 2);
      expect(result.building, isNotNull);
      expect(result.building!.name, 'Edificio A');
      expect(result.matchType, 'node_id');
    });

    test('searchByNodeId returns null for nonexistent', () {
      final result = repo.searchByNodeId('NONEXISTENT');
      expect(result, isNull);
    });

    test('searchByName finds node by name', () {
      final results = repo.searchByName('Aula 201');
      expect(results.isNotEmpty, true);
      final exact = results.firstWhere(
        (r) => r.node?.name == 'Aula 201',
        orElse: () => const SearchResult(matchType: ''),
      );
      expect(exact.node, isNotNull);
      expect(exact.zone!.name, 'Aulas P2');
    });

    test('searchByName finds node by id pattern', () {
      final results = repo.searchByName('P02');
      expect(results.isNotEmpty, true);
    });

    test('searchByName finds node by destinationLabel', () {
      final results = repo.searchByName('Salida Emergencia');
      expect(results.isNotEmpty, true);
      expect(results.first.node, isNotNull);
    });

    test('searchByName finds zone by name', () {
      final results = repo.searchByName('Escaleras');
      expect(results.isNotEmpty, true);
      expect(results.any((r) => r.matchType == 'zone'), true);
    });

    test('searchByName is case insensitive', () {
      final results = repo.searchByName('aula 204');
      expect(results.isNotEmpty, true);
    });

    test('searchByName partial match works', () {
      final results = repo.searchByName('lab');
      expect(results.isNotEmpty, true);
    });

    test('searchByName empty query returns empty', () {
      final results = repo.searchByName('');
      expect(results.isEmpty, true);
    });

    test('searchByName "aula 101" finds node with zone hierarchy', () {
      final results = repo.searchByName('aula 101');
      expect(results.isNotEmpty, true);
      final aula = results.firstWhere(
        (r) => r.node?.id == 'P_AULA_101',
        orElse: () => const SearchResult(matchType: ''),
      );
      expect(aula.node, isNotNull);
      expect(aula.zone, isNotNull);
      expect(aula.zone!.name, 'Aulas P1');
      expect(aula.floor, isNotNull);
      expect(aula.floor!.level, 1);
    });

    test('searchByName "salida" finds emergency exit with full context', () {
      final results = repo.searchByName('salida');
      expect(results.isNotEmpty, true);
      final exit = results.firstWhere(
        (r) => r.node?.id == 'P09',
        orElse: () => const SearchResult(matchType: ''),
      );
      expect(exit.node, isNotNull);
      expect(exit.zone!.name, 'Salida Emergencia');
      expect(exit.floor!.level, 2);
    });
  });

  group('CampusRepository - Zone-Level Route', () {
    late CampusRepository repo;

    setUp(() {
      repo = CampusRepository(MockCampusData.campus);
    });

    test('findRoute P01 to P09 traverses all zones', () {
      final result = repo.findRoute('P01', 'P09');
      expect(result.isSuccess, true);
      expect(result.zonePath.length, greaterThanOrEqualTo(3));
      expect(result.nodePath.length, greaterThanOrEqualTo(3));

      final zoneIds = result.zonePath.map((z) => z.id).toList();
      expect(zoneIds, contains('z_vestibulo_p1'));
      expect(zoneIds, contains('z_escaleras_p1'));
      expect(zoneIds, contains('z_aulas_p2'));
    });

    test('findRoute P01 to P_AULA_201 goes through zones', () {
      final result = repo.findRoute('P01', 'P_AULA_201');
      expect(result.isSuccess, true);
      expect(result.zonePath.length, greaterThanOrEqualTo(3));

      final nodeIds = result.nodePath.map((n) => n.id).toList();
      expect(nodeIds.first, 'P01');
      expect(nodeIds.last, 'P_AULA_201');
    });

    test('findRoute same zone uses node-only path', () {
      final result = repo.findRoute('P07', 'P_AULA_204');
      expect(result.isSuccess, true);
      expect(result.zonePath.length, 1);
      expect(result.nodePath.first.id, 'P07');
      expect(result.nodePath.last.id, 'P_AULA_204');
    });

    test('findRoute nonexistent start returns error', () {
      final result = repo.findRoute('NONEXISTENT', 'P09');
      expect(result.hasError, true);
    });

    test('findRoute nonexistent end returns error', () {
      final result = repo.findRoute('P01', 'NONEXISTENT');
      expect(result.hasError, true);
    });

    test('findRoute P_AULA_101 to P_AULA_204 crosses floors via zones', () {
      final result = repo.findRoute('P_AULA_101', 'P_AULA_204');
      expect(result.isSuccess, true);
      expect(result.zonePath.length, greaterThanOrEqualTo(4));

      final floorLevels = result.nodePath.map((n) => n.floorLevel).toSet();
      expect(floorLevels, containsAll(['1', '2']));
    });

    test('findRoute zone path follows correct order: vestibulo→aulas→escaleras→vestibulo_p2→aulas_p2', () {
      final result = repo.findRoute('P01', 'P_AULA_204');
      expect(result.isSuccess, true);

      final zoneIds = result.zonePath.map((z) => z.id).toList();
      expect(zoneIds, contains('z_vestibulo_p1'));
      expect(zoneIds, contains('z_aulas_p1'));
      expect(zoneIds, contains('z_escaleras_p1'));
      expect(zoneIds, contains('z_vestibulo_p2'));
      expect(zoneIds, contains('z_aulas_p2'));
    });

    test('findRoute P02 to P03 (same zone) returns direct path', () {
      final result = repo.findRoute('P02', 'P03');
      expect(result.isSuccess, true);
      expect(result.zonePath.length, 1);
      expect(result.zonePath.first.id, 'z_aulas_p1');
    });

    test('findRoute P01 to P03 goes through vestibulo then aulas', () {
      final result = repo.findRoute('P01', 'P03');
      expect(result.isSuccess, true);
      expect(result.zonePath.length, 2);
      expect(result.zonePath[0].id, 'z_vestibulo_p1');
      expect(result.zonePath[1].id, 'z_aulas_p1');
    });
  });

  group('CampusRepository - Validation', () {
    test('valid campus has no errors', () {
      final repo = CampusRepository(MockCampusData.campus);
      final errors = repo.validate();
      expect(errors.isEmpty, true);
    });

    test('detects zone without nodes', () {
      final campus = MockCampusData.campus.copyWith(
        zones: [...MockCampusData.campus.zones, const ZoneModel(
          id: 'z_empty', name: 'Empty Zone', floorId: 'piso_1',
          buildingId: 'edificio_A', nodeIds: [],
        )],
      );
      final repo = CampusRepository(campus);
      final errors = repo.validate();
      expect(errors.any((e) => e.severity == 'warning'), true);
    });

    test('detects node with invalid zoneId', () {
      final campus = MockCampusData.campus.copyWith(
        nodes: [...MockCampusData.campus.nodes, NodeModel(
          id: 'BAD', name: 'Bad Node', latitude: 0, longitude: 0,
          panoramaId: 'P_BAD', zoneId: 'nonexistent_zone',
        )],
      );
      final repo = CampusRepository(campus);
      final errors = repo.validate();
      expect(errors.any((e) => e.severity == 'error'), true);
    });

    test('detects duplicate node IDs', () {
      final campus = MockCampusData.campus.copyWith(
        nodes: [...MockCampusData.campus.nodes, MockCampusData.campus.nodes.first],
      );
      final repo = CampusRepository(campus);
      final errors = repo.validate();
      expect(errors.any((e) => e.message.contains('duplicado')), true);
    });
  });

  group('CampusRepository - CRUD', () {
    test('addNode adds to zone', () {
      final repo = CampusRepository(MockCampusData.campus);
      final initialCount = repo.campus.nodes.length;
      repo.addNode(const NodeModel(
        id: 'NEW', name: 'New Node', latitude: 0, longitude: 0,
        panoramaId: 'P_NEW', zoneId: 'z_vestibulo_p1',
      ));
      expect(repo.campus.nodes.length, initialCount + 1);
      final zone = repo.campus.getZone('z_vestibulo_p1');
      expect(zone!.nodeIds, contains('NEW'));
    });

    test('removeNode removes from zone', () {
      final repo = CampusRepository(MockCampusData.campus);
      final initialCount = repo.campus.nodes.length;
      repo.removeNode('P01');
      expect(repo.campus.nodes.length, initialCount - 1);
      final zone = repo.campus.getZone('z_vestibulo_p1');
      expect(zone!.nodeIds.contains('P01'), false);
    });

    test('removeNode cleans up connections', () {
      final repo = CampusRepository(MockCampusData.campus);
      repo.removeNode('P02');
      final p01 = repo.campus.getNode('P01');
      expect(p01!.connectedNodeIds.contains('P02'), false);
    });
  });

  group('CampusRepository - JSON Export/Import', () {
    test('export produces valid JSON', () {
      final repo = CampusRepository(MockCampusData.campus);
      final json = repo.exportToJson(pretty: false);
      expect(json.isNotEmpty, true);
      expect(json.contains('"id"'), true);
    });

    test('import restores campus correctly', () {
      final repo = CampusRepository(MockCampusData.campus);
      final json = repo.exportToJson(pretty: false);
      final restored = CampusRepository.fromJson(json);
      expect(restored.campus.nodes.length, repo.campus.nodes.length);
      expect(restored.campus.zones.length, repo.campus.zones.length);
    });

    test('export pretty produces indented JSON', () {
      final repo = CampusRepository(MockCampusData.campus);
      final json = repo.exportToJson(pretty: true);
      expect(json.contains('\n'), true);
      expect(json.contains('  '), true);
    });
  });

  group('MockCampusData backward compatibility', () {
    test('allNodes returns all nodes', () {
      expect(MockCampusData.allNodes.length, 12);
    });

    test('getNodeById works', () {
      final node = MockCampusData.getNodeById('P01');
      expect(node, isNotNull);
      expect(node!.name, 'Entrada Principal');
    });

    test('getConnectedNodes works', () {
      final connected = MockCampusData.getConnectedNodes('P02');
      expect(connected.length, 3);
      expect(connected.map((n) => n.id), containsAll(['P01', 'P03', 'P_AULA_101']));
    });

    test('getNodesByFloor works', () {
      final p1 = MockCampusData.getNodesByFloor('1');
      expect(p1.isNotEmpty, true);
      expect(p1.every((n) => n.floorLevel == '1'), true);
    });

    test('getDestinations works', () {
      final dests = MockCampusData.getDestinations();
      expect(dests.isNotEmpty, true);
    });

    test('calculateRoute returns active route', () {
      final route = MockCampusData.calculateRoute(startId: 'P01', endId: 'P09');
      expect(route.status.name, 'active');
      expect(route.nodes.length, greaterThanOrEqualTo(3));
    });

    test('calculateRoute P01 to P_AULA_201 goes through zones', () {
      final route = MockCampusData.calculateRoute(startId: 'P01', endId: 'P_AULA_201');
      expect(route.status.name, 'active');
      expect(route.nodes.first.id, 'P01');
      expect(route.nodes.last.id, 'P_AULA_201');
      expect(route.steps.isNotEmpty, true);
    });

    test('calculateRoute returns failed for nonexistent', () {
      final route = MockCampusData.calculateRoute(startId: 'P01', endId: 'NONEXISTENT');
      expect(route.status.name, 'failed');
    });

    test('addNode persists to campus', () {
      final initial = MockCampusData.allNodes.length;
      MockCampusData.addNode(const NodeModel(
        id: 'TEST_ADD', name: 'Test', latitude: 0, longitude: 0,
        panoramaId: 'P_TEST',
      ));
      expect(MockCampusData.allNodes.length, initial + 1);
      MockCampusData.removeNode('TEST_ADD');
    });
  });
}
