import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' as io;

void main() {
  print('=== Generador de Placeholders 360° ===\n');

  final nodes = [
    {'id': 'P01', 'name': 'Entrada Principal', 'floor': '1', 'color': [0xFF1a, 0x1a, 0x2e]},
    {'id': 'P02', 'name': 'Pasillo Principal P1', 'floor': '1', 'color': [0xFF2d, 0x13, 0x2c]},
    {'id': 'P_AULA_101', 'name': 'Aula 101', 'floor': '1', 'color': [0xFF0a, 0x3d, 0x62]},
    {'id': 'P03', 'name': 'Pasillo Secundario P1', 'floor': '1', 'color': [0xFF1b, 0x1a, 0x17]},
    {'id': 'P04', 'name': 'Acceso Escaleras', 'floor': '1', 'color': [0xFF4a, 0x1a, 0x2e]},
    {'id': 'P05', 'name': 'Escalera Principal', 'floor': '1-2', 'color': [0xFF2d, 0x3a, 0x2c]},
    {'id': 'P06', 'name': 'Cabeza Escalera P2', 'floor': '2', 'color': [0xFF0a, 0x4d, 0x62]},
    {'id': 'P07', 'name': 'Pasillo Principal P2', 'floor': '2', 'color': [0xFF3b, 0x2a, 0x17]},
    {'id': 'P_AULA_201', 'name': 'Aula 201', 'floor': '2', 'color': [0xFF1a, 0x3a, 0x2e]},
    {'id': 'P08', 'name': 'Pasillo Fondo P2', 'floor': '2', 'color': [0xFF4d, 0x13, 0x3c]},
    {'id': 'P_AULA_204', 'name': 'Aula 204', 'floor': '2', 'color': [0xFF0a, 0x2d, 0x52]},
    {'id': 'P09', 'name': 'Salida Emergencia P2', 'floor': '2', 'color': [0xFF2b, 0x1a, 0x37]},
  ];

  final outputDir = Directory('assets/panoramas');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final node in nodes) {
    final id = node['id'] as String;
    final name = node['name'] as String;
    final floor = node['floor'] as String;
    final color = (node['color'] as List).cast<int>();

    final png = _createEnhancedPlaceholder(
      width: 2048,
      height: 1024,
      r: color[0],
      g: color[1],
      b: color[2],
      nodeId: id,
      nodeName: name,
      floor: floor,
    );

    final file = File('${outputDir.path}/panorama_${id.toLowerCase()}.jpg');
    file.writeAsBytesSync(png);
    print('✓ ${id}: ${name} (${png.length} bytes)');
  }

  _generateMetadataJson(nodes);
  print('\n✓ Metadata generada en assets/panoramas/metadata.json');
  print('\n=== Completado ===');
}

void _generateMetadataJson(List<Map<String, dynamic>> nodes) {
  final metadata = <Map<String, dynamic>>[];

  for (final node in nodes) {
    final id = node['id'] as String;
    final name = node['name'] as String;
    final floor = node['floor'] as String;

    metadata.add({
      'nodeId': id,
      'name': name,
      'floorLevel': floor,
      'imageFile': 'panorama_${id.toLowerCase()}.jpg',
      'thumbnailFile': 'thumb_${id.toLowerCase()}.jpg',
      'resolution': '2048x1024',
      'status': 'placeholder',
      'captureDate': null,
      'captureTime': null,
      'cameraHeight': null,
      'lightConditions': null,
    });
  }

  final jsonFile = File('assets/panoramas/metadata.json');
  jsonFile.writeAsBytesSync(
    Uint8List.fromList(utf8.encode(
      const JsonEncoder.withIndent('  ').convert(metadata),
    )),
  );
}

