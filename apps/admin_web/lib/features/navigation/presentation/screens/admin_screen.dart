import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/utils/app_notifications.dart';
import 'package:admin_web/core/utils/app_settings.dart';
import 'package:admin_web/core/utils/web_file_io.dart';
import 'package:admin_web/core/utils/local_image_storage.dart';
import 'package:admin_web/core/utils/campus_bundle_export.dart';
import 'package:admin_web/core/utils/backend_client.dart';
import 'package:admin_web/features/navigation/domain/models/node_model.dart';
import 'package:admin_web/features/navigation/domain/models/zone_model.dart';
import 'package:admin_web/features/navigation/domain/models/floor_model.dart';
import 'package:admin_web/features/navigation/domain/models/building_model.dart';
import 'package:admin_web/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:admin_web/features/navigation/data/datasources/node_type_settings.dart';
import 'package:admin_web/features/navigation/presentation/screens/catalog_tab.dart';
import 'package:admin_web/features/navigation/presentation/screens/qr_tab.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/overlay_storage.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/connection_direction_storage.dart';
import 'package:admin_web/features/panorama_viewer/presentation/screens/overlay_editor_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ═══ FILTROS DE ESTRUCTURA ═══
  String? _selectedBuildingId;
  String? _selectedFloorId;
  String? _selectedZoneId;
  String? _selectedNodeId;

  // ═══ FORMULARIO (AGREGAR / EDITAR) ═══
  NodeModel? _editingNode;
  final _formKey = GlobalKey<FormState>();
  final _nodeIdController = TextEditingController();
  final _nodeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _headingController = TextEditingController();
  final _destLabelController = TextEditingController();
  int? _formFloorLevel;
  String? _formZoneId;
  NodeZone? _formNodeZone;
  final List<String> _formConnections = [];
  String? _connectionToAdd;
  Uint8List? _pickedImageBytes;
  bool _hasExistingImage = false;
  bool _busy = false;

  // ═══ BACKEND (PUSH) ═══
  final _backendUrlController = TextEditingController();
  bool _publishing = false;

  // ═══ CONFIG ═══
  int _quickPreviewDelay = AppSettings.defaultQuickPreviewDelay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    await MockCampusData.loadFromFile();
    await OverlayStorage.loadPersisted();
    await ConnectionDirectionStorage.loadPersisted();
    await NodeTypeSettings.load();
    _quickPreviewDelay = await AppSettings.quickPreviewDelaySeconds();
    _backendUrlController.text = await AppSettings.backendBaseUrl();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nodeIdController.dispose();
    _nodeNameController.dispose();
    _descriptionController.dispose();
    _headingController.dispose();
    _destLabelController.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  // UI PRINCIPAL
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree), text: 'Estructura'),
            Tab(icon: Icon(Icons.add_location_alt), text: 'Agregar'),
            Tab(icon: Icon(Icons.manage_search), text: 'Catálogo'),
            Tab(icon: Icon(Icons.qr_code_2), text: 'QR'),
            Tab(icon: Icon(Icons.settings), text: 'Config'),
            Tab(icon: Icon(Icons.merge_type), text: 'Overlays'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStructureView(context),
          _buildAddView(context),
          CatalogTab(onChanged: () => setState(() {})),
          const QrTab(),
          _buildConfigView(context),
          _buildOverlaysView(context),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: ESTRUCTURA (jerarquía + lista + ficha)
  // ═══════════════════════════════════════════

  Widget _buildStructureView(BuildContext context) {
    final campus = MockCampusData.campus;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(text, style: AppTheme.headingMedium),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildStatsRow(context),

        heading('Filtrar'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSelector(
                  label: 'Edificio',
                  icon: Icons.apartment,
                  value: campus.buildings.isEmpty
                      ? null
                      : (_selectedBuildingId ?? campus.buildings.first.id),
                  items: campus.buildings
                      .map((b) => DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(b.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedBuildingId = v;
                    _selectedFloorId = null;
                    _selectedZoneId = null;
                    _selectedNodeId = null;
                  }),
                ),
                if (_selectedBuildingFloor() != null ||
                    (_selectedBuilding != null && _selectedBuilding!.hasFloors))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildSelector(
                      label: 'Piso',
                      icon: Icons.layers,
                      value: _selectedFloorId,
                      items: _selectedBuildingFloors()
                          .map((f) => DropdownMenuItem<String>(
                                value: f.id,
                                child: Text('${f.name} (${f.level})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedFloorId = v;
                        _selectedZoneId = null;
                        _selectedNodeId = null;
                      }),
                    ),
                  ),
                if (_selectedFloor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildSelector(
                      label: 'Zona',
                      icon: Icons.category,
                      value: _selectedZoneId,
                      items: _selectedFloorZones()
                          .map((z) => DropdownMenuItem<String>(
                                value: z.id,
                                child: Text(z.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedZoneId = v;
                        _selectedNodeId = null;
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_selectedZone == null)
          _buildEmptyHint(
            icon: Icons.filter_alt_outlined,
            message: 'Selecciona un edificio y un piso para ver sus zonas.',
          )
        else
          heading('Nodos en "${_selectedZone!.name}"'),
        if (_selectedZone != null)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _selectedZoneNodes().isEmpty
                ? _buildEmptyHint(
                    icon: Icons.location_off_outlined,
                    message: 'Esta zona no tiene nodos aún. Úsalos en Admin → Agregar.',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedZoneNodes().length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final node = _selectedZoneNodes()[index];
                      return _buildNodeTile(context, node);
                    },
                  ),
          ),

        if (_selectedZone != null) ...[
          heading('Estadísticas de la zona'),
          _buildZoneStatsCard(context),
        ],

        if (_selectedNode != null) ...[
          heading('Ficha del nodo'),
          _buildNodeDetailCard(context),
        ],
      ],
    );
  }

  Widget _buildSelector({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('selector_$label'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildNodeTile(BuildContext context, NodeModel node) {
    final isSelected = _selectedNodeId == node.id;
    return ListTile(
      trailing: const Icon(Icons.chevron_right),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundColor: _isDestination(node)
            ? AppTheme.secondaryColor.withValues(alpha: 0.15)
            : AppTheme.primaryColor.withValues(alpha: 0.12),
        child: Icon(
          _iconForZone(node.zone),
          color: _isDestination(node)
              ? AppTheme.secondaryColor
              : AppTheme.primaryColor,
        ),
      ),
      title: Text(node.name),
      subtitle: Text(
        '${node.id} · ${node.connectedNodeIds.length} conexiones',
        style: AppTheme.bodySmall,
      ),
      onTap: () => setState(() => _selectedNodeId = isSelected ? null : node.id),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final nodes = MockCampusData.allNodes;
    final destinations = MockCampusData.getDestinations();
    final campus = MockCampusData.campus;

    Widget stat(String label, int count, Color color) => Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: AppTheme.headingLarge.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: AppTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Row(
        children: [
          stat('Nodos', nodes.length, AppTheme.primaryColor),
          stat('Destinos', destinations.length, AppTheme.secondaryColor),
          stat('Pisos', campus.floors.length, AppTheme.warningColor),
          stat('Zonas', campus.zones.length, AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildZoneStatsCard(BuildContext context) {
    final zone = _selectedZone;
    if (zone == null) return const SizedBox.shrink();
    final nodes = _selectedZoneNodes();
    final entry = zone.entryNodeId != null
        ? MockCampusData.getNodeById(zone.entryNodeId!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForZoneType(zone.type),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name,
                    style: AppTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    zone.type.name.toUpperCase(),
                    style: AppTheme.bodySmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _kvRow('Nodos', '${nodes.length}'),
            _kvRow('Entrada', entry?.name ?? '—', isDest: true),
            _kvRow(
              'Zonas vecinas',
              zone.connectedZoneIds.join(', ').isEmpty
                  ? 'ninguna'
                  : zone.connectedZoneIds.join(', '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String label, String value, {bool isDest = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isDest ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeDetailCard(BuildContext context) {
    final node = _selectedNode;
    if (node == null) return const SizedBox.shrink();
    final nodeZone = MockCampusData.campus.getZone(node.zoneId ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(_iconForZone(node.zone), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name, style: AppTheme.headingMedium),
                      Text(node.id, style: AppTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kvRow('Zona', nodeZone?.name ?? '—'),
            _kvRow('Panorama ID', node.panoramaId),
            _kvRow('Heading', '${node.heading.toStringAsFixed(1)}°'),
            if (node.destinationLabel != null)
              _kvRow('Label destino', node.destinationLabel!),
            const SizedBox(height: 8),
            Text('Conexiones (${node.connectedNodeIds.length})',
                style: AppTheme.bodyMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: node.connectedNodeIds.map((id) {
                final conn = MockCampusData.getNodeById(id);
                return Chip(
                  label: Text(conn?.name ?? id, style: AppTheme.bodySmall),
                  avatar: const Icon(Icons.link, size: 14),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _startEditingNode(node),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteNode(node),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: AGREGAR (formulario validado)
  // ═══════════════════════════════════════════

  Widget _buildAddView(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_editingNode != null)
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              child: ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
                title: Text(
                  'Editando: ${_editingNode!.name} (${_editingNode!.id})',
                  style: AppTheme.bodyMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar edición',
                  onPressed: () => setState(() {
                    _editingNode = null;
                    _resetForm();
                  }),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Datos básicos',
            icon: Icons.info_outline,
            children: [
              TextFormField(
                controller: _nodeIdController,
                decoration: const InputDecoration(
                  labelText: 'ID único del nodo *',
                  hintText: 'Ej: P_AULA_105',
                  prefixIcon: Icon(Icons.tag),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final value = _nodeIdController.text.trim();
                  if (value.isEmpty) return 'Se requiere un ID.';
                  final existing = MockCampusData.getNodeById(value);
                  if (existing != null && _editingNode?.id != value) {
                    return 'El ID "$value" ya existe. Usa otro distinto.';
                  }
                  return null;
                },
              ),
              if (_nodeIdController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _idAvailabilityBanner(),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nodeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Se requiere el nombre.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Ubicación',
            icon: Icons.explore,
            children: [
              TextFormField(
                controller: _headingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Heading (0-360°)',
                  prefixIcon: Icon(Icons.explore_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final num? parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Ingresa un número.';
                  if (parsed < 0 || parsed > 360) {
                    return 'El heading debe estar entre 0 y 360.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('floor_${_editingNode?.id ?? 'new'}'),
                initialValue: _formFloorLevel,
                decoration: const InputDecoration(
                  labelText: 'Piso *',
                  prefixIcon: Icon(Icons.layers),
                ),
                items: _sortedFloors
                    .map((f) => DropdownMenuItem<int>(
                          value: f.level,
                          child: Text('${f.name} (nivel ${f.level})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _formFloorLevel = v;
                  _formZoneId = null;
                }),
                validator: (v) => v == null ? 'Selecciona un piso.' : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Zona y tipo',
            icon: Icons.category,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('zone_${_editingNode?.id ?? 'new'}'),
                initialValue: _formZoneId,
                decoration: const InputDecoration(
                  labelText: 'Zona *',
                  prefixIcon: Icon(Icons.folder_open),
                ),
                items: _formZoneFloor?.zoneIds
                        .map((id) => MockCampusData.campus.getZone(id))
                        .whereType<ZoneModel>()
                        .map((z) => DropdownMenuItem<String>(
                              value: z.id,
                              child: Text(z.name),
                            ))
                        .toList() ??
                    [],
                onChanged: (v) => setState(() => _formZoneId = v),
                validator: (v) => v == null ? 'Selecciona una zona.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<NodeZone>(
                key: ValueKey('type_${_editingNode?.id ?? 'new'}'),
                initialValue: _formNodeZone,
                decoration: const InputDecoration(
                  labelText: 'Tipo de nodo *',
                  prefixIcon: Icon(Icons.sell),
                ),
                items: NodeZone.values
                    .map((z) => DropdownMenuItem<NodeZone>(
                          value: z,
                          child: Text(_zoneLabel(z)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _formNodeZone = v),
                validator: (v) => v == null ? 'Selecciona el tipo.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destLabelController,
                decoration: const InputDecoration(
                  labelText: 'Label de destino (opcional)',
                  hintText: 'Ej: Aula 101',
                  prefixIcon: Icon(Icons.outlined_flag),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Conexiones (mínimo 2)',
            icon: Icons.link,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _formConnections.isEmpty
                    ? [
                        Text(
                          'Aún no hay conexiones agregadas.',
                          style: AppTheme.bodySmall,
                        ),
                      ]
                    : _formConnections.map((id) {
                        final conn = MockCampusData.getNodeById(id);
                        return InputChip(
                          label: Text(conn?.name ?? id, style: AppTheme.bodySmall),
                          avatar: const Icon(Icons.link, size: 14),
                          onDeleted: () => setState(
                              () => _formConnections.remove(id)),
                        );
                      }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('connections_${_editingNode?.id ?? 'new'}'),
                      initialValue: _connectionToAdd,
                      decoration: const InputDecoration(
                        labelText: 'Agregar conexión',
                        prefixIcon: Icon(Icons.add_link),
                      ),
                      items: _availableConnections
                          .map((id) => DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  _connectionLabel(id),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _connectionToAdd = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addConnection,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (_formConnections.length < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Se requieren al menos 2 conexiones para que el nodo sea navegable.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Foto del panorama',
            icon: Icons.photo_camera,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingNode == null
                              ? 'Puedes elegir la foto aquí mismo, antes de guardar. Se asocia al ID del nodo al guardar.'
                              : 'Foto asociada al nodo ${_editingNode!.id}',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasExistingImage
                              ? 'Ya existe una imagen guardada.'
                              : 'Sin imagen guardada.',
                          style: AppTheme.bodySmall.copyWith(
                            color: _hasExistingImage
                                ? AppTheme.successColor
                                : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Seleccionar imagen'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: _pickedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      )
                    : Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Text('Sin foto seleccionada',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _saveNode,
                  icon: const Icon(Icons.save),
                  label: Text(_editingNode == null ? 'Guardar nodo' : 'Actualizar nodo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _idAvailabilityBanner() {
    final id = _nodeIdController.text.trim();
    if (id.isEmpty) return const SizedBox.shrink();
    final isEditingSelf = _editingNode?.id == id;
    final exists = MockCampusData.getNodeById(id) != null;
    final available = !exists || isEditingSelf;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (available ? AppTheme.successColor : AppTheme.errorColor)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: available ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available
                  ? 'ID disponible.'
                  : 'El ID "$id" ya existe. Prueba con otro.',
              style: AppTheme.bodySmall.copyWith(
                color: available ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 3: CONFIG (calidad + export/import)
  // ═══════════════════════════════════════════

  Widget _buildConfigView(BuildContext context) {
    final validation = MockCampusData.repository.validate();
    final errors = validation.where((e) => e.severity == 'error').toList();
    final warnings = validation.where((e) => e.severity == 'warning').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Resumen de calidad',
          icon: Icons.verified,
          children: [
            Row(
              children: [
                _qualityBadge(
                  errors.isEmpty ? AppTheme.successColor : AppTheme.errorColor,
                  errors.isEmpty ? Icons.check_circle : Icons.error_outline,
                  errors.isEmpty
                      ? 'Campus válido'
                      : '${errors.length} error(es)',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errors.isEmpty
                        ? 'El campus está listo para exportar.'
                        : 'Corrige los errores antes de exportar.',
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (errors.isNotEmpty || warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final e in errors.take(6))
                _buildValidationLine(e.message, isError: true),
              for (final w in warnings.take(4))
                _buildValidationLine(w.message, isError: false),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Preferencias',
          icon: Icons.tune,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delay de vista rápida',
                          style: TextStyle(fontSize: 15)),
                      Text('Segundos que el visor se detiene en cada nodo.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: _quickPreviewDelay,
                  items: [
                    for (int i = AppSettings.minQuickPreviewDelay;
                        i <= AppSettings.maxQuickPreviewDelay;
                        i++)
                      DropdownMenuItem(value: i, child: Text('$i s')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _quickPreviewDelay = v);
                    await AppSettings.setQuickPreviewDelaySeconds(v);
                    if (!context.mounted) return;
                    AppNotifications.showSuccess(
                      context,
                      title: 'Preferencia guardada',
                      description: 'Vista rápida: $v segundo(s) por nodo.',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Publicar (Push al teléfono)',
          icon: Icons.cloud_upload,
          children: [
            Text(
              'Publica el bundle + las imágenes al backend local. La app móvil '
              'lo consume automáticamente al arrancar (sin botones en la app).',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _backendUrlController,
              decoration: const InputDecoration(
                labelText: 'URL del backend',
                hintText: 'http://127.0.0.1:8082',
                prefixIcon: Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _publishing ? null : _checkBackend,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Ver estado'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _publishing ? null : _publishToBackend,
                  icon: _publishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: Text(_publishing ? 'Publicando…' : 'Publicar todo'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Exportar',
          icon: Icons.upload_file,
          children: [
            Text(
              'Genera el bundle JSON (campus + overlays + direcciones) que la app móvil importa.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _exportBundle,
              icon: const Icon(Icons.download),
              label: const Text('Exportar bundle'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _previewBundle,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Vista previa'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: 'Importar',
          icon: Icons.file_open,
          children: [
            Text(
              'Carga un bundle JSON exportado previamente para seguir editándolo.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _importBundle,
              icon: const Icon(Icons.upload),
              label: const Text('Importar bundle'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _confirmReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              icon: const Icon(Icons.restore),
              label: const Text('Restablecer a datos de demo'),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _qualityBadge(Color color, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationLine(String message, {required bool isError}) {
    final color = isError ? AppTheme.errorColor : AppTheme.warningColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 4: OVERLAYS (editor 360°)
  // ═══════════════════════════════════════════

  Widget _buildOverlaysView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Editor de overlays 360°',
          icon: Icons.merge_type,
          children: [
            Text(
              'Añade flechas de guía, textos y botones sobre las fotos panorámicas, y define la dirección exacta de cada conexión.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OverlayEditorScreen(),
                  ),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir editor de overlays'),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS DE ESTRUCTURA
  // ═══════════════════════════════════════════

  BuildingModel? get _selectedBuilding {
    final id = _selectedBuildingId;
    if (id == null) return null;
    if (MockCampusData.campus.buildings.isEmpty) return null;
    if (!MockCampusData.campus.buildings.any((b) => b.id == id)) {
      return MockCampusData.campus.buildings.first;
    }
    return MockCampusData.campus.buildings.firstWhere((b) => b.id == id);
  }

  List<String>? _selectedBuildingFloor() {
    final building = _selectedBuilding;
    if (building == null || !building.hasFloors) return null;
    return building.floorIds;
  }

  List<FloorModel> _selectedBuildingFloors() {
    final building = _selectedBuilding;
    if (building == null) return [];
    return MockCampusData.campus.getFloorsForBuilding(building.id);
  }

  FloorModel? get _selectedFloor {
    final floorId = _selectedFloorId;
    if (floorId == null) return null;
    return MockCampusData.campus.getFloor(floorId);
  }

  List<ZoneModel> _selectedFloorZones() {
    final floor = _selectedFloor;
    if (floor == null) return [];
    return MockCampusData.campus.getZonesForFloor(floor.id);
  }

  ZoneModel? get _selectedZone {
    final zoneId = _selectedZoneId;
    if (zoneId == null) return null;
    return MockCampusData.campus.getZone(zoneId);
  }

  List<NodeModel> _selectedZoneNodes() {
    final zone = _selectedZone;
    if (zone == null) return [];
    return zone.nodeIds
        .map((id) => MockCampusData.getNodeById(id))
        .whereType<NodeModel>()
        .toList();
  }

  NodeModel? get _selectedNode {
    final nodeId = _selectedNodeId;
    if (nodeId == null) return null;
    return MockCampusData.getNodeById(nodeId);
  }

  // ═══════════════════════════════════════════
  // HELPERS DEL FORMULARIO
  // ═══════════════════════════════════════════

  List<FloorModel> get _sortedFloors {
    final floors = List<FloorModel>.from(MockCampusData.campus.floors);
    floors.sort((a, b) => a.level.compareTo(b.level));
    return floors;
  }

  FloorModel? get _formZoneFloor {
    if (_formFloorLevel == null) return null;
    return _sortedFloors.cast<FloorModel?>().firstWhere(
          (f) => f!.level == _formFloorLevel,
          orElse: () => null,
        );
  }

  NodeZone get _formType => _formNodeZone ?? NodeZone.pasillo;

  String _zoneLabel(NodeZone zone) => NodeTypeSettings.labelFor(zone);

  List<String> get _availableConnections {
    final nodeId = _editingNode?.id;
    return MockCampusData.allNodes
        .where((n) => n.id != nodeId)
        .where((n) => !_formConnections.contains(n.id))
        .map((n) => n.id)
        .toList();
  }

  String _connectionLabel(String id) {
    final node = MockCampusData.getNodeById(id);
    return node != null ? '${node.name} ($id)' : id;
  }

  void _addConnection() {
    final id = _connectionToAdd;
    if (id == null) {
      AppNotifications.showWarning(
        context,
        title: 'Falta seleccionar',
        description: 'Elige un nodo para agregar como conexión.',
      );
      return;
    }
    setState(() {
      if (!_formConnections.contains(id)) _formConnections.add(id);
      _connectionToAdd = null;
    });
  }

  String? get _photoNodeId {
    final editingId = _editingNode?.id;
    if (editingId != null && editingId.isNotEmpty) return editingId;
    final typed = _nodeIdController.text.trim();
    return typed.isEmpty ? null : typed;
  }

  Future<void> _pickPhoto() async {
    try {
      final bytes = await pickImageBytes();
      if (bytes == null) return;
      setState(() => _pickedImageBytes = bytes);
    } on UnsupportedError {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'No disponible',
        description: 'La selección de archivos solo funciona dentro del navegador.',
      );
    }
  }

  Future<void> _persistPhotoIfNeeded() async {
    final nodeId = _photoNodeId;
    if (nodeId == null) return;
    if (_pickedImageBytes != null) {
      await LocalImageStorage.saveImage(nodeId: nodeId, bytes: _pickedImageBytes!);
    }
  }

  Future<void> _checkImageForEditingNode() async {
    final nodeId = _photoNodeId;
    if (nodeId == null) return;
    final has = await LocalImageStorage.hasImage(nodeId);
    if (mounted) {
      setState(() => _hasExistingImage = has);
    }
  }

  Future<void> _startEditingNode(NodeModel node) async {
    setState(() {
      _editingNode = node;
      _nodeIdController.text = node.id;
      _nodeNameController.text = node.name;
      _descriptionController.text = node.description;
      _headingController.text = node.heading.toString();
      _destLabelController.text = node.destinationLabel ?? '';
      _formFloorLevel =
          _sortedFloors.where((f) => f.id == node.floorLevel).firstOrNull?.level ??
              int.tryParse(node.floorLevel ?? '');
      _formZoneId = node.zoneId;
      _formNodeZone = node.zone;
      _formConnections
        ..clear()
        ..addAll(node.connectedNodeIds);
      _pickedImageBytes = null;
      _hasExistingImage = false;
      _busy = false;
    });
    _tabController.index = 1;
    await _checkImageForEditingNode();
  }

  Future<void> _saveNode() async {
    if (!_formKey.currentState!.validate()) {
      AppNotifications.showError(
        context,
        title: 'Revisa el formulario',
        description: 'Hay campos inválidos. Corrígelos antes de guardar.',
      );
      return;
    }
    if (_formConnections.length < 2) {
      AppNotifications.showWarning(
        context,
        title: 'Faltan conexiones',
        description: 'Se requieren al menos 2 conexiones para el nodo.',
      );
      return;
    }

    final id = _nodeIdController.text.trim();
    final isEditingSelf = _editingNode?.id == id;
    final existing = MockCampusData.getNodeById(id);
    if (existing != null && !isEditingSelf) {
      AppNotifications.showError(
        context,
        title: 'ID duplicado',
        description: 'El ID "$id" ya existe en el campus.',
      );
      return;
    }

    final floor = _formZoneFloor;
    final floorId = floor?.id ?? _editingNode?.floorLevel;

    final node = NodeModel(
      id: id,
      name: _nodeNameController.text.trim(),
      description: _descriptionController.text.trim(),
      latitude: _editingNode?.latitude ?? 0,
      longitude: _editingNode?.longitude ?? 0,
      heading: _headingController.text.trim().isEmpty
          ? 0
          : double.parse(_headingController.text.trim()),
      floorLevel: floorId ?? _editingNode?.floorLevel,
      buildingId: floor?.buildingId ?? _editingNode?.buildingId,
      panoramaId: id,
      connectedNodeIds: List.unmodifiable(_formConnections),
      zone: _formType,
      zoneId: _formZoneId,
      destinationLabel: _destLabelController.text.trim().isEmpty
          ? null
          : _destLabelController.text.trim(),
    );

    setState(() => _busy = true);
    try {
      if (_editingNode != null) {
        MockCampusData.updateNode(id, node);
        await _persistPhotoIfNeeded();
        if (!mounted) return;
        AppNotifications.showSuccess(
          context,
          title: 'Nodo actualizado',
          description: '${node.name} (${node.id}) se guardó correctamente.',
        );
      } else if (mounted) {
        MockCampusData.addNode(node);
        final photoBytes = _pickedImageBytes;
        if (photoBytes != null && photoBytes.isNotEmpty) {
          await LocalImageStorage.saveImage(nodeId: id, bytes: photoBytes);
        }
        if (!mounted) return;
        AppNotifications.showSuccess(
          context,
          title: 'Nodo agregado',
          description: '${node.name} (${node.id}) se agregó al campus.',
        );
      }
      await MockCampusData.saveToFile();
      setState(() {
        _editingNode = null;
        _selectedNodeId = id;
        _resetForm();
      });
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al guardar',
        description: 'No se pudo guardar el nodo: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetForm() {
    _nodeIdController.clear();
    _nodeNameController.clear();
    _descriptionController.clear();
    _headingController.clear();
    _destLabelController.clear();
    _formFloorLevel = null;
    _formZoneId = null;
    _formNodeZone = null;
    _formConnections.clear();
    _connectionToAdd = null;
    _pickedImageBytes = null;
    _hasExistingImage = false;
  }

  Future<void> _confirmDeleteNode(NodeModel node) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nodo'),
        content: Text(
          '¿Eliminar "${node.name}" (${node.id})? Las conexiones que otros nodos '
          'tenían hacia este nodo se quitarán también.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (result != true) return;
    MockCampusData.removeNode(node.id);
    await LocalImageStorage.deleteImage(node.id);
    await MockCampusData.saveToFile();
    if (mounted) {
      setState(() => _selectedNodeId = null);
      AppNotifications.showSuccess(
        context,
        title: 'Nodo eliminado',
        description: '${node.name} se eliminó del campus.',
      );
    }
  }

  // ═══════════════════════════════════════════
  // CONFIG: EXPORT / IMPORT / RESET / PUSH
  // ═══════════════════════════════════════════

  Future<String> _backendUrl() async {
    var url = _backendUrlController.text.trim();
    if (url.isEmpty) {
      url = await AppSettings.backendBaseUrl();
      _backendUrlController.text = url;
    }
    await AppSettings.setBackendBaseUrl(url);
    return url;
  }

  Future<void> _checkBackend() async {
    final url = await _backendUrl();
    if (!mounted) return;
    if (url.isEmpty) {
      AppNotifications.showWarning(
        context,
        title: 'Falta la URL',
        description: 'Ingresa la URL del backend (ej: http://127.0.0.1:8082).',
      );
      return;
    }
    try {
      final version = await fetchBundleVersion(url);
      if (!mounted) return;
      if (version == null) {
        AppNotifications.showError(
          context,
          title: 'Sin respuesta',
          description: 'No se pudo conectar con el backend en $url.',
        );
        return;
      }
      AppNotifications.showSuccess(
        context,
        title: 'Backend conectado',
        description:
            'Versión ${version['version']} · ${version['summary']}',
      );
    } on UnsupportedError {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'No disponible',
        description: 'La publicación solo funciona dentro del navegador.',
      );
    }
  }

  Future<void> _publishToBackend() async {
    final url = await _backendUrl();
    if (!mounted) return;
    if (url.isEmpty) {
      AppNotifications.showWarning(
        context,
        title: 'Falta la URL',
        description: 'Ingresa la URL del backend (ej: http://127.0.0.1:8082).',
      );
      return;
    }

    final bundle = CampusBundleExport.buildBundle();
    setState(() => _publishing = true);
    try {
      final okBundle = await publishBundle(url, bundle);
      if (!okBundle) {
        if (!mounted) return;
        AppNotifications.showError(
          context,
          title: 'No se pudo publicar',
          description: 'El backend no aceptó el bundle en $url.',
        );
        return;
      }

      final imageIds = await LocalImageStorage.getAllNodeIdsWithImages();
      var uploaded = 0;
      for (final nodeId in imageIds) {
        final bytes = await LocalImageStorage.getImageBytes(nodeId);
        if (bytes == null) continue;
        final okImage = await publishImage(url, nodeId, bytes);
        if (okImage) uploaded++;
      }

      if (!mounted) return;
      final summary = CampusBundleExport.describeBundle(bundle);
      AppNotifications.showSuccess(
        context,
        title: 'Publicado',
        description:
            '$summary · $uploaded/${imageIds.length} imágenes enviadas.',
      );
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

  void _exportBundle() {
    try {
      final bundle = CampusBundleExport.buildBundle();
      downloadFile('campus_bundle.json', bundle);
      final summary = CampusBundleExport.describeBundle(bundle);
      AppNotifications.showSuccess(
        context,
        title: 'Bundle exportado',
        description: summary,
      );
    } catch (e) {
      AppNotifications.showError(
        context,
        title: 'Error al exportar',
        description: 'No se pudo generar el bundle: $e',
      );
    }
  }

  void _previewBundle() {
    try {
      final bundle = CampusBundleExport.buildBundle();
      final summary = CampusBundleExport.describeBundle(bundle);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vista previa del bundle'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppNotifications.showError(
        context,
        title: 'Error',
        description: 'No se pudo generar la vista previa: $e',
      );
    }
  }

  Future<void> _importBundle() async {
    try {
      final jsonText = await pickJsonText();
      if (jsonText == null) return;
      final summary = CampusBundleExport.describeBundle(jsonText);
      final ok = CampusBundleExport.importFromBundle(jsonText);
      if (!ok) {
        if (!mounted) return;
        AppNotifications.showError(
          context,
          title: 'Bundle inválido',
          description: 'El archivo seleccionado no es un bundle válido.',
        );
        return;
      }
      setState(() {});
      if (!mounted) return;
      AppNotifications.showSuccess(
        context,
        title: 'Bundle importado',
        description: summary,
      );
    } on UnsupportedError {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'No disponible',
        description: 'La importación solo funciona dentro del navegador.',
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al importar',
        description: 'No se pudo importar el bundle: $e',
      );
    }
  }

  Future<void> _confirmReset() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer datos'),
        content: const Text(
          'Se restablecerán el campus, overlays y direcciones a los datos de '
          'demo. Los cambios locales se perderán. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (result != true) return;
    await MockCampusData.resetToDefault();

    if (mounted) {
      setState(() {
        _selectedBuildingId = null;
        _selectedFloorId = null;
        _selectedZoneId = null;
        _selectedNodeId = null;
      });
      AppNotifications.showSuccess(
        context,
        title: 'Datos restablecidos',
        description: 'El campus volvió a los datos de demo.',
      );
    }
  }

  // ═══════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════

  Widget _buildEmptyHint({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  bool _isDestination(NodeModel node) => node.zone == NodeZone.destino;

  static IconData _iconForZone(NodeZone zone) {
    switch (zone) {
      case NodeZone.inicio:
        return Icons.play_arrow;
      case NodeZone.pasillo:
        return Icons.route;
      case NodeZone.destino:
        return Icons.flag;
    }
  }

  static IconData _iconForZoneType(ZoneType type) {
    switch (type) {
      case ZoneType.vesticulo:
        return Icons.door_front_door;
      case ZoneType.pasillo:
        return Icons.route;
      case ZoneType.aula:
        return Icons.meeting_room;
      case ZoneType.laboratorio:
        return Icons.science;
      case ZoneType.biblioteca:
        return Icons.local_library;
      case ZoneType.deporte:
        return Icons.sports;
      case ZoneType.servicio:
        return Icons.support_agent;
      case ZoneType.destino:
        return Icons.flag;
      case ZoneType.transicion:
        return Icons.stairs;
    }
  }
}