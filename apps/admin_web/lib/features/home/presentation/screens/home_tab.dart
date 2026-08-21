import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:campus_domain/campus_domain.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/utils/app_notifications.dart';
import 'package:admin_web/core/utils/app_settings.dart';
import 'package:admin_web/core/utils/backend_client.dart';
import 'package:admin_web/core/utils/campus_bundle_export.dart';
import 'package:admin_web/core/utils/home_editor_storage.dart';
import 'package:admin_web/core/utils/nav_start_storage.dart';
import 'package:admin_web/core/utils/web_file_io.dart';
import 'package:admin_web/features/navigation/data/datasources/mock_campus_data.dart';

/// Editor del fondo de la pantalla de inicio de la app móvil.
///
/// Permite elegir el tipo (imagen, video, carrusel o panorama 360°), subir los
/// archivos de media, previsualizarlos y publicarlos junto con el bundle en el
/// backend local. La app móvil descarga la configuración y los media al
/// sincronizar.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, this.refreshTick = 0});

  /// Contador que el panel incrementa al entrar en esta pestaña; al cambiar,
  /// la pestaña vuelve a consultar el backend (estado publicado).
  final int refreshTick;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeMedia {
  final String id;
  final Uint8List bytes;
  final bool isVideo;
  final String name;

  const _HomeMedia({
    required this.id,
    required this.bytes,
    required this.isVideo,
    required this.name,
  });
}

class _HomeTabState extends State<HomeTab> {
  HomeBackgroundType _type = HomeBackgroundType.image;
  final List<_HomeMedia> _media = [];
  int _intervalSeconds = 5;
  bool _publishing = false;

  // Hidratación del estado persistido (evita volver a guardar durante la carga).
  bool _hydrating = true;

  // Estado publicado en el backend, para la sección de verificación.
  bool _publishedLoading = false;
  String? _publishedBundleJson;
  String? _publishedVersion;
  String? _publishedSummary;
  List<String> _publishedHomeMediaIds = const [];
  String? _publishedError;
  bool _restoringPublished = false;

  String? _startBuildingId;
  String? _startFloorId;
  String? _startZoneId;
  String? _startNodeId;

  static int _idCounter = 0;

  bool get _isVideoType => _type == HomeBackgroundType.video;

  List<String> get _localMediaIds => _media.map((m) => m.id).toList();

