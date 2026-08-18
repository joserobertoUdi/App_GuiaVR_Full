import 'package:shared_preferences/shared_preferences.dart';

/// Configuración persistente de la app (preferencias locales del dispositivo).
class AppSettings {
  AppSettings._();

  static const String _kQuickPreviewDelay = 'quick_preview_delay_seconds';
  static const String _kBackendBaseUrl = 'backend_base_url';

  /// Tiempo (en segundos) que la vista rápida permanece en cada nodo antes de
  /// avanzar. Por defecto 2 s; el operador lo ajusta en Admin → Config.
  static const int defaultQuickPreviewDelay = 2;
  static const int minQuickPreviewDelay = 1;
  static const int maxQuickPreviewDelay = 5;

  /// URL base del backend de push (admin). Se alcanza en el dispositivo del
  /// demo vía `adb reverse tcp:8082 tcp:8082` (127.0.0.1 del teléfono = host).
  static const String defaultBackendBaseUrl = 'http://127.0.0.1:8082';

  static Future<int> quickPreviewDelaySeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_kQuickPreviewDelay);
    if (value == null) return defaultQuickPreviewDelay;
    return value.clamp(minQuickPreviewDelay, maxQuickPreviewDelay);
  }

  static Future<void> setQuickPreviewDelaySeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kQuickPreviewDelay,
      seconds.clamp(minQuickPreviewDelay, maxQuickPreviewDelay),
    );
  }

  static Future<String> backendBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBackendBaseUrl) ?? defaultBackendBaseUrl;
  }

  static Future<void> setBackendBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_kBackendBaseUrl, trimmed);
  }
}
