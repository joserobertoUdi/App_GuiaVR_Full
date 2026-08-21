// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;
import 'dart:typed_data';

// ═══ PUBLISH (PUT) ═══

Future<bool> publishBundle(String baseUrl, String bundleJson) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/bundle',
      method: 'PUT',
      sendData: bundleJson,
      requestHeaders: const {'Content-Type': 'application/json'},
    );
    final status = request.status ?? 0;
    return status >= 200 && status < 300;
  } catch (_) {
    return false;
  }
}

Future<bool> publishImage(
  String baseUrl,
  String nodeId,
  Uint8List bytes,
) async {
  try {
    final blob = web.Blob([bytes]);
    final request = await web.HttpRequest.request(
      '$baseUrl/api/images/${Uri.encodeComponent(nodeId)}',
      method: 'PUT',
      sendData: blob,
    );
    final status = request.status ?? 0;
    return status >= 200 && status < 300;
  } catch (_) {
    return false;
  }
}

Future<bool> publishHomeMedia(
  String baseUrl,
  String mediaId,
  Uint8List bytes,
) async {
  try {
    final blob = web.Blob([bytes]);
    final request = await web.HttpRequest.request(
      '$baseUrl/api/home-media/${Uri.encodeComponent(mediaId)}',
      method: 'PUT',
      sendData: blob,
    );
    final status = request.status ?? 0;
    return status >= 200 && status < 300;
  } catch (_) {
    return false;
  }
}

// ═══ FETCH (GET) ═══

Future<Map<String, dynamic>?> fetchBundleVersion(String baseUrl) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/bundle/version',
      method: 'GET',
    );
    if ((request.status ?? 0) != 200) return null;
    return json.decode(request.responseText ?? '') as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<String?> fetchBundle(String baseUrl) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/bundle',
      method: 'GET',
    );
    if ((request.status ?? 0) != 200) return null;
    return request.responseText;
  } catch (_) {
    return null;
  }
}

Future<List<String>> fetchHomeMediaList(String baseUrl) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/home-media',
      method: 'GET',
    );
    if ((request.status ?? 0) != 200) return const [];
    final payload =
        json.decode(request.responseText ?? '') as Map<String, dynamic>;
    return (payload['media'] as List?)?.cast<String>() ?? const [];
  } catch (_) {
    return const [];
  }
}

Future<List<String>> fetchImageIds(String baseUrl) async {
  try {
    final request = await web.HttpRequest.request(
      '$baseUrl/api/images',
      method: 'GET',
    );
    if ((request.status ?? 0) != 200) return const [];
    final payload =
        json.decode(request.responseText ?? '') as Map<String, dynamic>;
    return (payload['images'] as List?)?.cast<String>() ?? const [];
  } catch (_) {
    return const [];
  }
}

// ═══ BINARY DOWNLOAD ═══

Future<Uint8List?> fetchImageBytes(String baseUrl, String nodeId) async {
  return _fetchBinary(
    '$baseUrl/api/images/${Uri.encodeComponent(nodeId)}',
  );
}

Future<Uint8List?> fetchHomeMediaBytes(String baseUrl, String mediaId) async {
  return _fetchBinary(
    '$baseUrl/api/home-media/${Uri.encodeComponent(mediaId)}',
  );
}

/// Descarga binaria usando XMLHttpRequest con responseType=arraybuffer.
Future<Uint8List?> _fetchBinary(String url) async {
  try {
    final xhr = web.HttpRequest();
    xhr.open('GET', url, async: true);
    xhr.responseType = 'arraybuffer';

    final completer = Completer<Uint8List?>();
    xhr.onLoad.listen((_) {
      try {
        final response = xhr.response;
        if (response == null) {
          completer.complete(null);
          return;
        }
        if (response is ByteBuffer) {
          completer.complete(response.asUint8List());
        } else if (response is Uint8List) {
          completer.complete(response);
        } else {
          final buf = response as dynamic;
          if (buf is ByteBuffer) {
            completer.complete(buf.asUint8List());
          } else {
            completer.complete(Uint8List.view(buf as dynamic));
          }
        }
      } catch (e) {
        print('[_fetchBinary] parse error: $e');
        completer.complete(null);
      }
    });
    xhr.onError.listen((_) {
      print('[_fetchBinary] XHR error for $url');
      completer.complete(null);
    });

    xhr.send();
    return completer.future;
  } catch (e) {
    print('[_fetchBinary] exception: $e');
    return null;
  }
}