  @override
  void initState() {
    super.initState();
    NavStartStorage.loadStartNodeId().then((id) {
      if (!mounted) return;
      setState(() {
        _startNodeId = id;
        _restoreCascadeFor(id);
      });
    });
    _hydrateEditorState();
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _hydrateEditorState();
    }
  }

  /// Restaura el editor desde el almacenamiento local (byte store + storage)
  /// para que la configuración y los media sobrevivan a la recarga de página.
  Future<void> _hydrateEditorState() async {
    final persisted = await HomeEditorStorage.loadState();
    if (!mounted) return;
    if (persisted != null) {
      final restored = <_HomeMedia>[];
      for (final m in persisted.media) {
        final bytes = await HomeEditorStorage.loadMediaBytes(m.id);
        if (bytes != null) {
          restored.add(_HomeMedia(
            id: m.id,
            bytes: bytes,
            isVideo: m.isVideo,
            name: m.name,
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        _type = persisted.type;
        _intervalSeconds = persisted.intervalSeconds;
        _media
          ..clear()
          ..addAll(restored);
      });
    }
    _hydrating = false;
    await _loadPublishedStatus();
  }

  /// Persiste el estado actual del editor (config + bytes) para la recarga.
  Future<void> _persistEditor() async {
    if (_hydrating) return;
    await HomeEditorStorage.saveState(HomeEditorState(
      type: _type,
      intervalSeconds: _intervalSeconds,
      media: _media
          .map((m) => HomeEditorMedia(
                id: m.id,
                name: m.name,
                isVideo: m.isVideo,
              ))
          .toList(),
    ));
    for (final m in _media) {
      await HomeEditorStorage.saveMediaBytes(m.id, m.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIntroCard(),
        const SizedBox(height: 16),
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildMediaSection(),
        if (_type == HomeBackgroundType.carousel) ...[
          const SizedBox(height: 16),
          _buildIntervalSection(),
        ],
        const SizedBox(height: 16),
        _buildPreviewSection(),
        const SizedBox(height: 16),
        _buildStartLocationSection(),
        const SizedBox(height: 16),
        _buildPublishSection(),
        const SizedBox(height: 16),
        _buildPublishedStatusCard(),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Fondo de la pantalla de inicio', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configura cómo se ve la pantalla de inicio de la app móvil: '
              'una imagen, un video, un carrusel de imágenes o un panorama '
              'interactivo 360°. Publica los media y el bundle para que el '
              'teléfono lo descargue al sincronizar.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '● Para el tipo panorama 360° usa una foto esférica o ecuirectangular.\n'
              '● Para el carrusel 360° sube varias fotos esféricas: cada una '
              'rota una vuelta completa y luego pasa a la siguiente.',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo de fondo', style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            SegmentedButton<HomeBackgroundType>(
              segments: const [
                ButtonSegment(
                  value: HomeBackgroundType.image,
                  icon: Icon(Icons.image),
                  label: Text('Imagen'),
                ),
                ButtonSegment(
                  value: HomeBackgroundType.video,
                  icon: Icon(Icons.play_circle),
                  label: Text('Video'),
                ),
                ButtonSegment(
                  value: HomeBackgroundType.carousel,
                  icon: Icon(Icons.view_carousel),
                  label: Text('Carrusel 360°'),
                ),
                ButtonSegment(
                  value: HomeBackgroundType.panorama,
                  icon: Icon(Icons.view_in_ar),
                  label: Text('360°'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (v) {
                setState(() => _type = v.first);
                _persistEditor();
              },
            ),
            const SizedBox(height: 8),
            Text(
              _typeDescription(_type),
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  String _typeDescription(HomeBackgroundType type) {
    switch (type) {
      case HomeBackgroundType.image:
        return 'Una sola imagen de fondo. Ideal para un arranque rápido y ligero.';
      case HomeBackgroundType.video:
        return 'Un video de fondo en bucle. Añade movimiento a la presentación.';
      case HomeBackgroundType.carousel:
        return 'Carrusel 360° interactivo: cada imagen rota una vuelta '
            'completa durante el tiempo indicado y luego avanza a la siguiente. '
            'Usa fotos esféricas/equirectangulares.';
      case HomeBackgroundType.panorama:
        return 'Foto 360° interactiva: el usuario puede girar/mirar alrededor.';
    }
  }

  Widget _buildMediaSection() {
    final maxForType = switch (_type) {
      HomeBackgroundType.image => 1,
      HomeBackgroundType.video => 1,
      HomeBackgroundType.panorama => 1,
      HomeBackgroundType.carousel => 8,
    };
    final canAdd = _media.length < maxForType;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Media (${_media.length}/$maxForType)',
                    style: AppTheme.headingMedium),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: canAdd && !_publishing ? _addMedia : null,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_isVideoType ? 'Subir video' : 'Subir imagen'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_media.isEmpty)
              Text(
                _isVideoType
                    ? 'Aún no hay videos. Sube uno para usarlo como fondo.'
                    : 'Aún no hay imágenes. Sube una para usarla como fondo.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final m in _media) _buildMediaThumb(m)],
              ),
            if (_isVideoType && _media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'El video se reproduce en bucle y sin sonido en la app móvil.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumb(_HomeMedia media) {
    return SizedBox(
      width: 120,
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: media.isVideo
                    ? Container(
                        color: Colors.black87,
                        child: const Icon(Icons.movie, color: Colors.white, size: 32),
                      )
                    : Image.memory(
                        media.bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      media.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(fontSize: 11),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar',
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: _publishing
                        ? null
                        : () {
                            setState(() => _media.remove(media));
                            _persistEditor();
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Intervalo del carrusel', style: AppTheme.headingMedium),
                const Spacer(),
                Text('$_intervalSeconds s', style: AppTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _intervalSeconds.toDouble(),
              min: 2,
              max: 15,
              divisions: 13,
              label: '$_intervalSeconds s',
              onChanged: _publishing
                  ? null
                  : (v) {
                      setState(() => _intervalSeconds = v.round());
                      _persistEditor();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista previa', style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: _previewPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPlaceholder() {
    if (_media.isEmpty) {
      return Container(
        color: const Color(0xFF37474F),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
            const SizedBox(height: 8),
            Text(
              'Sube media para ver una vista previa',
              style: AppTheme.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final Widget content;
    switch (_type) {
      case HomeBackgroundType.video:
        content = Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Icon(Icons.play_arrow, color: Colors.white70, size: 64),
        );
      case HomeBackgroundType.panorama:
        content = Image.memory(
          _media.first.bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      case HomeBackgroundType.image:
        content = Image.memory(
          _media.first.bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      case HomeBackgroundType.carousel:
        content = Image.memory(
          _media.first.bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        if (_type == HomeBackgroundType.carousel && _media.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: _badge('${_media.length} media · $_intervalSeconds s'),
          )
        else
          Positioned(
            bottom: 8,
            right: 8,
            child: _badge(_typeLabel),
          ),
      ],
    );
  }

  String get _typeLabel {
    switch (_type) {
      case HomeBackgroundType.image:
        return 'Imagen de fondo';
      case HomeBackgroundType.video:
        return 'Video de fondo';
      case HomeBackgroundType.carousel:
        return 'Carrusel 360°';
      case HomeBackgroundType.panorama:
        return 'Panorama 360°';
    }
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: AppTheme.bodySmall.copyWith(color: Colors.white)),
    );
  }

  // ═══════════════════════════════════════════
  // UBICACIÓN DE INICIO POR DEFECTO
  // ═══════════════════════════════════════════

  CampusModel get _campus => MockCampusData.campus;

  List<BuildingModel> get _startBuildings => _campus.buildings.toList();

  List<FloorModel> get _startFloors {
    if (_startBuildingId == null) return [];
    return _campus.floors
        .where((f) => f.buildingId == _startBuildingId)
        .toList();
  }

  List<ZoneModel> get _startZones {
    if (_startFloorId == null) return [];
    return _campus.zones
        .where((z) => z.floorId == _startFloorId)
        .toList();
  }

  List<NodeModel> get _startNodes {
    if (_startZoneId == null) return [];
    return _campus.nodes.where((n) => n.zoneId == _startZoneId).toList();
  }

  NodeModel? get _selectedStartNode =>
      _startNodeId != null ? MockCampusData.getNodeById(_startNodeId!) : null;

  /// Reconstruye el cascade (edificio→piso→zona) a partir de un nodo ya
  /// seleccionado, para que los dropdowns se vean coherentes al recargar.
  void _restoreCascadeFor(String? nodeId) {
    if (nodeId == null) return;
    final node = MockCampusData.getNodeById(nodeId);
    if (node == null) return;
    final zone = _campus.getZone(node.zoneId!);
    final floor = _campus.getFloor(zone?.floorId ?? '');
    _startBuildingId = zone?.buildingId ?? floor?.buildingId;
    _startFloorId = zone?.floorId ?? floor?.id;
    _startZoneId = zone?.id;
  }

  void _modifyStartSelection({
    String? buildingId,
    String? floorId,
    String? zoneId,
    String? nodeId,
  }) {
    setState(() {
      if (buildingId != _startBuildingId) {
        _startBuildingId = buildingId;
        _startFloorId = null;
        _startZoneId = null;
        _startNodeId = null;
      } else if (floorId != _startFloorId) {
        _startFloorId = floorId;
        _startZoneId = null;
        _startNodeId = null;
      } else if (zoneId != _startZoneId) {
        _startZoneId = zoneId;
        _startNodeId = null;
      } else if (nodeId != _startNodeId) {
        _startNodeId = nodeId;
        NavStartStorage.saveStartNodeId(nodeId);
      }
    });
  }

  Widget _buildStartLocationSection() {
    final node = _selectedStartNode;
    final zone = node != null ? _campus.getZone(node.zoneId!) : null;
    final floor = zone != null ? _campus.getFloor(zone.floorId) : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Ubicación de inicio por defecto', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Elige el punto donde la app inicia el recorrido al presionar '
              '"Iniciar recorrido". Se publica como parte del bundle.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _dropdown(
              label: 'Edificio',
              hint: 'Selecciona edificio',
              value: _startBuildingId,
              items: _startBuildings,
              itemId: (b) => b.id,
              itemLabel: (b) => b.name,
              onSelected: (id) => _modifyStartSelection(buildingId: id),
            ),
            _dropdown(
              label: 'Piso',
              hint: 'Selecciona piso',
              value: _startFloors.map((f) => f.id).contains(_startFloorId)
                  ? _startFloorId
                  : null,
              items: _startFloors,
              itemId: (f) => f.id,
              itemLabel: (f) => 'Piso ${f.level}',
              onSelected: (id) => _modifyStartSelection(floorId: id),
            ),
            _dropdown(
              label: 'Zona',
              hint: 'Selecciona zona',
              value: _startZones.map((z) => z.id).contains(_startZoneId)
                  ? _startZoneId
                  : null,
              items: _startZones,
              itemId: (z) => z.id,
              itemLabel: (z) => z.name,
              onSelected: (id) => _modifyStartSelection(zoneId: id),
            ),
            _dropdown(
              label: 'Nodo de inicio',
              hint: 'Selecciona el punto de inicio',
              value: _startNodes.map((n) => n.id).contains(_startNodeId)
                  ? _startNodeId
                  : null,
              items: _startNodes,
              itemId: (n) => n.id,
              itemLabel: (n) => n.name,
              onSelected: (id) => _modifyStartSelection(nodeId: id),
            ),
            const SizedBox(height: 16),
            if (node == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sin inicio por defecto: la app pedirá el punto al usuario.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE53935)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Color(0xFFE53935), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${node.name} · ${zone?.name ?? ''} · ${floor?.name ?? ''} (piso ${floor?.level ?? '?'})',
                        style: AppTheme.bodyMedium.copyWith(color: const Color(0xFFB71C1C)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required String hint,
    required String? value,
    required List<T> items,
    required String Function(T) itemId,
    required String Function(T) itemLabel,
    required void Function(String?) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        hint: Text(hint),
        items: [
          for (final item in items)
            DropdownMenuItem(value: itemId(item), child: Text(itemLabel(item))),
        ],
        onChanged: items.isEmpty ? null : onSelected,
      ),
    );
  }

  Widget _buildPublishSection() {
    final backendUrl = AppSettings.defaultBackendBaseUrl;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Publicar en el teléfono', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sube los media y actualiza el bundle en backend $backendUrl. '
              'La app móvil lo descarga automáticamente al sincronizar.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_currentConfig() != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Configuración: ${_currentConfig()!.describe()}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                ),
              ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _publishing ? null : _exportBundle,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar bundle'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _publishing || _media.isEmpty ? null : _publish,
                  icon: _publishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: Text(_publishing ? 'Publicando...' : 'Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════

  HomeBackgroundConfig? _currentConfig() {
    if (_media.isEmpty) return null;
    return HomeBackgroundConfig(
      type: _type,
      mediaIds: _media.map((m) => m.id).toList(),
      intervalSeconds: _intervalSeconds,
    );
  }

  Future<void> _addMedia() async {
    try {
      final bytes = _isVideoType
          ? await pickVideoBytes()
          : await pickImageBytes();
      if (bytes == null) return;
      final id = 'home_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
      final name = '${_isVideoType ? 'video' : 'img'}${_media.length + 1}';
      final media = _HomeMedia(
        id: id,
        bytes: bytes,
        isVideo: _isVideoType,
        name: name,
      );
      if (!mounted) return;
      setState(() {
        if (_isVideoType ||
            _type == HomeBackgroundType.image ||
            _type == HomeBackgroundType.panorama) {
          _media.clear();
        }
        _media.add(media);
      });
      unawaited(_persistEditor());
      if (!mounted) return;
      AppNotifications.showSuccess(
        context,
        title: _isVideoType ? 'Video agregado' : 'Imagen agregada',
        description: media.name,
      );
    } on UnsupportedError {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'No disponible',
        description: 'La subida de archivos solo funciona en el navegador.',
      );
    }
  }

  void _exportBundle() {
    try {
      final config = _currentConfig();
      final navigation =
          NavigationConfig(defaultStartNodeId: _startNodeId);
      final bundle = CampusBundleExport.buildBundle(
        home: config,
        navigation: navigation,
      );
      downloadFile('campus_bundle.json', bundle);
      AppNotifications.showSuccess(
        context,
        title: 'Bundle exportado',
        description: 'Con la configuración del fondo de inicio y navegación.',
      );
    } catch (e) {
      AppNotifications.showError(
        context,
        title: 'Error al exportar',
        description: 'No se pudo generar el bundle: $e',
      );
    }
  }

  Future<void> _publish() async {
    final config = _currentConfig();
    if (config == null) return;

    final url = await AppSettings.backendBaseUrl();
    if (!mounted) return;

    setState(() => _publishing = true);
    try {
      var uploaded = 0;
      for (final m in _media) {
        final ok = await publishHomeMedia(url, m.id, m.bytes);
        if (ok) uploaded++;
      }
      if (!mounted) return;
      if (uploaded != _media.length) {
        AppNotifications.showWarning(
          context,
          title: 'Media con errores',
          description: '$uploaded/${_media.length} media subidos. Revisa el backend.',
        );
      }

      final bundle = CampusBundleExport.buildBundle(
        home: config,
        navigation: NavigationConfig(defaultStartNodeId: _startNodeId),
      );
      final okBundle = await publishBundle(url, bundle);
      if (!mounted) return;
      if (!okBundle) {
        AppNotifications.showError(
          context,
          title: 'No se pudo publicar',
          description: 'El backend no aceptó el bundle en $url.',
        );
        return;
      }
      AppNotifications.showSuccess(
        context,
        title: 'Fondo publicado',
        description:
            '${config.describe()} · $uploaded media enviados al teléfono'
            '${_startNodeId != null ? ' · Inicio: ${_selectedStartNode?.name ?? _startNodeId}' : ''}.',
      );
      await _loadPublishedStatus();
    } on UnsupportedError {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'No disponible',
        description: 'La publicación solo funciona dentro del navegador.',
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al publicar',
        description: '$e',
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  // ═══════════════════════════════════════════
  // ESTADO PUBLICADO EN EL BACKEND
  // ═══════════════════════════════════════════

  Widget _buildPublishedStatusCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Publicado en el backend', style: AppTheme.headingMedium),
                const Spacer(),
                if (_publishedLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Consultar de nuevo',
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed:
                        _restoringPublished || _publishing ? null : _loadPublishedStatus,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (_publishedError != null)
              Text(
                'No se pudo consultar el backend: $_publishedError',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
              )
            else if (_publishedBundleJson == null)
              Text(
                'Aún no hay bundle publicado. Usa "Publicar" para enviarlo al '
                'teléfono.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
              )
            else ...[
              Text(
                'Bundle versión ${_publishedVersion ?? '?'} presente en el backend.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
              ),
              if (_publishedSummary != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(_publishedSummary!, style: AppTheme.bodyMedium),
                ),
            ],
            if (_publishedBundleJson != null) ...[
              const Divider(height: 24),
              Text(
                'Media del fondo publicados (${_publishedHomeMediaIds.length}):',
                style: AppTheme.bodyMedium,
              ),
              if (_publishedHomeMediaIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in _publishedHomeMediaIds)
                        Chip(
                          label: Text(id, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _localMediaIds.contains(id)
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _restoringPublished || _publishing
                      ? null
                      : _restoreFromBackend,
                  icon: _restoringPublished
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    _restoringPublished
                        ? 'Restaurando...'
                        : 'Restaurar desde el backend',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Consulta el backend: bundle publicado + lista de media del fondo de
  /// inicio. Útil para verificar que la app móvil recibirá lo mismo.
  Future<void> _loadPublishedStatus() async {
    if (_publishedLoading) return;
    setState(() {
      _publishedLoading = true;
      _publishedError = null;
    });
    final url = await AppSettings.backendBaseUrl();
    if (!mounted) return;
    try {
      final bundleJson = await fetchBundle(url);
      String? version;
      String? summary;
      if (bundleJson != null) {
        try {
          final data = CampusBundle.parse(bundleJson);
          version = data.version;
          summary = CampusBundle.describe(bundleJson);
        } catch (_) {
          summary = 'El bundle publicado no se puede interpretar como CampusBundle.';
        }
      }
      final mediaIds = await fetchHomeMediaList(url);
      if (!mounted) return;
      setState(() {
        _publishedBundleJson = bundleJson;
        _publishedVersion = version;
        _publishedSummary = summary;
        _publishedHomeMediaIds = mediaIds;
        _publishedLoading = false;
      });
    } on UnsupportedError {
      if (!mounted) return;
      setState(() {
        _publishedLoading = false;
        _publishedError = 'Solo disponible dentro del navegador';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _publishedLoading = false;
        _publishedError = '$e';
      });
    }
  }

  /// Restaura el editor desde lo publicado en el backend: descarga los media
  /// del fondo, aplica tipo/intervalo y el nodo de inicio del bundle.
  Future<void> _restoreFromBackend() async {
    final bundleJson = _publishedBundleJson;
    if (bundleJson == null) return;
    setState(() => _restoringPublished = true);
    final url = await AppSettings.backendBaseUrl();
    try {
      final data = CampusBundle.parse(bundleJson);
      final home = data.home;
      if (home == null || home.mediaIds.isEmpty) {
        if (!mounted) return;
        await _applyRestoredHome(null);
        await _applyRestoredStart(data.navigation?.defaultStartNodeId);
        return;
      }
      final restored = <_HomeMedia>[];
      for (final id in home.mediaIds) {
        final bytes = await fetchHomeMediaBytes(url, id);
        if (bytes == null) continue;
        restored.add(_HomeMedia(
          id: id,
          bytes: bytes,
          isVideo: home.type == HomeBackgroundType.video,
          name: home.type == HomeBackgroundType.video ? 'video' : 'img',
        ));
      }
      if (!mounted) return;
      await _applyRestoredHome(home, media: restored);
      await _applyRestoredStart(data.navigation?.defaultStartNodeId);
      if (!mounted) return;
      AppNotifications.showSuccess(
        context,
        title: 'Fondo restaurado',
        description:
            '${home.describe()} · ${restored.length} media descargados del backend.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _restoringPublished = false);
      AppNotifications.showError(
        context,
        title: 'No se pudo restaurar',
        description: '$e',
      );
    }
  }

  Future<void> _applyRestoredHome(
    HomeBackgroundConfig? home, {
    List<_HomeMedia> media = const [],
  }) async {
    setState(() {
      if (home == null) {
        _media.clear();
        _type = HomeBackgroundType.image;
        _intervalSeconds = 5;
      } else {
        _media
          ..clear()
          ..addAll(media);
        _type = home.type;
        _intervalSeconds = home.intervalSeconds;
      }
      _restoringPublished = false;
    });
    await _persistEditor();
  }

  Future<void> _applyRestoredStart(String? nodeId) async {
    await NavStartStorage.saveStartNodeId(nodeId);
    if (!mounted) return;
    setState(() {
      _startNodeId = nodeId;
      _restoreCascadeFor(nodeId);
    });
  }
}