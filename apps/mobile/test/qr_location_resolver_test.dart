import 'package:flutter_test/flutter_test.dart';

import 'package:campus_domain/campus_domain.dart';
import 'package:app_guia_ar/features/navigation/presentation/utils/qr_location_resolver.dart';

void main() {
  final campus = _buildCampus();

  group('QrLocationResolver - nodo', () {
    test('resuelve por id', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.node,
          id: 'P01',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P01');
    });

    test('resuelve por panoramaId (instancia física del backend)', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.node,
          id: 'pano_entrada',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P01');
      expect(result.qrId, 'P01');
    });

    test('resuelve por nombre normalizado (acentos/case/espacios)', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.node,
          id: '',
          name: 'VESTIBULO AULA',
        ),
        campus: campus,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P02');
    });

    test('id desconocido y sin nombre devuelve null', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.node,
          id: 'NO_EXISTE',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNull);
    });
  });

  group('QrLocationResolver - zona', () {
    test('resuelve a su nodo de entrada', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.zone,
          id: 'z_aulas_p1',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P01');
    });

    test('zona con entrada inexistente cae al primer nodo disponible', () {
      final mutated = campus.copyWith(
        zones: [
          campus.zones.first.copyWith(entryNodeId: 'NOPE'),
        ],
      );
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.zone,
          id: 'z_aulas_p1',
          name: '',
        ),
        campus: mutated,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P01');
    });

    test('zona sin entradas ni nodeIds cae a un nodo del piso', () {
      final mutated = campus.copyWith(
        zones: [
          campus.zones.first.copyWith(entryNodeId: null, nodeIds: []),
        ],
      );
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.zone,
          id: 'z_aulas_p1',
          name: '',
        ),
        campus: mutated,
      );
      expect(result, isNotNull);
      expect(result!.node.id, isNotNull);
    });

    test('zona inexistente devuelve null', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.zone,
          id: 'z_inexistente',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNull);
    });
  });

  group('QrLocationResolver - piso y edificio', () {
    test('piso resuelve al primer nodo de su zona', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.floor,
          id: 'piso_1',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P01');
      expect(result.locationLabel, contains('piso_1'));
    });

    test('edificio resuelve al primer nodo de su primer piso', () {
      final result = QrLocationResolver.resolve(
        const CampusQrReference(
          type: CampusQrEntityType.building,
          id: 'edificio_A',
          name: '',
        ),
        campus: campus,
      );
      expect(result, isNotNull);
      expect(result!.node.id, 'P01');
    });
  });
}

CampusModel _buildCampus() {
  return CampusModel(
    id: 'campus_test',
    name: 'Campus Test',
    buildings: [
      const BuildingModel(
        id: 'edificio_A',
        name: 'Edificio A',
        latitude: -16.5005,
        longitude: -68.1505,
        floorIds: ['piso_1'],
      ),
    ],
    floors: [
      const FloorModel(
        id: 'piso_1',
        name: 'Piso 1',
        level: 1,
        buildingId: 'edificio_A',
        zoneIds: ['z_aulas_p1'],
      ),
    ],
    zones: [
      ZoneModel(
        id: 'z_aulas_p1',
        name: 'Aulas P1',
        floorId: 'piso_1',
        buildingId: 'edificio_A',
        type: ZoneType.aula,
        nodeIds: ['P01', 'P02'],
        entryNodeId: 'P01',
        exitNodeId: 'P02',
      ),
    ],
    nodes: [
      NodeModel(
        id: 'P01',
        name: 'Entrada Principal',
        latitude: -16.5001,
        longitude: -68.1501,
        floorLevel: '1',
        buildingId: 'edificio_A',
        panoramaId: 'pano_entrada',
        connectedNodeIds: ['P02'],
        zoneId: 'z_aulas_p1',
      ),
      NodeModel(
        id: 'P02',
        name: 'Vestíbulo Aula',
        latitude: -16.5002,
        longitude: -68.1502,
        floorLevel: '1',
        buildingId: 'edificio_A',
        panoramaId: 'P02',
        connectedNodeIds: ['P01'],
        zoneId: 'z_aulas_p1',
      ),
    ],
  );
}