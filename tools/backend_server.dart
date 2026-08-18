import 'dart:convert';
import 'dart:io';

/// Backend de push local para el flujo E2E.
///
/// La web de administración publica aquí el bundle de campus + las imágenes
/// de panorama (PUT), y la app móvil consulta esos recursos al arrancar y se
/// actualiza automáticamente (sin botones en la app).
///
/// Endpoints:
///   GET  /api/health                      → estado
///   GET  /api/bundle                      → último bundle publicado
///   PUT  /api/bundle                      → publicar bundle (body = JSON)
///   GET  /api/bundle/version              → versión y resumen del bundle
///   GET  /api/images                      → lista de nodeId con imagen
///   GET  /api/images/<nodeId>             → bytes de la imagen
///   PUT  /api/images/<nodeId>             → publicar imagen (body = bytes)
///
/// Persistencia en ./backend_data/
Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8082;
  final dataDir = Directory('backend_data');
  if (!dataDir.existsSync()) dataDir.createSync(recursive: true);
  final imagesDir = Directory('${dataDir.path}/images');
  if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Backend Push corriendo en http://${server.address.address}:$port');
  stdout.writeln('Datos en: ${dataDir.absolute.path}');
  stdout.writeln('Control+C para detener.');

  await for (final req in server) {
    _handle(req, dataDir, imagesDir);
  }
}

Future<void> _handle(
  HttpRequest req,
  Directory dataDir,
  Directory imagesDir,
) async {
  final res = req.response;
  _cors(res);

  final path = req.uri.path;
  final method = req.method.toUpperCase();

  if (method == 'OPTIONS') {
    res.statusCode = HttpStatus.ok;
    await res.close();
    return;
  }

  Future<void> respond(int status, String body) async {
    res.statusCode = status;
    res.write(body);
    await res.close();
  }

  try {
    switch (path) {
      case '/api/health':
        return respond(HttpStatus.ok, '{"status":"ok"}');

      case '/api/bundle':
        final file = File('${dataDir.path}/bundle.json');
        if (method == 'GET') {
          if (file.existsSync()) {
            res.headers.contentType = ContentType.json;
            return respond(HttpStatus.ok, file.readAsStringSync());
          }
          return respond(HttpStatus.notFound, '{"error":"aún no hay bundle"}');
        }
        if (method == 'PUT' || method == 'POST') {
          final bytes = await _collect(req);
          await file.writeAsBytes(bytes);
          stdout.writeln('[bundle] publicado (${bytes.length} bytes)');
          return respond(HttpStatus.ok, '{"status":"ok"}');
        }
        return respond(HttpStatus.methodNotAllowed,
            '{"error":"método no permitido"}');

      case '/api/bundle/version':
        final file = File('${dataDir.path}/bundle.json');
        if (!file.existsSync()) {
          return respond(HttpStatus.notFound, '{"error":"aún no hay bundle"}');
        }
        final summary = _describe(file.readAsStringSync());
        return respond(HttpStatus.ok, jsonEncode(summary));

      case '/api/images':
        final ids = imagesDir
            .listSync(followLinks: false)
            .where((e) => e is File)
            .map((e) => e.uri.pathSegments.last)
            .where((name) => name.endsWith('.img'))
            .map((name) => name.substring(0, name.length - '.img'.length))
            .toList();
        return respond(HttpStatus.ok, jsonEncode({'images': ids}));
    }

    final imagesMatch = RegExp(r'^/api/images/([^/]+)$').firstMatch(path);
    if (imagesMatch != null) {
      final nodeId = Uri.decodeComponent(imagesMatch.group(1)!);
      final file = File('${imagesDir.path}/$nodeId.img');
      if (method == 'GET') {
        if (file.existsSync()) {
          res.headers.contentType = ContentType.binary;
          await res.addStream(file.openRead());
          await res.close();
          return;
        }
        return respond(HttpStatus.notFound, '{"error":"imagen no existe"}');
      }
      if (method == 'PUT' || method == 'POST') {
        final bytes = await _collect(req);
        await file.writeAsBytes(bytes);
        stdout.writeln('[images/$nodeId] publicado (${bytes.length} bytes)');
        return respond(HttpStatus.ok, '{"status":"ok"}');
      }
    }

    return respond(HttpStatus.notFound, '{"error":"recurso no encontrado"}');
  } catch (e, st) {
    stderr.writeln('$e\n$st');
    try {
      await respond(
        HttpStatus.internalServerError,
        jsonEncode({'error': '$e'}),
      );
    } catch (_) {}
  }
}

Future<List<int>> _collect(HttpRequest req) async {
  final bytes = <int>[];
  await for (final chunk in req) {
    bytes.addAll(chunk);
  }
  return bytes;
}

void _cors(HttpResponse res) {
  res.headers.set('Access-Control-Allow-Origin', '*');
  res.headers.set('Access-Control-Allow-Methods', 'GET, PUT, POST, OPTIONS');
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type');
}

Map<String, dynamic> _describe(String jsonString) {
  try {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      return {'version': 'desconocida', 'summary': 'Bundle inválido'};
    }
    final campus = decoded['campus'] as Map<String, dynamic>?;
    final floors = (campus?['floors'] as List?)?.length ?? 0;
    final zones = (campus?['zones'] as List?)?.length ?? 0;
    final nodes = (campus?['nodes'] as List?)?.length ?? 0;
    return {
      'version': decoded['version'] ?? 'desconocida',
      'exportedAt': decoded['exportedAt'] ?? '',
      'summary': 'Pisos: $floors | Zonas: $zones | Nodos: $nodes',
    };
  } catch (_) {
    return {'version': 'desconocida', 'summary': 'Bundle inválido'};
  }
}