Uint8List _createEnhancedPlaceholder({
  required int width,
  required int height,
  required int r,
  required int g,
  required int b,
  required String nodeId,
  required String nodeName,
  required String floor,
}) {
  final raw = <int>[];

  for (int y = 0; y < height; y++) {
    raw.add(0);

    final gradientFactor = y / height;
    final gr = (r * (1 - gradientFactor * 0.3)).round().clamp(0, 255);
    final gg = (g * (1 - gradientFactor * 0.3)).round().clamp(0, 255);
    final gb = (b * (1 - gradientFactor * 0.3)).round().clamp(0, 255);

    for (int x = 0; x < width; x++) {
      final gridX = (x % 64 < 1) || (x % 64 > 62);
      final gridY = (y % 64 < 1) || (y % 64 > 62);
      final isGrid = gridX || gridY;

      final centerDx = (x - width / 2).abs() / (width / 2);
      final centerDy = (y - height / 2).abs() / (height / 2);
      final centerDist = (centerDx + centerDy) / 2;
      final vignette = (1 - centerDist * 0.4).clamp(0.0, 1.0);

      final fr = isGrid ? (gr * 0.7).round() : (gr * vignette).round();
      final fg = isGrid ? (gg * 0.7).round() : (gg * vignette).round();
      final fb = isGrid ? (gb * 0.7).round() : (gb * vignette).round();

      raw.add(fr.clamp(0, 255));
      raw.add(fg.clamp(0, 255));
      raw.add(fb.clamp(0, 255));
    }
  }

  _drawText(raw, width, height, nodeId, 100, height ~/ 2 - 60, 255, 255, 255, 4);
  _drawText(raw, width, height, nodeName, 100, height ~/ 2 + 20, 200, 200, 200, 2);
  _drawText(raw, width, height, 'Piso $floor', 100, height ~/ 2 + 80, 150, 150, 150, 2);
  _drawText(raw, width, height, 'PLACEHOLDER 360', width - 400, 50, 100, 100, 100, 2);
  _drawText(raw, width, height, '${width}x$height', width - 250, height - 50, 100, 100, 100, 2);

  final rawBytes = Uint8List.fromList(raw);
  final compressed = Uint8List.fromList(io.zlib.encode(rawBytes));

  final png = BytesBuilder();
  png.add([137, 80, 78, 71, 13, 10, 26, 10]);

  _addChunk(png, 'IHDR', _bytesFromInts([width, height, 8, 2, 0, 0, 0]));
  _addChunk(png, 'IDAT', compressed);
  _addChunk(png, 'IEND', Uint8List(0));

  return png.toBytes();
}

void _drawText(
  List<int> raw,
  int imgWidth,
  int imgHeight,
  String text,
  int startX,
  int startY,
  int r,
  int g,
  int b,
  int scale,
) {
  final charWidth = 8 * scale;
  final charHeight = 12 * scale;

  for (int ci = 0; ci < text.length; ci++) {
    final char = text[ci];
    final charBitmap = _getCharBitmap(char);
    if (charBitmap == null) continue;

    for (int cy = 0; cy < charBitmap.length && cy < charHeight; cy++) {
      final row = charBitmap[cy];
      if (row == null) continue;
      for (int cx = 0; cx < row.length && cx < charWidth; cx++) {
        final scaledCy = cy ~/ scale;
        final scaledCx = cx ~/ scale;
        if (scaledCy < charBitmap.length && scaledCx < (charBitmap[scaledCy]?.length ?? 0)) {
          if ((charBitmap[scaledCy]?[scaledCx] ?? 0) == 1) {
            final px = startX + ci * charWidth + cx;
            final py = startY + cy;

            if (px >= 0 && px < imgWidth && py >= 0 && py < imgHeight) {
              final offset = 1 + (py * imgWidth + px) * 3;
              if (offset + 2 < raw.length) {
                raw[offset] = r;
                raw[offset + 1] = g;
                raw[offset + 2] = b;
              }
            }
          }
        }
      }
    }
  }
}

