// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Implementación para navegador usando IndexedDB.
/// La cuota de IndexedDB es de cientos de MB (a diferencia de los ~5 MB de
/// localStorage), suficiente para panoramas 360° de varios MB.
///
/// Los bytes se guardan como string base64 con clave fuera de línea, lo que
/// evita problemas de conversión de objetos no planos con `js_interop`.
const String _dbName = 'panorama_images';
const int _dbVersion = 1;
const String _storeName = 'images';

web.IDBDatabase? _dbCache;

Future<web.IDBDatabase> _openDb() async {
  final cached = _dbCache;
  if (cached != null) return cached;

  final request = web.window.indexedDB.open(_dbName, _dbVersion);
  final completer = Completer<web.IDBDatabase>();

  request.onupgradeneeded =
      ((JSAny? _) {
        final db = request.result as web.IDBDatabase;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName, web.IDBObjectStoreParameters());
        }
      }).toJS;

  request.onsuccess =
      ((JSAny? _) {
        final db = request.result as web.IDBDatabase;
        _dbCache = db;
        if (!completer.isCompleted) completer.complete(db);
      }).toJS;

  request.onerror =
      ((JSAny? _) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('No se pudo abrir IndexedDB: ${request.error}'),
          );
        }
      }).toJS;

  return completer.future;
}

Future<JSAny?> _requestResult(web.IDBRequest request) {
  final completer = Completer<JSAny?>();
  request.onsuccess =
      ((JSAny? _) {
        if (!completer.isCompleted) completer.complete(request.result);
      }).toJS;
  request.onerror =
      ((JSAny? _) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Operación IndexedDB fallida: ${request.error}'),
          );
        }
      }).toJS;
  return completer.future;
}

Future<void> _waitTransaction(web.IDBTransaction tx) {
  final completer = Completer<void>();
  tx.oncomplete =
      ((JSAny? _) {
        if (!completer.isCompleted) completer.complete();
      }).toJS;
  tx.onerror =
      ((JSAny? _) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Transacción IndexedDB con error: ${tx.error}'),
          );
        }
      }).toJS;
  tx.onabort =
      ((JSAny? _) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Transacción IndexedDB abortada'));
        }
      }).toJS;
  return completer.future;
}

Future<void> writeBytes(String key, Uint8List bytes) async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readwrite');
  await _requestResult(
    tx.objectStore(_storeName).put(base64Encode(bytes).toJS, key.toJS),
  );
  await _waitTransaction(tx);
}

Future<Uint8List?> readBytes(String key) async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readonly');
  final result = await _requestResult(
    tx.objectStore(_storeName).get(key.toJS),
  );
  await _waitTransaction(tx);
  final value = result?.dartify();
  if (value is String) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

Future<bool> hasBytes(String key) async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readonly');
  final result = await _requestResult(
    tx.objectStore(_storeName).get(key.toJS),
  );
  await _waitTransaction(tx);
  return result?.dartify() is String;
}

Future<void> deleteBytes(String key) async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readwrite');
  await _requestResult(tx.objectStore(_storeName).delete(key.toJS));
  await _waitTransaction(tx);
}

Future<void> clearAllBytes() async {
  final db = await _openDb();
  final tx = db.transaction(_storeName.toJS, 'readwrite');
  await _requestResult(tx.objectStore(_storeName).clear());
  await _waitTransaction(tx);
}