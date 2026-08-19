import 'package:flutter/material.dart';
import 'package:campus_domain/models/building_model.dart';
import 'package:campus_domain/models/floor_model.dart';
import 'package:campus_domain/models/node_model.dart';
import 'package:campus_domain/models/zone_model.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/utils/app_notifications.dart';
import 'package:admin_web/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:admin_web/features/navigation/data/datasources/node_type_settings.dart';

/// Gestión de catálogo: CRUD de pisos y zonas + editor de tipos de nodo.
/// Notifica vía [onChanged] para que el padre refresque sus vistas.
class CatalogTab extends StatefulWidget {
  final VoidCallback onChanged;

  const CatalogTab({super.key, required this.onChanged});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  final _buildingKey = GlobalKey<FormState>();
  final _floorKey = GlobalKey<FormState>();
  final _zoneKey = GlobalKey<FormState>();

  TextEditingController? _buildingIdController;
  TextEditingController? _buildingNameController;
  TextEditingController? _buildingDescController;
  TextEditingController? _buildingLatController;
  TextEditingController? _buildingLonController;
  TextEditingController? _floorIdController;
  TextEditingController? _floorNameController;
  TextEditingController? _floorLevelController;
  TextEditingController? _floorStairController;
  TextEditingController? _zoneIdController;
  TextEditingController? _zoneNameController;
  TextEditingController? _zoneDescController;
  TextEditingController? _zoneOrderController;

  final Map<String, TextEditingController> _nodeTypeLabelControllers = {};
  final Map<String, TextEditingController> _nodeTypeDescControllers = {};

