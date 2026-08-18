import 'package:flutter/material.dart';

import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/hotspot_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/usecases/navigation_usecases.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';

class PanoramaNavigationState {
  final NodeModel? currentNode;
  final PanoramaModel? currentPanorama;
  final List<NodeModel> connectedNodes;
  final bool isLoading;
  final String? error;
  final List<String> visitedNodeIds;
  final String? destinationNodeId;

  const PanoramaNavigationState({
    this.currentNode,
    this.currentPanorama,
    this.connectedNodes = const [],
    this.isLoading = false,
    this.error,
    this.visitedNodeIds = const [],
    this.destinationNodeId,
  });

  PanoramaNavigationState copyWith({
    NodeModel? currentNode,
    PanoramaModel? currentPanorama,
    List<NodeModel>? connectedNodes,
    bool? isLoading,
    String? error,
    List<String>? visitedNodeIds,
    String? destinationNodeId,
  }) {
    return PanoramaNavigationState(
      currentNode: currentNode ?? this.currentNode,
      currentPanorama: currentPanorama ?? this.currentPanorama,
      connectedNodes: connectedNodes ?? this.connectedNodes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      visitedNodeIds: visitedNodeIds ?? this.visitedNodeIds,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
    );
  }

  bool get hasError => error != null;
  bool get hasCurrentNode => currentNode != null;
  bool get hasDestination => destinationNodeId != null;
  bool get isAtDestination => currentNode?.id == destinationNodeId;
  
  HotspotModel? getHotspotForNode(String targetNodeId) {
    if (currentPanorama == null) return null;
    try {
      return currentPanorama!.hotspots.firstWhere(
        (h) => h.targetNodeId == targetNodeId,
      );
    } catch (_) {
      return null;
    }
  }
}

class PanoramaNavigationProvider extends ChangeNotifier {
  final NavigateToNodeUseCase _navigateToNodeUseCase;
  final GetCurrentPanoramaUseCase _getCurrentPanoramaUseCase;
  final GetConnectedNodesUseCase _getConnectedNodesUseCase;
  
  PanoramaNavigationState _state = const PanoramaNavigationState();
  
  PanoramaNavigationState get state => _state;

  PanoramaNavigationProvider({
    required NavigateToNodeUseCase navigateToNodeUseCase,
    required GetCurrentPanoramaUseCase getCurrentPanoramaUseCase,
    required GetConnectedNodesUseCase getConnectedNodesUseCase,
  })  : _navigateToNodeUseCase = navigateToNodeUseCase,
        _getCurrentPanoramaUseCase = getCurrentPanoramaUseCase,
        _getConnectedNodesUseCase = getConnectedNodesUseCase;

  Future<void> initialize({
    required String startNodeId,
    String? destinationNodeId,
  }) async {
    _state = _state.copyWith(
      isLoading: true,
      error: null,
      destinationNodeId: destinationNodeId,
      visitedNodeIds: [startNodeId],
    );
    notifyListeners();

    try {
      final panorama = await _getCurrentPanoramaUseCase.execute(startNodeId);
      final connectedNodes = await _getConnectedNodesUseCase.execute(startNodeId);

      _state = _state.copyWith(
        currentNode: await _navigateToNodeUseCase.nodeRepository.getNodeById(startNodeId),
        currentPanorama: panorama,
        connectedNodes: connectedNodes,
        isLoading: false,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Error al inicializar: $e',
      );
    }
    notifyListeners();
  }

  Future<void> navigateToNode(String targetNodeId) async {
    if (_state.currentNode == null) return;

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _navigateToNodeUseCase.execute(
      currentNodeId: _state.currentNode!.id,
      targetNodeId: targetNodeId,
    );

    if (result.isSuccess) {
      final visitedIds = List<String>.from(_state.visitedNodeIds);
      if (!visitedIds.contains(targetNodeId)) {
        visitedIds.add(targetNodeId);
      }

      final connectedNodes = await _getConnectedNodesUseCase.execute(targetNodeId);

      _state = _state.copyWith(
        currentNode: result.node,
        currentPanorama: result.panorama,
        connectedNodes: connectedNodes,
        isLoading: false,
        visitedNodeIds: visitedIds,
      );
    } else {
      _state = _state.copyWith(
        isLoading: false,
        error: result.errorMessage,
      );
    }
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