List<List<int>>? _getCharBitmap(String char) {
  const bitmap = {
    'A': [
      [0,0,1,1,1,0,0],
      [0,1,0,0,0,1,0],
      [1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
    ],
    'B': [
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [1,1,1,1,1,0,0],
    ],
    'C': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    'D': [
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,1,0],
      [1,1,1,1,1,0,0],
    ],
    'E': [
      [1,1,1,1,1,1,1],
      [1,0,0,0,0,0,0],
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,1,1,1,1,1,1],
    ],
    'F': [
      [1,1,1,1,1,1,1],
      [1,0,0,0,0,0,0],
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
    ],
    'G': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,0,0],
      [1,0,0,1,1,1,1],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    'H': [
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
    ],
    'I': [
      [1,1,1,1,1,1,1],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [1,1,1,1,1,1,1],
    ],
    'J': [
      [0,0,0,0,0,0,1],
      [0,0,0,0,0,0,1],
      [0,0,0,0,0,0,1],
      [0,0,0,0,0,0,1],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    'K': [
      [1,0,0,0,0,0,1],
      [1,0,0,0,1,0,0],
      [1,1,1,1,0,0,0],
      [1,0,0,0,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,0,1],
    ],
    'L': [
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
      [1,1,1,1,1,1,1],
    ],
    'M': [
      [1,0,0,0,0,0,1],
      [1,1,0,0,0,1,1],
      [1,0,1,0,1,0,1],
      [1,0,0,1,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
    ],
    'N': [
      [1,0,0,0,0,0,1],
      [1,1,0,0,0,0,1],
      [1,0,1,0,0,0,1],
      [1,0,0,1,0,0,1],
      [1,0,0,0,1,1,1],
      [1,0,0,0,0,0,1],
    ],
    'O': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    'P': [
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,0,0],
      [1,0,0,0,0,0,0],
    ],
    'Q': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,0,1],
      [1,0,0,1,0,0,1],
      [1,0,0,0,1,1,0],
      [0,1,1,1,1,0,1],
    ],
    'R': [
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [1,1,1,1,1,0,0],
      [1,0,0,0,1,0,0],
      [1,0,0,0,0,1,0],
    ],
    'S': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,0,0,0],
      [0,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    'T': [
      [1,1,1,1,1,1,1],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
    ],
    'U': [
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    'V': [
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [0,1,0,0,0,1,0],
      [0,0,1,0,1,0,0],
      [0,0,0,1,0,0,0],
    ],
    'W': [
      [1,0,0,0,0,0,1],
      [1,0,0,0,0,0,1],
      [1,0,0,1,0,0,1],
      [1,0,1,0,1,0,1],
      [1,1,0,0,0,1,1],
      [1,0,0,0,0,0,1],
    ],
    'X': [
      [1,0,0,0,0,0,1],
      [0,1,0,0,0,1,0],
      [0,0,1,0,1,0,0],
      [0,0,0,1,0,0,0],
      [0,0,1,0,1,0,0],
      [0,1,0,0,0,1,0],
      [1,0,0,0,0,0,1],
    ],
    'Y': [
      [1,0,0,0,0,0,1],
      [0,1,0,0,0,1,0],
      [0,0,1,0,1,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
    ],
    'Z': [
      [1,1,1,1,1,1,1],
      [0,0,0,0,0,1,0],
      [0,0,0,0,1,0,0],
      [0,0,0,1,0,0,0],
      [0,0,1,0,0,0,0],
      [1,1,1,1,1,1,1],
    ],
    '0': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    '1': [
      [0,0,0,1,0,0,0],
      [0,0,1,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,1,1,1,0,0],
    ],
    '2': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [0,0,0,0,1,0,0],
      [0,0,0,1,0,0,0],
      [0,0,1,0,0,0,0],
      [1,1,1,1,1,1,0],
    ],
    '3': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [0,0,1,1,1,0,0],
      [0,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    '4': [
      [0,0,0,0,1,0,0],
      [0,0,0,1,1,0,0],
      [0,0,1,0,1,0,0],
      [0,1,0,0,1,0,0],
      [1,1,1,1,1,1,0],
      [0,0,0,0,1,0,0],
    ],
    '5': [
      [1,1,1,1,1,1,0],
      [1,0,0,0,0,0,0],
      [1,1,1,1,1,0,0],
      [0,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    '6': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,0,0],
      [1,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    '7': [
      [1,1,1,1,1,1,1],
      [0,0,0,0,0,1,0],
      [0,0,0,0,1,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
      [0,0,0,1,0,0,0],
    ],
    '8': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    '9': [
      [0,1,1,1,1,0,0],
      [1,0,0,0,0,1,0],
      [1,0,0,0,0,1,0],
      [0,1,1,1,1,1,0],
      [0,0,0,0,0,1,0],
      [0,1,1,1,1,0,0],
    ],
    '_': [
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [1,1,1,1,1,1,1],
    ],
    ' ': [
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0],
    ],
  };

  return bitmap[char.toUpperCase()];
}

void _addChunk(BytesBuilder builder, String type, Uint8List data) {
  final length = Uint8List(4);
  length[0] = (data.length >> 24) & 0xFF;
  length[1] = (data.length >> 16) & 0xFF;
  length[2] = (data.length >> 8) & 0xFF;
  length[3] = data.length & 0xFF;
  builder.add(length);

  final typeBytes = Uint8List.fromList(utf8.encode(type));
  builder.add(typeBytes);
  builder.add(data);

  final crc = _crc32(typeBytes, data);
  final crcBytes = Uint8List(4);
  crcBytes[0] = (crc >> 24) & 0xFF;
  crcBytes[1] = (crc >> 16) & 0xFF;
  crcBytes[2] = (crc >> 8) & 0xFF;
  crcBytes[3] = crc & 0xFF;
  builder.add(crcBytes);
}

Uint8List _bytesFromInts(List<int> ints) {
  final result = Uint8List(ints.length * 4);
  for (int i = 0; i < ints.length; i++) {
    result[i * 4] = (ints[i] >> 24) & 0xFF;
    result[i * 4 + 1] = (ints[i] >> 16) & 0xFF;
    result[i * 4 + 2] = (ints[i] >> 8) & 0xFF;
    result[i * 4 + 3] = ints[i] & 0xFF;
  }
  return result;
}

int _crc32(Uint8List type, Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (final byte in type) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  for (final byte in data) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

final _crcTable = List<int>.generate(256, (i) {
  var c = i;
  for (int j = 0; j < 8; j++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});