  FloorModel? _editingFloor;
  ZoneModel? _editingZone;
  BuildingModel? _editingBuilding;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initNodeTypeControllers();
  }

  @override
  void dispose() {
    _buildingIdController?.dispose();
    _buildingNameController?.dispose();
    _buildingDescController?.dispose();
    _buildingLatController?.dispose();
    _buildingLonController?.dispose();
    _floorIdController?.dispose();
    _floorNameController?.dispose();
    _floorLevelController?.dispose();
    _floorStairController?.dispose();
    _zoneIdController?.dispose();
    _zoneNameController?.dispose();
    _zoneDescController?.dispose();
    _zoneOrderController?.dispose();
    for (final c in _nodeTypeLabelControllers.values) {
      c.dispose();
    }
    for (final c in _nodeTypeDescControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initNodeTypeControllers() {
    for (final zone in NodeZone.values) {
      _nodeTypeLabelControllers[zone.name] = TextEditingController(
        text: NodeTypeSettings.labelFor(zone),
      );
      _nodeTypeDescControllers[zone.name] = TextEditingController(
        text: NodeTypeSettings.descriptionFor(zone),
      );
    }
  }

  // ═══════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          title: 'Edificios',
          icon: Icons.apartment,
          trailing: TextButton.icon(
            onPressed: _busy ? null : () => _openBuildingForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar edificio'),
          ),
        ),
        _buildBuildingsBody(),
        const SizedBox(height: 24),
        _buildSectionHeader(
          title: 'Pisos',
          icon: Icons.layers,
          trailing: TextButton.icon(
            onPressed: _busy ? null : () => _openFloorForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar piso'),
          ),
        ),
        _buildFloorsBody(),
        const SizedBox(height: 24),
        _buildSectionHeader(
          title: 'Zonas',
          icon: Icons.folder_open,
          trailing: TextButton.icon(
            onPressed: _busy ? null : () => _openZoneForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar zona'),
          ),
        ),
        _buildZonesBody(),
        const SizedBox(height: 24),
        _buildSectionHeader(
          title: 'Tipos de nodo',
          icon: Icons.sell,
          trailing: TextButton.icon(
            onPressed: _busy ? null : _saveNodeTypes,
            icon: const Icon(Icons.save),
            label: const Text('Guardar tipos'),
          ),
        ),
        _buildNodeTypesEditor(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: AppTheme.headingMedium),
          ),
          ?trailing,
        ],
      ),
    );
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

  // ═══════════════════════════════════════════
  // EDIFICIOS
  // ═══════════════════════════════════════════

  Widget _buildBuildingsBody() {
    final campus = MockCampusData.campus;
    if (campus.buildings.isEmpty) {
      return _emptyHint('No hay edificios. Usa "Agregar edificio".');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final building in campus.buildings)
          _buildingCard(building),
      ],
    );
  }

  Widget _buildingCard(BuildingModel building) {
    final floors = MockCampusData.campus
        .getFloorsForBuilding(building.id)
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: const Icon(Icons.apartment, size: 18),
        ),
        title: Text(building.name),
        subtitle: Text(
          '${building.id} · ${floors.length} piso(s) · '
          '${building.latitude.toStringAsFixed(4)}, '
          '${building.longitude.toStringAsFixed(4)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: _busy ? null : () => _openBuildingForm(context, building: building),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: _busy ? null : () => _confirmDeleteBuilding(context, building),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBuildingForm(BuildContext context, {BuildingModel? building}) async {
    _editingBuilding = building;
    _buildingIdController = TextEditingController(text: building?.id ?? '');
    _buildingNameController = TextEditingController(text: building?.name ?? '');
    _buildingDescController = TextEditingController(text: building?.description ?? '');
    _buildingLatController =
        TextEditingController(text: building?.latitude.toString() ?? '-16.5005');
    _buildingLonController =
        TextEditingController(text: building?.longitude.toString() ?? '-68.1505');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(building == null ? 'Agregar edificio' : 'Editar edificio'),
            content: Form(
              key: _buildingKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _buildingIdController,
                      enabled: building == null,
                      decoration: const InputDecoration(
                        labelText: 'ID del edificio *',
                        hintText: 'Ej: edificio_B',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Se requiere un ID.';
                        final exists = MockCampusData.campus.buildings
                            .any((b) => b.id == value);
                        return exists && building?.id != value
                            ? 'El ID "$value" ya existe.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _buildingNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Se requiere el nombre.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _buildingDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _buildingLatController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitud *',
                              prefixIcon: Icon(Icons.pin_drop),
                            ),
                            validator: (v) {
                              final d = double.tryParse(v?.trim() ?? '');
                              if (d == null) return 'Número inválido.';
                              return (d < -90 || d > 90)
                                  ? 'Rango -90..90.'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _buildingLonController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitud *',
                              prefixIcon: Icon(Icons.pin_drop),
                            ),
                            validator: (v) {
                              final d = double.tryParse(v?.trim() ?? '');
                              if (d == null) return 'Número inválido.';
                              return (d < -180 || d > 180)
                                  ? 'Rango -180..180.'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveBuilding(context, dialogContext: dialogContext),
                icon: const Icon(Icons.save),
                label: Text(building == null ? 'Crear' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveBuilding(
    BuildContext context, {
    required BuildContext dialogContext,
  }) async {
    if (!_buildingKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final building = BuildingModel(
        id: _buildingIdController!.text.trim(),
        name: _buildingNameController!.text.trim(),
        description: _buildingDescController!.text.trim(),
        latitude: double.parse(_buildingLatController!.text.trim()),
        longitude: double.parse(_buildingLonController!.text.trim()),
        floorIds: _editingBuilding?.floorIds ?? const [],
      );
      if (_editingBuilding != null) {
        MockCampusData.updateBuilding(building);
      } else {
        MockCampusData.addBuilding(building);
      }
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      AppNotifications.showSuccess(
        context,
        title: _editingBuilding == null ? 'Edificio creado' : 'Edificio actualizado',
        description: '${building.name} se guardó correctamente.',
      );
      widget.onChanged();
      _editingBuilding = null;
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al guardar',
        description: 'No se pudo guardar el edificio: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteBuilding(BuildContext context, BuildingModel building) async {
    final floors = MockCampusData.campus
        .getFloorsForBuilding(building.id)
        .toList();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar edificio'),
        content: Text(
          floors.isNotEmpty
              ? '¿Eliminar "${building.name}"? También se eliminarán sus '
                  '${floors.length} piso(s), zonas y nodos asociados.'
              : '¿Eliminar el edificio "${building.name}"?',
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
    MockCampusData.removeBuilding(building.id);
    if (!context.mounted) return;
    AppNotifications.showSuccess(
      context,
      title: 'Edificio eliminado',
      description: '${building.name} se eliminó del campus.',
    );
    widget.onChanged();
  }

  // ═══════════════════════════════════════════
  // PISOS
  // ═══════════════════════════════════════════

  Widget _buildFloorsBody() {
    final campus = MockCampusData.campus;
    if (campus.buildings.isEmpty) {
      return _emptyHint('No hay edificios en el campus.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final building in campus.buildings) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              building.name,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _buildingFloorsCard(building),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildingFloorsCard(BuildingModel building) {
    final floors = MockCampusData.campus
        .getFloorsForBuilding(building.id)
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));

    if (floors.isEmpty) {
      return _emptyHint('Este edificio no tiene pisos. Usa "Agregar piso".');
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final floor in floors)
            _tile(
              title: '${floor.name} (nivel ${floor.level})',
              subtitle: '${floor.id} · ${floor.zoneIds.length} zonas',
              icon: Icons.layers_outlined,
              color: AppTheme.primaryColor,
              onEdit: () => _openFloorForm(context, floor: floor),
              onDelete: () => _confirmDeleteFloor(context, floor),
            ),
        ],
      ),
    );
  }

  Future<void> _openFloorForm(BuildContext context, {FloorModel? floor}) async {
    _editingFloor = floor;
    _floorIdController = TextEditingController(text: floor?.id ?? '');
    _floorNameController = TextEditingController(text: floor?.name ?? '');
    _floorLevelController =
        TextEditingController(text: floor?.level.toString() ?? '');
    _floorStairController =
        TextEditingController(text: floor?.stairNodeId ?? '');

    String? buildingId = floor?.buildingId ??
        (MockCampusData.campus.buildings.isNotEmpty
            ? MockCampusData.campus.buildings.first.id
            : null);

    if (buildingId == null) {
      AppNotifications.showWarning(
        context,
        title: 'Sin edificios',
        description: 'Primero debe existir un edificio para asignar el piso.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(floor == null ? 'Agregar piso' : 'Editar piso'),
            content: Form(
              key: _floorKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _floorIdController,
                      enabled: floor == null,
                      decoration: const InputDecoration(
                        labelText: 'ID del piso *',
                        hintText: 'Ej: piso_3',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Se requiere un ID.';
                        final exists = MockCampusData.campus.floors
                            .any((f) => f.id == value);
                        return exists && floor?.id != value
                            ? 'El ID "$value" ya existe.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _floorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Se requiere el nombre.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _floorLevelController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nivel *',
                        prefixIcon: Icon(Icons.stairs),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Se requiere el nivel.';
                        }
                        return int.tryParse(v.trim()) == null
                            ? 'Ingresa un número entero.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('building_${floor?.id ?? 'new'}'),
                      initialValue: buildingId,
                      decoration: const InputDecoration(
                        labelText: 'Edificio *',
                        prefixIcon: Icon(Icons.apartment),
                      ),
                      items: MockCampusData.campus.buildings
                          .map((b) => DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(b.name),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => buildingId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _floorStairController,
                      decoration: const InputDecoration(
                        labelText: 'Nodo de escalera (opcional)',
                        hintText: 'Ej: P05',
                        prefixIcon: Icon(Icons.arrow_upward),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _saveFloor(context, buildingId: buildingId, dialogContext: dialogContext),
                icon: const Icon(Icons.save),
                label: Text(floor == null ? 'Crear' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveFloor(
    BuildContext context, {
    required String? buildingId,
    required BuildContext dialogContext,
  }) async {
    if (!_floorKey.currentState!.validate()) return;
    if (buildingId == null) return;

    setState(() => _busy = true);
    try {
      final floor = FloorModel(
        id: _floorIdController!.text.trim(),
        name: _floorNameController!.text.trim(),
        level: int.parse(_floorLevelController!.text.trim()),
        buildingId: buildingId,
        zoneIds: _editingFloor?.zoneIds ?? const [],
        stairNodeId: _floorStairController!.text.trim().isEmpty
            ? null
            : _floorStairController!.text.trim(),
      );
      if (_editingFloor != null) {
        MockCampusData.updateFloor(floor);
      } else {
        MockCampusData.addFloor(floor);
      }
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      AppNotifications.showSuccess(
        context,
        title: _editingFloor == null ? 'Piso creado' : 'Piso actualizado',
        description: '${floor.name} se guardó correctamente.',
      );
      widget.onChanged();
      _editingFloor = null;
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al guardar',
        description: 'No se pudo guardar el piso: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteFloor(BuildContext context, FloorModel floor) async {
    final nodesCount = floor.zoneIds
        .map((id) => MockCampusData.campus.getZone(id))
        .whereType<ZoneModel>()
        .fold<int>(0, (sum, z) => sum + z.nodeIds.length);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar piso'),
        content: Text(
          floor.zoneIds.isNotEmpty
              ? '¿Eliminar "${floor.name}"? Se eliminarán también sus '
                  '${floor.zoneIds.length} zona(s) y $nodesCount nodo(s).'
              : '¿Eliminar el piso "${floor.name}"?',
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
    MockCampusData.removeFloor(floor.id);
    if (!context.mounted) return;
    AppNotifications.showSuccess(
      context,
      title: 'Piso eliminado',
      description: '${floor.name} se eliminó del campus.',
    );
    widget.onChanged();
  }

  // ═══════════════════════════════════════════
  // ZONAS
  // ═══════════════════════════════════════════

  Widget _buildZonesBody() {
    final floors = List<FloorModel>.from(MockCampusData.campus.floors)
      ..sort((a, b) => a.level.compareTo(b.level));
    if (floors.isEmpty) {
      return _emptyHint('No hay pisos. Crea un piso primero.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final floor in floors) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              '${floor.name} (${floor.id})',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _floorZonesCard(floor),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _floorZonesCard(FloorModel floor) {
    final zones = floor.zoneIds
        .map((id) => MockCampusData.campus.getZone(id))
        .whereType<ZoneModel>()
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (zones.isEmpty) {
      return _emptyHint('Este piso no tiene zonas. Usa "Agregar zona".');
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final zone in zones)
            _tile(
              title: zone.name,
              subtitle:
                  '${zone.id} · ${zone.type.name} · ${zone.nodeIds.length} nodos',
              icon: Icons.folder_open_outlined,
              color: AppTheme.secondaryColor,
              onEdit: () => _openZoneForm(context, zone: zone),
              onDelete: () => _confirmDeleteZone(context, zone),
            ),
        ],
      ),
    );
  }

  Future<void> _openZoneForm(BuildContext context, {ZoneModel? zone}) async {
    _editingZone = zone;
    _zoneIdController = TextEditingController(text: zone?.id ?? '');
    _zoneNameController = TextEditingController(text: zone?.name ?? '');
    _zoneDescController = TextEditingController(text: zone?.description ?? '');
    _zoneOrderController = TextEditingController(text: '${zone?.order ?? 0}');

    final zoneIds = MockCampusData.campus.zones
        .map((z) => z.id)
        .where((id) => id != zone?.id)
        .toList();
    final connectedSet = <String>{...?zone?.connectedZoneIds};

    String? floorId = zone?.floorId ??
        (MockCampusData.campus.floors.isNotEmpty
            ? MockCampusData.campus.floors.first.id
            : null);
    ZoneType type = zone?.type ?? ZoneType.pasillo;

    if (floorId == null) {
      AppNotifications.showWarning(
        context,
        title: 'Sin pisos',
        description: 'Primero debe existir un piso para asignar la zona.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(zone == null ? 'Agregar zona' : 'Editar zona'),
            content: Form(
              key: _zoneKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _zoneIdController,
                      enabled: zone == null,
                      decoration: const InputDecoration(
                        labelText: 'ID de la zona *',
                        hintText: 'Ej: z_aulas_p3',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Se requiere un ID.';
                        final exists = MockCampusData.campus.zones
                            .any((z) => z.id == value);
                        return exists && zone?.id != value
                            ? 'El ID "$value" ya existe.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zoneNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Se requiere el nombre.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zoneDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('sfloor_${zone?.id ?? 'new'}'),
                      initialValue: floorId,
                      decoration: const InputDecoration(
                        labelText: 'Piso *',
                        prefixIcon: Icon(Icons.layers),
                      ),
                      items: MockCampusData.campus.floors
                          .map((f) => DropdownMenuItem<String>(
                                value: f.id,
                                child: Text('${f.name} (${f.id})'),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => floorId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ZoneType>(
                      key: ValueKey('stype_${zone?.id ?? 'new'}'),
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ZoneType.values
                          .map((t) => DropdownMenuItem<ZoneType>(
                                value: t,
                                child: Text(t.name),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() {
                        if (v != null) type = v;
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zoneOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Orden',
                        prefixIcon: Icon(Icons.sort),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Zonas conectadas',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: zoneIds.map((id) {
                        final z = MockCampusData.campus.getZone(id);
                        final selected = connectedSet.contains(id);
                        return FilterChip(
                          label: Text(
                            z?.name ?? id,
                            style: AppTheme.bodySmall,
                          ),
                          selected: selected,
                          onSelected: (v) => setDialogState(() {
                            if (v) {
                              connectedSet.add(id);
                            } else {
                              connectedSet.remove(id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveZone(
                  context,
                  floorId: floorId,
                  type: type,
                  connectedZoneIds: connectedSet.toList(),
                  dialogContext: dialogContext,
                ),
                icon: const Icon(Icons.save),
                label: Text(zone == null ? 'Crear' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveZone(
    BuildContext context, {
    required String? floorId,
    required ZoneType type,
    required List<String> connectedZoneIds,
    required BuildContext dialogContext,
  }) async {
    if (!_zoneKey.currentState!.validate()) return;
    if (floorId == null) return;

    final floor = MockCampusData.campus.getFloor(floorId);
    if (floor == null) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Piso inválido',
        description: 'El piso seleccionado ya no existe.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final zone = ZoneModel(
        id: _zoneIdController!.text.trim(),
        name: _zoneNameController!.text.trim(),
        description: _zoneDescController!.text.trim(),
        floorId: floorId,
        buildingId: floor.buildingId,
        type: type,
        connectedZoneIds: List.unmodifiable(connectedZoneIds),
        nodeIds: _editingZone?.nodeIds ?? const [],
        entryNodeId: _editingZone?.entryNodeId,
        exitNodeId: _editingZone?.exitNodeId,
        order: int.tryParse(_zoneOrderController!.text.trim()) ?? 0,
      );
      if (_editingZone != null) {
        MockCampusData.updateZone(zone);
      } else {
        MockCampusData.addZone(zone);
      }
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      AppNotifications.showSuccess(
        context,
        title: _editingZone == null ? 'Zona creada' : 'Zona actualizada',
        description: '${zone.name} se guardó correctamente.',
      );
      widget.onChanged();
      _editingZone = null;
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al guardar',
        description: 'No se pudo guardar la zona: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteZone(BuildContext context, ZoneModel zone) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar zona'),
        content: Text(
          zone.nodeIds.isNotEmpty
              ? '¿Eliminar "${zone.name}"? También se eliminarán sus '
                  '${zone.nodeIds.length} nodo(s).'
              : '¿Eliminar la zona "${zone.name}"?',
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
    MockCampusData.removeZone(zone.id);
    if (!context.mounted) return;
    AppNotifications.showSuccess(
      context,
      title: 'Zona eliminada',
      description: '${zone.name} se eliminó del campus.',
    );
    widget.onChanged();
  }

  // ═══════════════════════════════════════════
  // TIPOS DE NODO
  // ═══════════════════════════════════════════

  Widget _buildNodeTypesEditor() {
    final zones = NodeZone.values;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Renombra y describe los 3 tipos de nodo. El valor técnico '
              '(inicio/pasillo/destino) no cambia en el bundle.',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final zone in zones) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nodeTypeLabelControllers[zone.name],
                      decoration: InputDecoration(
                        labelText: 'Tipo: ${_nodeTypeTechnicalLabel(zone)}',
                        prefixIcon: Icon(_iconForNodeZone(zone)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nodeTypeDescControllers[zone.name],
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ),
                ],
              ),
              if (zone != zones.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  String _nodeTypeTechnicalLabel(NodeZone zone) {
    switch (zone) {
      case NodeZone.inicio:
        return 'Inicio de recorrido (inicio)';
      case NodeZone.pasillo:
        return 'Pasillo / transición (pasillo)';
      case NodeZone.destino:
        return 'Destino (destino)';
    }
  }

  IconData _iconForNodeZone(NodeZone zone) {
    switch (zone) {
      case NodeZone.inicio:
        return Icons.play_arrow;
      case NodeZone.pasillo:
        return Icons.route;
      case NodeZone.destino:
        return Icons.flag;
    }
  }

  Future<void> _saveNodeTypes() async {
    setState(() => _busy = true);
    try {
      for (final zone in NodeZone.values) {
        NodeTypeSettings.update(
          zone: zone,
          label: _nodeTypeLabelControllers[zone.name]!.text.trim(),
          description: _nodeTypeDescControllers[zone.name]!.text.trim(),
        );
      }
      await NodeTypeSettings.save();
      if (!mounted) return;
      AppNotifications.showSuccess(
        context,
        title: 'Tipos de nodo guardados',
        description: 'Los nombres y descripciones se actualizaron.',
      );
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error al guardar',
        description: 'No se pudieron guardar los tipos: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ═══════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════

  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: _busy ? null : onEdit,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: _busy ? null : onDelete,
            ),
        ],
      ),
    );
  }
}