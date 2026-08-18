import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Abstracción de almacenamiento que funciona tanto en móvil como en web.
/// En ambos casos usa SharedPreferences (que en web se mapea a localStorage).
/// Para datos grandes (JSON de campus, imágenes) ofrece helper de JSON.
class PlatformStorage {
  static PlatformStorage? _instance;
  SharedPreferences? _prefs;

  PlatformStorage._();

  static PlatformStorage get instance {
    _instance ??= PlatformStorage._();
    return _instance!;
  }

  /// Inicializa el storage. Debe llamarse antes de usarlo.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ═══ KEY-VALUE BÁSICO ═══

  Future<String?> read(String key) async {
    return _prefs?.getString(key);
  }

  Future<void> write(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<bool> contains(String key) async {
    return _prefs?.containsKey(key) ?? false;
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }

  // ═══ JSON HELPERS ═══

  /// Lee un JSON almacenado por clave y lo decodifica.
  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Codifica un Map a JSON string y lo almacena.
  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    await write(key, json.encode(data));
  }

  /// Lee una lista JSON almacenada por clave.
  Future<List<dynamic>?> readJsonList(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    try {
      return json.decode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Almacena una lista como JSON.
  Future<void> writeJsonList(String key, List<dynamic> data) async {
    await write(key, json.encode(data));
  }

  // ═══ IMÁGENES (base64 para web, path para móvil) ═══

  /// Guarda datos de imagen como base64 (útil en web).
  Future<void> saveImageBase64(String key, List<int> bytes) async {
    await write(key, base64Encode(bytes));
  }

  /// Lee datos de imagen desde base64.
  Future<List<int>?> loadImageBase64(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Indica si estamos en web.
  static bool get isWeb => kIsWeb;

  /// Indica si estamos en plataforma nativa (móvil/desktop).
  static bool get isNative => !kIsWeb;
}
