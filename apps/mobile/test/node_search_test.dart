import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

void main() {
  group('NodeSearch', () {
    test('getNodeById returns correct node', () {
      final node = MockCampusData.getNodeById('P01');
      expect(node, isNotNull);
      expect(node!.id, 'P01');
      expect(node.name, 'Entrada Principal');
    });

    test('getNodeById returns null for non-existent node', () {
      final node = MockCampusData.getNodeById('NONEXISTENT');
      expect(node, isNull);
    });

    test('getNodesByFloor returns correct floor nodes', () {
      final floor1 = MockCampusData.getNodesByFloor('1');
      final floor2 = MockCampusData.getNodesByFloor('2');

      expect(floor1.length, greaterThan(0));
      expect(floor2.length, greaterThan(0));

      for (final node in floor1) {
        expect(node.floorLevel, '1');
      }
      for (final node in floor2) {
        expect(node.floorLevel, '2');
      }
    });

    test('getDestinations returns only destination nodes', () {
      final destinations = MockCampusData.getDestinations();

      expect(destinations.length, greaterThan(0));
      for (final node in destinations) {
        expect(node.isDestination, isTrue);
      }
    });

    test('getConnectedNodes returns correct connections', () {
      final connected = MockCampusData.getConnectedNodes('P02');

      expect(connected.length, greaterThan(0));
      expect(connected.any((n) => n.id == 'P01'), isTrue);
      expect(connected.any((n) => n.id == 'P03'), isTrue);
    });

    test('getConnectedNodes returns empty for non-existent node', () {
      final connected = MockCampusData.getConnectedNodes('NONEXISTENT');
      expect(connected, isEmpty);
    });

    test('getAllNodes returns all campus nodes', () {
      final allNodes = MockCampusData.getAllNodes();
      expect(allNodes.length, 12);
    });

    test('node properties are correctly set', () {
      final node = MockCampusData.getNodeById('P_AULA_101');
      expect(node, isNotNull);
      expect(node!.zone, NodeZone.destino);
      expect(node.destinationLabel, 'Aula 101');
      expect(node.isDestination, isTrue);
    });

    test('node connectedNodeIds are valid', () {
      final allNodes = MockCampusData.getAllNodes();

      for (final node in allNodes) {
        for (final connectedId in node.connectedNodeIds) {
          final connectedNode = MockCampusData.getNodeById(connectedId);
          expect(connectedNode, isNotNull,
              reason: 'Node ${node.id} references non-existent node $connectedId');
        }
      }
    });

    test('node connections are bidirectional', () {
      final allNodes = MockCampusData.getAllNodes();

      for (final node in allNodes) {
        for (final connectedId in node.connectedNodeIds) {
          final connectedNode = MockCampusData.getNodeById(connectedId);
          expect(connectedNode!.connectedNodeIds.contains(node.id), isTrue,
              reason: 'Node ${node.id} connects to $connectedId but not vice versa');
        }
      }
    });
  });
}
