import 'dart:convert';
import 'dart:typed_data';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Implementación para VM (tests) / plataformas sin navegador.
/// Guarda los bytes como base64 en `PlatformStorage` (localStorage en web).
Future<void> writeBytes(String key, Uint8List bytes) async {
  await PlatformStorage.instance.write(key, base64Encode(bytes));
}

Future<Uint8List?> readBytes(String key) async {
  final raw = await PlatformStorage.instance.read(key);
  if (raw == null) return null;
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
}

Future<bool> hasBytes(String key) async {
  return await PlatformStorage.instance.contains(key);
}

Future<void> deleteBytes(String key) async {
  await PlatformStorage.instance.remove(key);
}