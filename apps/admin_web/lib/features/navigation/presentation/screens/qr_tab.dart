import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:campus_domain/campus_domain.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/utils/app_notifications.dart';
import 'package:admin_web/core/utils/qr_image_renderer.dart';
import 'package:admin_web/core/utils/web_file_io.dart';
import 'package:admin_web/features/navigation/data/datasources/mock_campus_data.dart';

/// Generador de códigos QR de ubicación: individual y en masa.
///
/// Cada QR codifica `* T:id|nombre *` (dos identificadores redundantes) para
/// edificios, pisos, zonas y nodos, y se puede descargar como PNG para
/// imprimir/pegarlo en el campus. El escáner de la app móvil lee el mismo
/// formato.
class QrTab extends StatefulWidget {
  const QrTab({super.key});

  @override
  State<QrTab> createState() => _QrTabState();
}

class _QrEntry {
  final CampusQrReference ref;
  final String subtitle;

  _QrEntry({required this.ref, required this.subtitle});
}

class _QrTabState extends State<QrTab> {
  CampusQrEntityType _type = CampusQrEntityType.zone;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final entries = _entriesFor(_type);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIntroCard(),
        const SizedBox(height: 16),
        _buildTypeSelector(),
        const SizedBox(height: 8),
        _buildActionsBar(entries),
        const SizedBox(height: 8),
        _buildTypeDescription(),
        const SizedBox(height: 16),
        for (final entry in entries) _buildEntryTile(entry),
        if (entries.isEmpty)
          _emptyHint('No hay elementos para este nivel. Crea datos primero.'),
      ],
    );
  }

  String _entityTitle(CampusQrEntityType type) {
    switch (type) {
      case CampusQrEntityType.building:
        return 'Edificios';
      case CampusQrEntityType.floor:
        return 'Pisos';
      case CampusQrEntityType.zone:
        return 'Zonas';
      case CampusQrEntityType.node:
        return 'Nodos';
    }
  }

  String _entityDescription(CampusQrEntityType type) {
    switch (type) {
      case CampusQrEntityType.building:
        return 'Un QR por edificio. Al escanearlo, la app posiciona al usuario '
            'en el primer nodo accesible del edificio.';
      case CampusQrEntityType.floor:
        return 'Un QR por piso. Al escanearlo, la app ubica al usuario en la '
            'entrada del piso.';
      case CampusQrEntityType.zone:
        return 'Un QR por zona (aula, pasillo, escaleras...). Al escanearlo, la '
            'app ubica al usuario en el nodo de entrada de la zona.';
      case CampusQrEntityType.node:
        return 'Un QR por nodo (punto de captura 360°). Es la referencia más '
            'precisa: posiciona al usuario exactamente en el nodo.';
    }
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
                const Icon(Icons.qr_code_2, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Generador de códigos QR', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cada código usa el formato seguro "* T:id|nombre *" con el tipo, '
              'el ID y el nombre de la ubicación. Al escanearlo, la app móvil '
              'detecta dónde estás al instante.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '● Generación individual: botón "QR" en cada fila.\n'
              '● Generación masiva: marca varias filas y pulsa "Generar en masa".\n'
              '● Los QR se descargan como PNG para imprimir y pegar en el campus.',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<CampusQrEntityType>(
      segments: CampusQrEntityType.values
          .map((t) => ButtonSegment<CampusQrEntityType>(
                value: t,
                icon: Icon(_iconForType(t)),
                label: Text(_entityTitle(t)),
              ))
          .toList(),
      selected: {_type},
      onSelectionChanged: (v) => setState(() {
        _type = v.first;
        _selected.clear();
      }),
    );
  }

  Widget _buildActionsBar(List<_QrEntry> entries) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selected.isEmpty
                ? null
                : () => _generateMass(entries.where((e) => _selected.contains(e.ref.id))),
            icon: const Icon(Icons.qr_code),
            label: Text(
              'Generar en masa (${_selected.length})',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Seleccionar todos',
          onPressed: entries.isEmpty
              ? null
              : () => setState(() {
                    _selected
                      ..clear()
                      ..addAll(entries.map((e) => e.ref.id));
                  }),
          icon: const Icon(Icons.select_all),
        ),
        IconButton.outlined(
          tooltip: 'Limpiar selección',
          onPressed: _selected.isEmpty
              ? null
              : () => setState(_selected.clear),
          icon: const Icon(Icons.deselect),
        ),
      ],
    );
  }

  Widget _buildTypeDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        _entityDescription(_type),
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
      ),
    );
  }

  Widget _buildEntryTile(_QrEntry entry) {
    final selected = _selected.contains(entry.ref.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 24,
          child: Checkbox(
            value: selected,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected.add(entry.ref.id);
              } else {
                _selected.remove(entry.ref.id);
              }
            }),
          ),
        ),
        title: Text(
          entry.ref.name.isEmpty ? entry.ref.id : entry.ref.name,
        ),
        subtitle: Text(
          '${entry.ref.id} · ${entry.subtitle}',
        ),
        trailing: IconButton(
          tooltip: 'Descargar QR individual',
          icon: const Icon(Icons.qr_code_2),
          onPressed: () => _generateSingle(entry),
        ),
      ),
    );
  }

  IconData _iconForType(CampusQrEntityType type) {
    switch (type) {
      case CampusQrEntityType.building:
        return Icons.apartment;
      case CampusQrEntityType.floor:
        return Icons.layers;
      case CampusQrEntityType.zone:
        return Icons.folder_open;
      case CampusQrEntityType.node:
        return Icons.location_on;
    }
  }

  IconData _iconForPrefix(String prefix) {
    switch (prefix) {
      case 'B':
        return Icons.apartment;
      case 'F':
        return Icons.layers;
      case 'N':
        return Icons.location_on;
      default:
        return Icons.folder_open;
    }
  }

  List<_QrEntry> _entriesFor(CampusQrEntityType type) {
    final campus = MockCampusData.campus;
    final entries = <_QrEntry>[];

    switch (type) {
      case CampusQrEntityType.building:
        for (final building in campus.buildings) {
          final floors = campus.getFloorsForBuilding(building.id).length;
          entries.add(_QrEntry(
            ref: CampusQrReference(
              type: type,
              id: building.id,
              name: building.name,
            ),
            subtitle: '$floors piso(s)',
          ));
        }
      case CampusQrEntityType.floor:
        for (final floor in campus.floors) {
          final buildingName =
              campus.getBuilding(floor.buildingId)?.name ?? floor.buildingId;
          entries.add(_QrEntry(
            ref: CampusQrReference(
              type: type,
              id: floor.id,
              name: floor.name,
            ),
            subtitle: 'Nivel ${floor.level} · $buildingName',
          ));
        }
      case CampusQrEntityType.zone:
        for (final zone in campus.zones) {
          final floorName = campus.getFloor(zone.floorId)?.name ?? zone.floorId;
          entries.add(_QrEntry(
            ref: CampusQrReference(
              type: type,
              id: zone.id,
              name: zone.name,
            ),
            subtitle: '${zone.type.name} · $floorName',
          ));
        }
      case CampusQrEntityType.node:
        for (final node in campus.nodes) {
          final zoneName =
              node.zoneId == null ? null : campus.getZone(node.zoneId!)?.name;
          entries.add(_QrEntry(
            ref: CampusQrReference(
              type: type,
              id: node.id,
              name: node.name,
            ),
            subtitle: 'Piso ${node.floorLevel}'
                '${zoneName == null ? '' : ' · $zoneName'}',
          ));
        }
    }

    entries.sort((a, b) => a.ref.name.compareTo(b.ref.name));
    return entries;
  }

  String _codedValue(CampusQrReference ref) => CampusQrCode.encode(ref);

  String _filenameFor(CampusQrReference ref) =>
      QrImageRenderer.filenameFor(typePrefix: CampusQrCode.prefixFor(ref.type), id: ref.id);

  // ═══════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════

  Future<void> _generateSingle(_QrEntry entry) async {
    final value = _codedValue(entry.ref);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_iconForPrefix(CampusQrCode.prefixFor(entry.ref.type)),
                      color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.ref.name.isEmpty ? entry.ref.id : entry.ref.name,
                      style: AppTheme.headingMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.ref.id} · ${entry.subtitle}',
                style: AppTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.textSecondaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: value,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Código codificado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  value,
                  style: AppTheme.bodySmall.copyWith(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _downloadPng(entry),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar PNG'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateMass(Iterable<_QrEntry> entries) async {
    final list = entries.toList();
    if (list.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'QR en masa (${list.length})',
                        style: AppTheme.headingMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Descargar todos los PNG',
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadMassPng(list),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final entry = list[index];
                    return _QrCard(
                      entry: entry,
                      value: _codedValue(entry.ref),
                      onDownload: () => _downloadPng(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPng(_QrEntry entry) async {
    AppNotifications.showInfo(
      context,
      title: 'Generando PNG...',
      description: _filenameFor(entry.ref),
    );
    final bytes = await QrImageRenderer.renderPng(_codedValue(entry.ref));
    if (bytes == null) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error',
        description: 'No se pudo generar el QR para ${entry.ref.id}.',
      );
      return;
    }
    _saveBytes(_filenameFor(entry.ref), bytes);
  }

  Future<void> _downloadMassPng(List<_QrEntry> entries) async {
    AppNotifications.showInfo(
      context,
      title: 'Generando ${entries.length} QR...',
      description: 'Se descargarán los PNG.',
    );
    for (final entry in entries) {
      final bytes = await QrImageRenderer.renderPng(_codedValue(entry.ref));
      if (bytes != null) {
        _saveBytes(_filenameFor(entry.ref), bytes);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  void _saveBytes(String filename, Uint8List bytes) {
    downloadBytes(filename, bytes, mime: 'image/png');
  }

  Widget _emptyHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
      ),
    );
  }
}

/// Tarjeta de QR dentro de la vista masiva.
class _QrCard extends StatefulWidget {
  final _QrEntry entry;
  final String value;
  final VoidCallback onDownload;

  const _QrCard({
    required this.entry,
    required this.value,
    required this.onDownload,
  });

  @override
  State<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<_QrCard> {
  ImageProvider? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await QrImageRenderer.renderPng(widget.value, size: 256);
    if (!mounted) return;
    setState(() {
      _image = bytes == null
          ? null
          : MemoryImage(Uint8List.fromList(bytes));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: _image == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image(
                      image: _image!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.entry.ref.name.isEmpty
                  ? widget.entry.ref.id
                  : widget.entry.ref.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall,
            ),
            Text(
              widget.entry.ref.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            IconButton(
              tooltip: 'Descargar PNG',
              icon: const Icon(Icons.download, size: 18),
              onPressed: widget.onDownload,
            ),
          ],
        ),
      ),
    );
  }
}