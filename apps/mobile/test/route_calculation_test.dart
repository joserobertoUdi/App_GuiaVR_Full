import 'package:flutter_test/flutter_test.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

void main() {
  group('RouteCalculation', () {
    test('findRoute returns path between connected nodes', () {
      final path = MockCampusData.findRoute('P01', 'P03');
      expect(path, isNotEmpty);
      expect(path.first.id, 'P01');
      expect(path.last.id, 'P03');
    });

    test('findRoute returns empty for non-existent start', () {
      final path = MockCampusData.findRoute('NONEXISTENT', 'P03');
      expect(path, isEmpty);
    });

    test('findRoute returns empty for non-existent end', () {
      final path = MockCampusData.findRoute('P01', 'NONEXISTENT');
      expect(path, isEmpty);
    });

    test('findRoute returns shortest path', () {
      final path = MockCampusData.findRoute('P01', 'P_AULA_101');
      expect(path.length, 3);
      expect(path[0].id, 'P01');
      expect(path[1].id, 'P02');
      expect(path[2].id, 'P_AULA_101');
    });

    test('calculateRoute returns valid route model', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P03',
      );

      expect(route.id, isNotEmpty);
      expect(route.startNodeId, 'P01');
      expect(route.endNodeId, 'P03');
      expect(route.status, RouteStatus.active);
      expect(route.nodeIds, isNotEmpty);
      expect(route.steps, isNotEmpty);
    });

    test('calculateRoute returns failed status for no route', () {
      final route = MockCampusData.calculateRoute(
        startId: 'NONEXISTENT',
        endId: 'P03',
      );

      expect(route.status, RouteStatus.failed);
      expect(route.errorMessage, isNotNull);
    });

    test('calculateRoute with guidedWalk mode', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
        mode: RouteMode.guidedWalk,
      );

      expect(route.mode, RouteMode.guidedWalk);
      expect(route.isGuided, isTrue);
      expect(route.isQuick, isFalse);
    });

    test('calculateRoute with quickPreview mode', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
        mode: RouteMode.quickPreview,
      );

      expect(route.mode, RouteMode.quickPreview);
      expect(route.isQuick, isTrue);
      expect(route.isGuided, isFalse);
    });

    test('route steps have instructions', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
      );

      for (final step in route.steps) {
        expect(step.instruction, isNotNull);
        expect(step.instruction!.isNotEmpty, isTrue);
      }
    });

    test('route steps have bearing and distance', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
      );

      for (final step in route.steps) {
        expect(step.bearingToNext, isNotNull);
        expect(step.distanceToNext, isNotNull);
        expect(step.distanceToNext!, greaterThan(0));
      }
    });

    test('route total distance is sum of steps', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
      );

      final sumDistance = route.steps.fold<double>(
        0,
        (sum, step) => sum + (step.distanceToNext ?? 0),
      );

      expect(route.totalDistance, closeTo(sumDistance, 0.1));
    });

    test('route progress tracking works', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
      );

      expect(route.progress, 0.0);

      final routeAtStep = route.copyWith(currentStepIndex: 1);
      expect(routeAtStep.progress, greaterThan(0));

      final routeCompleted = route.copyWith(
        currentStepIndex: route.nodes.length - 1,
        status: RouteStatus.completed,
      );
      expect(routeCompleted.progress, 1.0);
      expect(routeCompleted.isCompleted, isTrue);
    });

    test('route current and destination nodes are correct', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_101',
      );

      expect(route.currentNode?.id, 'P01');
      expect(route.destinationNode?.id, 'P_AULA_101');
    });

    test('route cross-floor navigation works', () {
      final route = MockCampusData.calculateRoute(
        startId: 'P01',
        endId: 'P_AULA_201',
      );

      expect(route.status, RouteStatus.active);
      expect(route.nodeIds, contains('P05'));
      expect(route.nodeIds, contains('P06'));
    });
  });
}
