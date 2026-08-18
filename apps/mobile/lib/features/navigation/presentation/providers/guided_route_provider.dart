import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';

class GuidedRouteProvider extends ChangeNotifier {
  RouteModel? _route;
  Timer? _quickPreviewTimer;
  Timer? _wrongDirectionTimer;
  bool _isDisposed = false;

  RouteModel? get route => _route;
  NodeModel? get currentNode => _route?.currentNode;
  NodeModel? get destinationNode => _route?.destinationNode;
  bool get isActive => _route?.isActive ?? false;
  bool get isWrongDirection => _route?.isWrongDirection ?? false;
  bool get isCompleted => _route?.isCompleted ?? false;
  bool get isQuickPreview => _route?.isQuick ?? false;
  double get progress => _route?.progress ?? 0;
  String get progressText => _route?.progressText ?? '0 / 0';
  String? get instruction => _route?.currentStep?.instruction;
  int get remainingSteps => _route?.remainingSteps ?? 0;

  void startRoute({
    required String startNodeId,
    required String endNodeId,
    RouteMode mode = RouteMode.guidedWalk,
  }) {
    _route = MockCampusData.calculateRoute(
      startId: startNodeId,
      endId: endNodeId,
      mode: mode,
    );

    if (mode == RouteMode.quickPreview) {
      _startQuickPreview();
    }

    notifyListeners();
  }

  void _startQuickPreview() {
    _quickPreviewTimer?.cancel();
    _quickPreviewTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isDisposed) return;
      advanceStep();
    });
  }

  void advanceStep() {
    if (_route == null || _route!.isCompleted) return;

    final nextIndex = _route!.currentStepIndex + 1;
    if (nextIndex >= _route!.nodes.length) {
      _completeRoute();
      return;
    }

    _route = _route!.copyWith(
      currentStepIndex: nextIndex,
      status: RouteStatus.active,
      isWrongDirection: false,
    );
    notifyListeners();
  }

  void previousStep() {
    if (_route == null || _route!.currentStepIndex <= 0) return;

    _route = _route!.copyWith(
      currentStepIndex: _route!.currentStepIndex - 1,
      status: RouteStatus.active,
      isWrongDirection: false,
    );
    notifyListeners();
  }

  void jumpToStep(int index) {
    if (_route == null || index < 0 || index >= _route!.nodes.length) return;

    _route = _route!.copyWith(
      currentStepIndex: index,
      status: RouteStatus.active,
      isWrongDirection: false,
    );
    notifyListeners();
  }

  void simulateWrongDirection() {
    if (_route == null || !_route!.isActive) return;

    _route = _route!.copyWith(
      isWrongDirection: true,
      status: RouteStatus.wrongDirection,
    );
    notifyListeners();

    _wrongDirectionTimer?.cancel();
    _wrongDirectionTimer = Timer(const Duration(seconds: 5), () {
      if (_isDisposed) return;
      _route = _route!.copyWith(
        isWrongDirection: false,
        status: RouteStatus.active,
      );
      notifyListeners();
    });
  }

  void _completeRoute() {
    _quickPreviewTimer?.cancel();
    _route = _route!.copyWith(
      status: RouteStatus.completed,
      currentStepIndex: _route!.nodes.length - 1,
    );
    notifyListeners();
  }

  void pauseRoute() {
    if (_route == null) return;
    _quickPreviewTimer?.cancel();
    _route = _route!.copyWith(status: RouteStatus.paused);
    notifyListeners();
  }

  void resumeRoute() {
    if (_route == null) return;
    _route = _route!.copyWith(status: RouteStatus.active);
    if (_route!.isQuick) {
      _startQuickPreview();
    }
    notifyListeners();
  }

  void stopRoute() {
    _quickPreviewTimer?.cancel();
    _wrongDirectionTimer?.cancel();
    _route = null;
    notifyListeners();
  }

  double getBearingToNextNode() {
    if (_route == null || _route!.currentNode == null) return 0;
    final next = _route!.nextStep;
    if (next == null) return 0;

    final targetNode = MockCampusData.getNodeById(next.nodeId);
    if (targetNode == null) return 0;

    final current = _route!.currentNode!;
    final dLat = targetNode.latitude - current.latitude;
    final dLon = targetNode.longitude - current.longitude;

    if (dLon == 0 && dLat == 0) return 0;
    return (90 - (dLat / dLon) * 180 / 3.14159) % 360;
  }

  String getDirectionLabel() {
    final bearing = getBearingToNextNode();
    if (bearing >= 337.5 || bearing < 22.5) return 'Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Noreste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Este';
    if (bearing >= 112.5 && bearing < 157.5) return 'Sureste';
    if (bearing >= 157.5 && bearing < 202.5) return 'Sur';
    if (bearing >= 202.5 && bearing < 247.5) return 'Suroeste';
    if (bearing >= 247.5 && bearing < 292.5) return 'Oeste';
    return 'Noroeste';
  }

  IconData getDirectionIcon() {
    final bearing = getBearingToNextNode();
    if (bearing >= 315 || bearing < 45) return Icons.arrow_upward;
    if (bearing >= 45 && bearing < 135) return Icons.arrow_forward;
    if (bearing >= 135 && bearing < 225) return Icons.arrow_downward;
    return Icons.arrow_back;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _quickPreviewTimer?.cancel();
    _wrongDirectionTimer?.cancel();
    super.dispose();
  }
}
