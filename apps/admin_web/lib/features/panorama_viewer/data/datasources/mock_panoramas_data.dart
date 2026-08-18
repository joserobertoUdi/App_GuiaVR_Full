import 'package:admin_web/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/hotspot_model.dart';

class MockPanoramasData {
  MockPanoramasData._();

  static const List<PanoramaModel> testPanoramas = [
    PanoramaModel(
      id: 'P01', nodeId: 'P01', imageUrl: 'assets/panoramas/panorama_001.jpg',
      hotspots: [HotspotModel(id: 'h_P01_P02', nodeId: 'P01', targetNodeId: 'P02', yaw: 90, pitch: 0, label: 'Entrar al pasillo')],
    ),
    PanoramaModel(
      id: 'P02', nodeId: 'P02', imageUrl: 'assets/panoramas/panorama_002.jpg',
      hotspots: [
        HotspotModel(id: 'h_P02_P01', nodeId: 'P02', targetNodeId: 'P01', yaw: 270, pitch: 0, label: 'Volver a entrada'),
        HotspotModel(id: 'h_P02_P03', nodeId: 'P02', targetNodeId: 'P03', yaw: 90, pitch: 0, label: 'Seguir pasillo'),
        HotspotModel(id: 'h_P02_101', nodeId: 'P02', targetNodeId: 'P_AULA_101', yaw: 45, pitch: 0, label: 'Aula 101'),
      ],
    ),
    PanoramaModel(
      id: 'P_AULA_101', nodeId: 'P_AULA_101', imageUrl: 'assets/panoramas/panorama_001.jpg',
      hotspots: [HotspotModel(id: 'h_101_P02', nodeId: 'P_AULA_101', targetNodeId: 'P02', yaw: 225, pitch: 0, label: 'Salir al pasillo')],
    ),
    PanoramaModel(
      id: 'P03', nodeId: 'P03', imageUrl: 'assets/panoramas/panorama_003.jpg',
      hotspots: [
        HotspotModel(id: 'h_P03_P02', nodeId: 'P03', targetNodeId: 'P02', yaw: 270, pitch: 0, label: 'Volver'),
        HotspotModel(id: 'h_P03_P04', nodeId: 'P03', targetNodeId: 'P04', yaw: 90, pitch: 0, label: 'Hacia escaleras'),
      ],
    ),
    PanoramaModel(
      id: 'P04', nodeId: 'P04', imageUrl: 'assets/panoramas/panorama_004.jpg',
      hotspots: [
        HotspotModel(id: 'h_P04_P03', nodeId: 'P04', targetNodeId: 'P03', yaw: 270, pitch: 0, label: 'Volver al pasillo'),
        HotspotModel(id: 'h_P04_P05', nodeId: 'P04', targetNodeId: 'P05', yaw: 0, pitch: -15, label: 'Subir escaleras'),
      ],
    ),
    PanoramaModel(
      id: 'P05', nodeId: 'P05', imageUrl: 'assets/panoramas/panorama_001.jpg',
      hotspots: [
        HotspotModel(id: 'h_P05_P04', nodeId: 'P05', targetNodeId: 'P04', yaw: 180, pitch: 15, label: 'Bajar escaleras'),
        HotspotModel(id: 'h_P05_P06', nodeId: 'P05', targetNodeId: 'P06', yaw: 0, pitch: 0, label: 'Llegar piso 2'),
      ],
    ),
    PanoramaModel(
      id: 'P06', nodeId: 'P06', imageUrl: 'assets/panoramas/panorama_002.jpg',
      hotspots: [
        HotspotModel(id: 'h_P06_P05', nodeId: 'P06', targetNodeId: 'P05', yaw: 0, pitch: 15, label: 'Bajar escaleras'),
        HotspotModel(id: 'h_P06_P07', nodeId: 'P06', targetNodeId: 'P07', yaw: 180, pitch: 0, label: 'Entrar al pasillo P2'),
      ],
    ),
    PanoramaModel(
      id: 'P07', nodeId: 'P07', imageUrl: 'assets/panoramas/panorama_003.jpg',
      hotspots: [
        HotspotModel(id: 'h_P07_P06', nodeId: 'P07', targetNodeId: 'P06', yaw: 0, pitch: 0, label: 'Volver escalera'),
        HotspotModel(id: 'h_P07_P08', nodeId: 'P07', targetNodeId: 'P08', yaw: 90, pitch: 0, label: 'Seguir pasillo'),
        HotspotModel(id: 'h_P07_201', nodeId: 'P07', targetNodeId: 'P_AULA_201', yaw: 45, pitch: 0, label: 'Aula 201'),
      ],
    ),
    PanoramaModel(
      id: 'P_AULA_201', nodeId: 'P_AULA_201', imageUrl: 'assets/panoramas/panorama_004.jpg',
      hotspots: [HotspotModel(id: 'h_201_P07', nodeId: 'P_AULA_201', targetNodeId: 'P07', yaw: 225, pitch: 0, label: 'Salir al pasillo')],
    ),
    PanoramaModel(
      id: 'P08', nodeId: 'P08', imageUrl: 'assets/panoramas/panorama_001.jpg',
      hotspots: [
        HotspotModel(id: 'h_P08_P07', nodeId: 'P08', targetNodeId: 'P07', yaw: 270, pitch: 0, label: 'Volver'),
        HotspotModel(id: 'h_P08_P09', nodeId: 'P08', targetNodeId: 'P09', yaw: 90, pitch: 0, label: 'Salida emergencia'),
        HotspotModel(id: 'h_P08_204', nodeId: 'P08', targetNodeId: 'P_AULA_204', yaw: 45, pitch: 0, label: 'Aula 204'),
      ],
    ),
    PanoramaModel(
      id: 'P_AULA_204', nodeId: 'P_AULA_204', imageUrl: 'assets/panoramas/panorama_002.jpg',
      hotspots: [HotspotModel(id: 'h_204_P08', nodeId: 'P_AULA_204', targetNodeId: 'P08', yaw: 225, pitch: 0, label: 'Salir al pasillo')],
    ),
    PanoramaModel(
      id: 'P09', nodeId: 'P09', imageUrl: 'assets/panoramas/panorama_003.jpg',
      hotspots: [HotspotModel(id: 'h_P09_P08', nodeId: 'P09', targetNodeId: 'P08', yaw: 270, pitch: 0, label: 'Volver al pasillo')],
    ),
  ];

  static PanoramaModel? getPanoramaById(String id) {
    try { return testPanoramas.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }

  static PanoramaModel? getPanoramaByNodeId(String nodeId) {
    try { return testPanoramas.firstWhere((p) => p.nodeId == nodeId); } catch (_) { return null; }
  }

  static List<PanoramaModel> getAllPanoramas() => testPanoramas;

  static PanoramaModel getOrCreateForNode(String nodeId) {
    return getPanoramaByNodeId(nodeId) ??
        PanoramaModel(
          id: nodeId,
          nodeId: nodeId,
          imageUrl: 'assets/panoramas/panorama_001.jpg',
          hotspots: [],
        );
  }
}