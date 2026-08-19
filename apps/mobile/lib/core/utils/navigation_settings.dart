import 'package:app_guia_ar/core/utils/platform_storage.dart';
import 'package:campus_domain/campus_domain.dart';
import 'package:flutter/foundation.dart';

/// Preferencias de navegación de la app móvil.
///
/// El nodo de inicio por defecto llega en el bundle desde el admin
/// ([NavigationConfig.defaultStartNodeId]) y se guarda en SharedPreferences.
/// La pantalla de planificación de ruta lo preselecciona como punto de inicio.
class NavigationSettings {
  NavigationSettings._();

  static const String _defaultStartKey = 'default_start_node_id';

  static String? _cachedDefaultStart;

  /// Notifica cambios (la sync del backend o el import del bundle lo llaman).
  static final ChangeNotifier changes = _NavSettingsNotifier();

  /// Dispara [changes] públicamente.
  static void notifyChange() {
    (changes as _NavSettingsNotifier).notify();
  }

  /// Guarda el nodo de inicio por defecto (id del nodo dentro del campus).
  static Future<void> setDefaultStartNodeId(String? nodeId) async {
    if (nodeId == null || nodeId.isEmpty) {
      await PlatformStorage.instance.remove(_defaultStartKey);
    } else {
      await PlatformStorage.instance.write(_defaultStartKey, nodeId);
    }
    _cachedDefaultStart = (nodeId == null || nodeId.isEmpty) ? null : nodeId;
    notifyChange();
  }

  static String? get defaultStartNodeId => _cachedDefaultStart;

  /// Lee el nodo de inicio por defecto guardado, o `null`.
  static Future<String?> loadDefaultStartNodeId() async {
    if (_cachedDefaultStart != null) return _cachedDefaultStart;
    _cachedDefaultStart = await PlatformStorage.instance.read(_defaultStartKey);
    return _cachedDefaultStart;
  }

  /// Aplica la config de navegación recibida en un bundle.
  static Future<void> applyNavigationConfig(NavigationConfig? config) async {
    if (config == null) return;
    await setDefaultStartNodeId(config.defaultStartNodeId);
  }
}

/// Notifier para [NavigationSettings.changes] con método público no protegido.
class _NavSettingsNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}