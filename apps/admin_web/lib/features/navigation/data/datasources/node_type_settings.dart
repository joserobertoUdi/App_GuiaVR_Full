import 'package:campus_domain/models/node_model.dart';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Configuración editable de los tipos de nodo (NodeZone).
/// Permite renombrar y describir los 3 tipos (inicio, pasillo, destino)
/// en el panel, conservando el valor de enum original para el JSON.
class NodeTypeSettings {
  NodeTypeSettings._();

  static const String _storageKey = 'node_type_settings_json';

  static final Map<String, Map<String, dynamic>> _overrides = {};

  static Future<void> load() async {
    try {
      final data = await PlatformStorage.instance.readJson(_storageKey);
      _overrides.clear();
      if (data != null) {
        for (final entry in data.entries) {
          final value = entry.value;
          if (value is Map) {
            _overrides[entry.key] = {
              'label': value['label']?.toString(),
              'description': value['description']?.toString(),
            };
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final data = <String, dynamic>{
        for (final e in _overrides.entries)
          e.key: {
            'label': e.value['label'],
            'description': e.value['description'],
          },
      };
      await PlatformStorage.instance.writeJson(_storageKey, data);
    } catch (_) {}
  }

  static String labelFor(NodeZone zone) {
    final override = _overrides[zone.name];
    final label = override?['label'] as String?;
    if (label != null && label.trim().isNotEmpty) return label;
    return _defaultLabel(zone);
  }

  static String descriptionFor(NodeZone zone) {
    final override = _overrides[zone.name];
    return (override?['description'] as String?) ?? '';
  }

  static void update({
    required NodeZone zone,
    required String label,
    required String description,
  }) {
    _overrides[zone.name] = {
      'label': label,
      'description': description,
    };
  }

  static String _defaultLabel(NodeZone zone) {
    switch (zone) {
      case NodeZone.inicio:
        return 'Inicio';
      case NodeZone.pasillo:
        return 'Pasillo';
      case NodeZone.destino:
        return 'Destino';
    }
  }
}