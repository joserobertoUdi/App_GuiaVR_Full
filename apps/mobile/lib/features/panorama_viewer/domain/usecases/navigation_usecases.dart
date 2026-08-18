import 'package:app_guia_ar/features/navigation/domain/repositories/node_repository.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/repositories/panorama_repository.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';

class GetCurrentPanoramaUseCase {
  final NodeRepository nodeRepository;
  final PanoramaRepository _panoramaRepository;

  GetCurrentPanoramaUseCase({
    required this.nodeRepository,
    required PanoramaRepository panoramaRepository,
  }) : _panoramaRepository = panoramaRepository;

  Future<PanoramaModel?> execute(String nodeId) async {
    final node = await nodeRepository.getNodeById(nodeId);
    if (node == null) return null;
    
    return await _panoramaRepository.getPanoramaByNodeId(nodeId);
  }
}

class NavigateToNodeUseCase {
  final NodeRepository nodeRepository;
  final PanoramaRepository _panoramaRepository;

  NavigateToNodeUseCase({
    required this.nodeRepository,
    required PanoramaRepository panoramaRepository,
  }) : _panoramaRepository = panoramaRepository;

  Future<NavigateResult> execute({
    required String currentNodeId,
    required String targetNodeId,
  }) async {
    final currentNode = await nodeRepository.getNodeById(currentNodeId);
    if (currentNode == null) {
      return NavigateResult.error('Nodo actual no encontrado');
    }

    final targetNode = await nodeRepository.getNodeById(targetNodeId);
    if (targetNode == null) {
      return NavigateResult.error('Nodo destino no encontrado');
    }

    if (!currentNode.connectedNodeIds.contains(targetNodeId)) {
      return NavigateResult.error('Los nodos no están conectados');
    }

    final panorama = await _panoramaRepository.getPanoramaByNodeId(targetNodeId);
    if (panorama == null) {
      return NavigateResult.error('Panorama no encontrado para el nodo destino');
    }

    return NavigateResult.success(
      node: targetNode,
      panorama: panorama,
    );
  }
}

class GetConnectedNodesUseCase {
  final NodeRepository nodeRepository;

  GetConnectedNodesUseCase({
    required this.nodeRepository,
  });

  Future<List<NodeModel>> execute(String nodeId) async {
    return await nodeRepository.getConnectedNodes(nodeId);
  }
}

class NavigateResult {
  final bool isSuccess;
  final String? errorMessage;
  final NodeModel? node;
  final PanoramaModel? panorama;

  NavigateResult._({
    required this.isSuccess,
    this.errorMessage,
    this.node,
    this.panorama,
  });

  factory NavigateResult.success({
    required NodeModel node,
    required PanoramaModel panorama,
  }) {
    return NavigateResult._(
      isSuccess: true,
      node: node,
      panorama: panorama,
    );
  }

  factory NavigateResult.error(String message) {
    return NavigateResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
