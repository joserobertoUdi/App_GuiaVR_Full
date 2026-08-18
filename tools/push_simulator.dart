import 'dart:convert';
import 'dart:io';

import 'package:campus_domain/campus_domain.dart';

/// Simula el botón "Publicar todo" de la web de administración.
/// Usa el mismo formato de bundle (CampusBundle.buildJson) y los mismos
/// endpoints /api/bundle y /api/images/<nodeId> del backend de push.
Future<void> main(List<String> args) async {
  final base = args.isNotEmpty ? args[0] : 'http://127.0.0.1:8082';

  // ── 1) Campus NUEVO (distinto al que ya está instalado en el teléfono) ──
  final building = BuildingModel(
    id: 'edificio_PUSH',
    name: 'Edificio Push E2E',
    description: 'Edificio publicado desde el backend',
    latitude: -16.5005,
    longitude: -68.1505,
    floorIds: const ['p_1'],
  );
  final floor = FloorModel(
    id: 'p_1',
    name: 'Planta 1',
    level: 1,
    buildingId: building.id,
    zoneIds: const ['z_entrada', 'z_pasillo', 'z_lab'],
  );
  final zoneIn = ZoneModel(
    id: 'z_entrada',
    name: 'Entrada',
    description: 'Acceso principal',
    floorId: floor.id,
    buildingId: building.id,
    type: ZoneType.vesticulo,
    connectedZoneIds: const ['z_pasillo'],
    nodeIds: const ['N_ENTRADA'],
    entryNodeId: 'N_ENTRADA',
    exitNodeId: 'N_ENTRADA',
    order: 0,
  );
  final zoneHall = ZoneModel(
    id: 'z_pasillo',
    name: 'Pasillo',
    description: 'Conector',
    floorId: floor.id,
    buildingId: building.id,
    type: ZoneType.pasillo,
    connectedZoneIds: const ['z_entrada', 'z_lab'],
    nodeIds: const ['N_PASILLO'],
    order: 1,
  );
  final zoneLab = ZoneModel(
    id: 'z_lab',
    name: 'Laboratorio',
    description: 'Laboratorio de robótica',
    floorId: floor.id,
    buildingId: building.id,
    type: ZoneType.laboratorio,
    connectedZoneIds: const ['z_pasillo'],
    nodeIds: const ['N_LAB'],
    order: 2,
  );

  final nEntrada = NodeModel(
    id: 'N_ENTRADA',
    name: 'Entrada',
    description: 'Punto de inicio',
    latitude: -16.5005,
    longitude: -68.1505,
    heading: 0,
    floorLevel: 'p_1',
    buildingId: building.id,
    panoramaId: 'pano_e2e_entrada',
    connectedNodeIds: const ['N_PASILLO'],
    zone: NodeZone.inicio,
    zoneId: zoneIn.id,
    accuracy: 2.0,
  );
  final nPasillo = NodeModel(
    id: 'N_PASILLO',
    name: 'Pasillo',
    description: 'Zona de paso',
    latitude: -16.5004,
    longitude: -68.1504,
    heading: 90,
    floorLevel: 'p_1',
    buildingId: building.id,
    panoramaId: 'pano_e2e_pasillo',
    connectedNodeIds: const ['N_ENTRADA', 'N_LAB'],
    zone: NodeZone.pasillo,
    zoneId: zoneHall.id,
    accuracy: 2.0,
  );
  final nLab = NodeModel(
    id: 'N_LAB',
    name: 'Laboratorio',
    description: 'Destino final',
    latitude: -16.5003,
    longitude: -68.1503,
    heading: 180,
    floorLevel: 'p_1',
    buildingId: building.id,
    panoramaId: 'pano_e2e_lab',
    connectedNodeIds: const ['N_PASILLO'],
    zone: NodeZone.destino,
    zoneId: zoneLab.id,
    destinationLabel: 'Laboratorio',
    accuracy: 2.0,
  );

  final campus = CampusModel(
    id: 'campus_push_e2e',
    name: 'Campus Push E2E (publicado por backend)',
    description: 'Bundle generado por el simulador del admin',
    buildings: [building],
    floors: [floor],
    zones: [zoneIn, zoneHall, zoneLab],
    nodes: [nEntrada, nPasillo, nLab],
    version: CampusBundle.version,
  );

  // Overlays y direcciones de conexión (igual que exportaría la web, con
  // el contrato de campus_domain: PanoramaOverlay.toJson incluye nodeId).
  final overlays = <String, dynamic>{
    nEntrada.id: [
      PanoramaOverlay(
        id: 'ov_entrada',
        nodeId: nEntrada.id,
        type: OverlayType.text,
        text: 'Bienvenido al edificio Push E2E',
        yaw: 0.0,
        pitch: 0.0,
      ).toJson(),
    ],
  };
  final connectionDirections = <String, dynamic>{
    nEntrada.id: [
      {'nodeId': nEntrada.id, 'targetNodeId': nPasillo.id, 'yaw': 0.0, 'pitch': 0.0}
    ],
    nPasillo.id: [
      {'nodeId': nPasillo.id, 'targetNodeId': nEntrada.id, 'yaw': 180.0, 'pitch': 0.0},
      {'nodeId': nPasillo.id, 'targetNodeId': nLab.id, 'yaw': 90.0, 'pitch': 0.0},
    ],
    nLab.id: [
      {'nodeId': nLab.id, 'targetNodeId': nPasillo.id, 'yaw': 270.0, 'pitch': 0.0},
    ],
  };

  final bundle = CampusBundle.buildJson(
    campus: campus,
    overlays: overlays,
    connectionDirections: connectionDirections,
    pretty: false,
  );
  stdout.writeln('[simulador] bundle generado: ${CampusBundle.describe(bundle)}');

  // ── 2) Publicar bundle en el backend ──
  final putBundle = await HttpClient()
      .putUrl(Uri.parse('$base/api/bundle'))
      .then((req) async {
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(bundle));
    final res = await req.close();
    return res.statusCode;
  });
  stdout.writeln('[simulador] PUT /api/bundle -> $putBundle');
  if (putBundle != 200) {
    stderr.writeln('ERROR: el bundle no se publicó');
    exitCode = 1;
    return;
  }

  // ── 3) Publicar imágenes de panorama (usando las descargadas de internet) ──
  final panosDir = Directory('tools/e2e_panos');
  final panoPaths = <String, String>{
    nEntrada.id: 'pano_e2e_a.jpg',
    nPasillo.id: 'pano_e2e_b.jpg',
    nLab.id: 'pano_e2e_c.jpg',
  };
  final client = HttpClient();
  for (final entry in panoPaths.entries) {
    final file = File('${panosDir.path}/${entry.value}');
    if (!file.existsSync()) {
      stderr.writeln('ERROR: falta ${file.path}');
      continue;
    }
    final req = await client.putUrl(Uri.parse('$base/api/images/${entry.key}'));
    req.headers.contentType = ContentType.binary;
    req.add(file.readAsBytesSync());
    final res = await req.close();
    await _drain(res);
    stdout.writeln(
        '[simulador] PUT /api/images/${entry.key} (${file.lengthSync()} B) -> ${res.statusCode}');
  }
  client.close(force: true);

  stdout.writeln('[simulador] listo.');
}

Future<void> _drain(HttpClientResponse res) async {
  await res.forEach((_) {});
}