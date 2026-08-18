import '../models/panorama_model.dart';

abstract class PanoramaRepository {
  Future<List<PanoramaModel>> getAllPanoramas();
  Future<PanoramaModel?> getPanoramaById(String id);
  Future<PanoramaModel?> getPanoramaByNodeId(String nodeId);
  Future<void> savePanorama(PanoramaModel panorama);
  Future<void> deletePanorama(String id);
  Future<void> updatePanorama(PanoramaModel panorama);
  Stream<List<PanoramaModel>> watchAllPanoramas();
  Stream<PanoramaModel?> watchPanoramaById(String id);
}
