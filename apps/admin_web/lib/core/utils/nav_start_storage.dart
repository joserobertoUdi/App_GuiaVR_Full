import 'package:admin_web/core/utils/platform_storage.dart';
import 'package:flutter/foundation.dart';

/// Persiste el nodo de inicio por defecto elegido en el panel de administración.
///
/// El valor es el `id` de un nodo del campus. Se guarda localmente en el
/// navegador y se incluye en el bundle publicado
/// (`NavigationConfig.defaultStartNodeId`) para que la app móvil lo use como
/// punto de inicio preseccionado.
class NavStartStorage {
  NavStartStorage._();

  static const String _startKey = 'default_start_node_id_v2';

  static String? _cachedStartId;

  /// Notifica cambios del punto de inicio por defecto.
  static final ChangeNotifier changes = _NavStartNotifier();

  /// Dispara [changes] públicamente.
  static void notifyChange() {
    (changes as _NavStartNotifier).notify();
  }

  static String? get startNodeId => _cachedStartId;

  /// Guarda el id del nodo de inicio por defecto (`null` para limpiarlo).
  static Future<void> saveStartNodeId(String? nodeId) async {
    if (nodeId == null || nodeId.isEmpty) {
      await PlatformStorage.instance.remove(_startKey);
    } else {
      await PlatformStorage.instance.write(_startKey, nodeId);
    }
    _cachedStartId = (nodeId == null || nodeId.isEmpty) ? null : nodeId;
    notifyChange();
  }

  /// Carga el id guardado (devuelve `null` si no hay ninguno).
  static Future<String?> loadStartNodeId() async {
    if (_cachedStartId != null) return _cachedStartId;
    _cachedStartId = await PlatformStorage.instance.read(_startKey);
    return _cachedStartId;
  }
}

/// Notifier para [NavStartStorage.changes] con método público no protegido.
class _NavStartNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}