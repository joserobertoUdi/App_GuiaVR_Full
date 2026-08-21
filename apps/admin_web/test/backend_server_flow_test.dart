import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus_domain/campus_domain.dart' as campus_domain;
import 'package:admin_web/core/utils/campus_bundle_export.dart';
import 'package:admin_web/core/utils/home_editor_storage.dart';
import 'package:admin_web/core/utils/nav_start_storage.dart';
import 'package:admin_web/core/utils/platform_storage.dart';

/// Test E2E del transporte web admin → backend de push.
///
/// Levanta el servidor real (`tools/backend_server.dart`) en un puerto efímero
/// y con un directorio de datos temporal (para no tocar `tools/backend_data/`).
/// Publica un bundle (con `home` + `navigation`) e imágenes/media, y verifica
/// que el backend los sirve tal como los consumiría la app móvil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // flutter_test instala un HttpClient de prueba que responde 400; para el
    // E2E contra el servidor real necesitamos la red real.
    HttpOverrides.global = null;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlatformStorage.instance.init();
  });

  test('flujo completo: publicar bundle + home-media + imágenes desde el admin',
      () async {
    // ── Dónde está el servidor y datos temporales ────────────────────────
    final repoRoot = Directory.current.parent.parent;
    final serverScript = File(
      '${repoRoot.path}${Platform.pathSeparator}tools${Platform.pathSeparator}'
      'backend_server.dart',
    );
    expect(serverScript.existsSync(), isTrue,
        reason: 'No se encontró tools/backend_server.dart');

    final workingDir =
        await Directory.systemTemp.createTemp('backend_e2e_');
    final port = 18000 + (DateTime.now().millisecondsSinceEpoch % 1000);
    final baseUrl = 'http://127.0.0.1:$port';

    // ── Generar el bundle como lo hace el panel web ─────────────────────
    await HomeEditorStorage.saveState(const HomeEditorState(
      type: campus_domain.HomeBackgroundType.carousel,
      intervalSeconds: 5,
      media: [
        HomeEditorMedia(id: 'm1', name: 'img1', isVideo: false),
        HomeEditorMedia(id: 'm2', name: 'img2', isVideo: false),
      ],
    ));
    await NavStartStorage.saveStartNodeId('P01');
    final bundleJson = CampusBundleExport.buildBundleWithSettings(
      homeState: await HomeEditorStorage.loadState(),
      defaultStartNodeId: await NavStartStorage.loadStartNodeId(),
    );

    // ── Levantar el backend real ────────────────────────────────────────
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final dartExecutable = flutterRoot == null
        ? File(Platform.resolvedExecutable)
            .parent
            .parent
            .parent
            .parent
            .uri
            .resolve('dart-sdk/bin/dart.exe')
            .toFilePath()
        : '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
            'cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}'
            'bin${Platform.pathSeparator}dart.exe';
    expect(File(dartExecutable).existsSync(), isTrue,
        reason: 'No se encontró el binario dart: $dartExecutable');
    debugPrint('dartExe=$dartExecutable script=${serverScript.path} '
        'cwd=${workingDir.path}');
    final server = await Process.start(
      dartExecutable,
      ['run', serverScript.path, '$port'],
      workingDirectory: workingDir.path,
    );
    final serverLog = StringBuffer();
    unawaited(server.stdout
        .transform(utf8.decoder)
        .listen(serverLog.write).asFuture<void>()
        .catchError((_) {}));
    unawaited(server.stderr
        .transform(utf8.decoder)
        .listen(serverLog.write).asFuture<void>()
        .catchError((_) {}));
    addTearDown(() async {
      server.kill();
      await server.exitCode.timeout(const Duration(seconds: 5));
      if (workingDir.existsSync()) {
        try {
          workingDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    try {
      await _waitForHealth(baseUrl);
    } catch (_) {
      fail('Backend sin responder en $baseUrl. \n\n--- log del servidor ---\n'
          '${serverLog.toString()}\n--- fin del log ---');
    }

    // ── Publicar y verificar ────────────────────────────────────────────
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 5);

    try {
      await _send(client, 'PUT', '$baseUrl/api/bundle', body: bundleJson);
      await _send(client, 'PUT', '$baseUrl/api/home-media/m1',
          bytes: [1, 2, 3, 4, 5]);
      await _send(client, 'PUT', '$baseUrl/api/home-media/m2', bytes: [9, 8, 7]);
      await _send(client, 'PUT', '$baseUrl/api/images/P01', bytes: [11, 22, 33]);

      // Bundle recuperable: la app móvil vería la config del fondo y el inicio.
      final bundleOut = await _get(client, '$baseUrl/api/bundle');
      final parsed = campus_domain.CampusBundle.parse(bundleOut);
      expect(parsed.version, campus_domain.CampusBundle.version);
      expect(parsed.home, isNotNull);
      expect(parsed.home!.type, campus_domain.HomeBackgroundType.carousel);
      expect(parsed.home!.mediaIds, containsAll(['m1', 'm2']));
      expect(parsed.navigation?.defaultStartNodeId, 'P01');

      final version = json.decode(await _get(client, '$baseUrl/api/bundle/version'))
          as Map<String, dynamic>;
      expect(version['version'], campus_domain.CampusBundle.version);

      // Media del fondo tal como los descarga HomeContentStorage.
      final mediaList = json.decode(await _get(client, '$baseUrl/api/home-media'))
          as Map<String, dynamic>;
      expect(mediaList['media'], containsAll(['m1', 'm2']));
      final m1 = await _getBytes(client, '$baseUrl/api/home-media/m1');
      expect(m1, [1, 2, 3, 4, 5]);

      // Imágenes de panorama por nodo tal como las descarga LocalImageStorage.
      final images = json.decode(await _get(client, '$baseUrl/api/images'))
          as Map<String, dynamic>;
      expect(images['images'], contains('P01'));
      final img = await _getBytes(client, '$baseUrl/api/images/P01');
      expect(img, [11, 22, 33]);
} finally {
      client.close(force: true);
    }
  }, timeout: const Timeout(Duration(seconds: 120)));
}

Future<void> _waitForHealth(String baseUrl) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  for (var i = 0; i < 40; i++) {
    try {
      final req = await client.getUrl(Uri.parse('$baseUrl/api/health'));
      final res = await req.close();
      await res.drain<void>();
      if (res.statusCode == HttpStatus.ok) {
        client.close(force: true);
        return;
      }
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
  client.close(force: true);
  fail('El backend no respondió en $baseUrl/api/health');
}

Future<String> _get(HttpClient client, String url) async {
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  expect(res.statusCode, HttpStatus.ok, reason: 'GET $url');
  return utf8.decoder.bind(res).join();
}

Future<List<int>> _getBytes(HttpClient client, String url) async {
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  expect(res.statusCode, HttpStatus.ok, reason: 'GET bytes $url');
  return res.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
}

Future<void> _send(HttpClient client, String method, String url,
    {String? body, List<int>? bytes}) async {
  final req = await client.openUrl(method, Uri.parse(url));
  if (body != null) {
    req.headers.contentType = ContentType.json;
    req.write(body);
  } else if (bytes != null) {
    req.headers.contentType = ContentType.binary;
    req.add(bytes);
  }
  final res = await req.close();
  await res.drain<void>();
  expect(res.statusCode, HttpStatus.ok, reason: '$method $url');
}