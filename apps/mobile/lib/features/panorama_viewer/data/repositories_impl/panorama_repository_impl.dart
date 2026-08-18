import 'package:app_guia_ar/features/panorama_viewer/data/datasources/mock_panoramas_data.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/repositories/panorama_repository.dart';

class PanoramaRepositoryImpl implements PanoramaRepository {
  final List<PanoramaModel> _panoramas = List.from(MockPanoramasData.testPanoramas);

  @override
  Future<List<PanoramaModel>> getAllPanoramas() async {
    return List.unmodifiable(_panoramas);
  }

  @override
  Future<PanoramaModel?> getPanoramaById(String id) async {
    try {
      return _panoramas.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PanoramaModel?> getPanoramaByNodeId(String nodeId) async {
    try {
      return _panoramas.firstWhere((p) => p.nodeId == nodeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePanorama(PanoramaModel panorama) async {
    final index = _panoramas.indexWhere((p) => p.id == panorama.id);
    if (index >= 0) {
      _panoramas[index] = panorama;
    } else {
      _panoramas.add(panorama);
    }
  }

  @override
  Future<void> deletePanorama(String id) async {
    _panoramas.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> updatePanorama(PanoramaModel panorama) async {
    final index = _panoramas.indexWhere((p) => p.id == panorama.id);
    if (index >= 0) {
      _panoramas[index] = panorama;
    }
  }

  @override
  Stream<List<PanoramaModel>> watchAllPanoramas() async* {
    yield List.unmodifiable(_panoramas);
  }

  @override
  Stream<PanoramaModel?> watchPanoramaById(String id) async* {
    yield await getPanoramaById(id);
  }
}
