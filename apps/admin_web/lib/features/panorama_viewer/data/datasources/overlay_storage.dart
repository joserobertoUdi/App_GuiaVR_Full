import 'package:admin_web/core/utils/platform_storage.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/panorama_overlay_model.dart';

class OverlayStorage {
  OverlayStorage._();

  static const String _storageKey = 'overlays_json';

  static final Map<String, List<PanoramaOverlay>> _overlays = {};

  static List<PanoramaOverlay> getOverlaysForNode(String nodeId) {
    return List.unmodifiable(_overlays[nodeId] ?? []);
  }

  static void addOverlay(PanoramaOverlay overlay) {
    final nodeOverlays = _overlays[overlay.nodeId] ?? [];
    nodeOverlays.add(overlay);
    _overlays[overlay.nodeId] = nodeOverlays;
    _save();
  }

  static void updateOverlay(PanoramaOverlay overlay) {
    final nodeOverlays = _overlays[overlay.nodeId];
    if (nodeOverlays == null) return;
    final index = nodeOverlays.indexWhere((o) => o.id == overlay.id);
    if (index >= 0) {
      nodeOverlays[index] = overlay;
    }
    _save();
  }

  static void removeOverlay(String nodeId, String overlayId) {
    final nodeOverlays = _overlays[nodeId];
    if (nodeOverlays == null) return;
    nodeOverlays.removeWhere((o) => o.id == overlayId);
    _save();
  }

  static List<String> getNodeIdsWithOverlays() {
    return _overlays.keys.where((id) => _overlays[id]!.isNotEmpty).toList();
  }

  static void clear() {
    _overlays.clear();
  }

  static Map<String, dynamic> exportToJson() {
    final data = <String, dynamic>{};
    for (final entry in _overlays.entries) {
      if (entry.value.isNotEmpty) {
        data[entry.key] = entry.value.map((o) => o.toJson()).toList();
      }
    }
    return data;
  }

  static void importFromJson(Map<String, dynamic> json) {
    _overlays.clear();
    for (final entry in json.entries) {
      _overlays[entry.key] = (entry.value as List)
          .map((e) => PanoramaOverlay.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _save();
  }

  /// Restaura los overlays guardados en `PlatformStorage` (localStorage web).
  static Future<void> loadPersisted() async {
    final storage = PlatformStorage.instance;
    final json = await storage.readJson(_storageKey);
    if (json == null) return;
    importFromJson(json);
  }

  static void _save() {
    PlatformStorage.instance.writeJson(_storageKey, exportToJson());
  }
}