import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renderiza un código QR fuera del árbol de widgets y devuelve sus bytes PNG.
///
/// Útil para exportar QR individuales o en masa a imagen sin necesidad de
/// incrustarlos primero en la UI.
class QrImageRenderer {
  QrImageRenderer._();

  /// Genera un PNG de [size]×[size] píxeles con el valor [data].
  /// Devuelve `null` si el contenido no se puede codificar.
  static Future<Uint8List?> renderPng(
    String data, {
    int size = 512,
    Color? foregroundColor,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final qrColor = foregroundColor ?? Colors.black;
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: qrColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: qrColor,
        ),
        gapless: true,
      );
      painter.paint(canvas, Size(size.toDouble(), size.toDouble()));

      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Nombre de archivo amigable para un QR dado.
  static String filenameFor({
    required String typePrefix,
    required String id,
  }) {
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return 'qr_${typePrefix}_$safe.png';
  }
}