import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/zone_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/building_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/floor_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/core/utils/navigation_settings.dart';
import 'package:app_guia_ar/features/navigation/presentation/utils/route_readiness.dart';

/// Pantalla de planificación de recorrido (Fase 0).
///
/// Diseño unificado en un solo cuadro con colorimetría blanco/rojo:
///  - Modo resaltado (Ruta guiada / Ruta rápida) en tarjetas grandes.
///  - Punto de inicio por cascada: edificio → piso → zona → nodo.
///  - Inicio por defecto precargado desde el panel de administración.
///  - Destinos unificados: solo destinos posibles del campus, seccionados por
///    edificio → piso → zona; se tocan para fijarlos como destino.
class Fase0TestScreen extends StatefulWidget {
  const Fase0TestScreen({super.key});

  @override
  State<Fase0TestScreen> createState() => _Fase0TestScreenState();
}

// ═══════════════════════════════════════════════
// Colorimetría blanco/rojo
// ═══════════════════════════════════════════════

const Color _kRed = Color(0xFFE53935);
const Color _kRedDark = Color(0xFFB71C1C);
const Color _kRedMid = Color(0xFFC62828);
const Color _kRedLight = Color(0xFFFFEBEE);
const Color _kRedSoft = Color(0xFFFBE9E9);

class _Fase0TestScreenState extends State<Fase0TestScreen> {
  String? _selectedStartNodeId;
  String? _selectedEndNodeId;
  RouteMode _selectedMode = RouteMode.guidedWalk;

  String? _startBuildingId;
  String? _startFloorId;
  String? _startZoneId;

  String? _defaultStartNodeId;
  bool _loadingDefault = true;

  final _campus = MockCampusData.campus;

  @override
  void initState() {
    super.initState();
    _loadDefaultStart();
  }

  Future<void> _loadDefaultStart() async {
    final id = await NavigationSettings.loadDefaultStartNodeId();
    if (!mounted) return;
    setState(() {
      _loadingDefault = false;
      if (id != null && MockCampusData.getNodeById(id) != null) {
        _defaultStartNodeId = id;
        _applyStartNode(id);
      }
    });
  }

  void _applyStartNode(String nodeId) {
    final node = MockCampusData.getNodeById(nodeId);
    _selectedStartNodeId = nodeId;
    final zone = node?.zoneId != null ? _campus.getZone(node!.zoneId!) : null;
    _startZoneId = zone?.id;
    _startFloorId = zone?.floorId;
    _startBuildingId = zone?.buildingId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kRedSoft,
      appBar: AppBar(
        title: const Text('Planificar recorrido'),
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kRedLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kRedDark.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildModeSelector(),
              const SizedBox(height: 14),
              _buildCascadeDivider(),
              const SizedBox(height: 14),
              _buildStartCascade(),
              const SizedBox(height: 12),
              _buildDestinationSelector(),
              const SizedBox(height: 14),
              _buildSummaryAndStartButton(),
              const SizedBox(height: 14),
              _buildCascadeDivider(),
              const SizedBox(height: 14),
              _buildDestinationsMap(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _kRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.route, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nuevo recorrido',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kRedDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Elige el modo, tu punto de inicio y el destino. Solo verás los '
          'destinos posibles dentro del campus.',
          style: const TextStyle(fontSize: 13, color: _kRedMid, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildCascadeDivider() {
    return const Divider(color: _kRedLight, thickness: 1.5, height: 1);
  }

  // ═══════════════════════════════════════════════
  // MODO DE NAVEGACIÓN — tarjetas grandes resaltadas
  // ═══════════════════════════════════════════════

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.directions,
          'Modo de navegación',
          subtitle: _selectedMode == RouteMode.guidedWalk
              ? 'Caminando, paso a paso con el guía.'
              : 'Vista rápida automática.',
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildModeCard(
                  mode: RouteMode.guidedWalk,
                  icon: Icons.directions_walk,
                  title: 'Ruta guiada',
                  subtitle: 'Paso a paso',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  mode: RouteMode.quickPreview,
                  icon: Icons.play_circle_fill,
                  title: 'Ruta rápida',
                  subtitle: 'Automática',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required RouteMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _kRed : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kRedDark : _kRedLight,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kRedDark.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: isSelected ? Colors.white : _kRed,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : _kRedDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : _kRedMid,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 40 : 18,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : _kRedLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PUNTO DE INICIO — cascada edificio→piso→zona→nodo
  // ═══════════════════════════════════════════════

  Widget _buildStartCascade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                Icons.flag,
                'Punto de inicio',
                showSubtitle: false,
              ),
            ),
            if (_loadingDefault)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kRed),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCascadeDropdown(
          label: 'Edificio',
          value: _startBuildingId,
          items: _startBuildings,
          itemId: (b) => b.id,
          itemLabel: (b) => b.name,
          onSelected: (id) => _modifyStartCascade(buildingId: id),
          enabled: _startBuildings.isNotEmpty,
        ),
        const SizedBox(height: 10),
        _buildCascadeDropdown(
          label: 'Piso',
          value: _startFloorId,
          items: _startFloors,
          itemId: (f) => f.id,
          itemLabel: (f) => 'Piso ${f.level} · ${f.name}',
          onSelected: (id) => _modifyStartCascade(floorId: id),
          enabled: _startFloorId != null,
        ),
        const SizedBox(height: 10),
        _buildCascadeDropdown(
          label: 'Zona',
          value: _startZoneId,
          items: _startZones,
          itemId: (z) => z.id,
          itemLabel: (z) => z.name,
          onSelected: (id) => _modifyStartCascade(zoneId: id),
          enabled: _startZoneId != null,
        ),
        const SizedBox(height: 10),
        _buildCascadeDropdown(
          label: 'Nodo de inicio',
          value: _selectedStartNodeId,
          items: _startNodes,
          itemId: (n) => n.id,
          itemLabel: (n) => n.name,
          onSelected: (id) => _modifyStartCascade(nodeId: id),
          enabled: _startNodes.isNotEmpty,
          icon: Icons.flag,
        ),
        const SizedBox(height: 4),
        if (_defaultStartNodeId != null && _selectedStartNodeId != null)
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: _kRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Inicio por defecto del panel: '
                  '${MockCampusData.getNodeById(_selectedStartNodeId!)?.name ?? _selectedStartNodeId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kRedMid,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _modifyStartCascade({
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
        _selectedStartNodeId = null;
      } else if (floorId != _startFloorId) {
        _startFloorId = floorId;
        _startZoneId = null;
        _selectedStartNodeId = null;
      } else if (zoneId != _startZoneId) {
        _startZoneId = zoneId;
        _selectedStartNodeId = null;
      } else if (nodeId != _selectedStartNodeId) {
        _selectedStartNodeId = nodeId;
      }
    });
  }

  // ═══════════════════════════════════════════════
  // DESTINO — selectora de destinos posibles
  // ═══════════════════════════════════════════════

  Widget _buildDestinationSelector() {
    final destinations = _buildDestinationDropdownItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.location_on,
          'Destino',
          subtitle: 'Solo destinos posibles del campus.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedEndNodeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Selecciona el destino',
            prefixIcon: const Icon(Icons.location_on, color: _kRed),
            filled: true,
            fillColor: _kRedSoft,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kRedLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kRed, width: 2),
            ),
          ),
          items: destinations,
          onChanged: destinations.isEmpty
              ? null
              : (v) => setState(() => _selectedEndNodeId = v),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildDestinationDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    final destinations = MockCampusData.getDestinations();

    for (final building in _buildingsWithData) {
      for (final floor in _campus.getFloorsForBuilding(building.id)) {
        final zones = _campus.getZonesForFloor(floor.id);
        final zonesWithDestinations = zones
            .where((z) =>
                z.nodeIds.any((id) => MockCampusData.getNodeById(id)?.isDestination == true))
            .toList();
        if (zonesWithDestinations.isEmpty) continue;

        items.add(DropdownMenuItem<String>(
          enabled: false,
          value: '__b_${building.id}_f_${floor.id}',
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${building.name} · Piso ${floor.level}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _kRedDark,
                fontSize: 13,
              ),
            ),
          ),
        ));
        for (final zone in zonesWithDestinations) {
          for (final id in zone.nodeIds) {
            final node = MockCampusData.getNodeById(id);
            if (node == null || !node.isDestination) continue;
            if (node.id == _selectedStartNodeId) continue;
            items.add(DropdownMenuItem<String>(
              value: node.id,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    const Icon(Icons.school, size: 14, color: _kRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        node.destinationLabel ?? node.name,
                        style: const TextStyle(fontSize: 13, color: _kRedDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      zone.name,
                      style: const TextStyle(fontSize: 10, color: _kRedMid),
                    ),
                  ],
                ),
              ),
            ));
          }
        }
      }
    }

    if (destinations.isEmpty) {
      items.add(const DropdownMenuItem<String>(
        enabled: false,
        value: '__none',
        child: Text('No hay destinos disponibles en el campus'),
      ));
    }
    return items;
  }

  // ═══════════════════════════════════════════════
  // RESUMEN + BOTÓN DE INICIO
  // ═══════════════════════════════════════════════

  Widget _buildSummaryAndStartButton() {
    final startNode = _selectedStartNodeId != null
        ? MockCampusData.getNodeById(_selectedStartNodeId!)
        : null;
    final endNode = _selectedEndNodeId != null
        ? MockCampusData.getNodeById(_selectedEndNodeId!)
        : null;
    final canStart = startNode != null &&
        endNode != null &&
        startNode.id != endNode.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kRedSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRedLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 15, color: _kRed),
                        const SizedBox(width: 6),
                        Text(
                          startNode?.name ??
                              (startNode == null ? 'Inicio no seleccionado' : ''),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: startNode != null ? _kRedDark : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 15, color: _kRed),
                        const SizedBox(width: 6),
                        Text(
                          endNode?.destinationLabel ?? endNode?.name ??
                              'Destino no seleccionado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: endNode != null ? _kRedDark : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.route, color: _kRed, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: canStart ? _startNavigation : null,
          icon: Icon(
            _selectedMode == RouteMode.quickPreview
                ? Icons.play_arrow
                : Icons.directions_walk,
            size: 26,
          ),
          label: Text(
            _selectedMode == RouteMode.quickPreview
                ? 'Iniciar vista rápida'
                : 'Iniciar ruta guiada',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _kRedLight,
            disabledForegroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 6,
            shadowColor: _kRedDark.withValues(alpha: 0.5),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // DESTINOS UNIFICADOS — solo destinos posibles,
  // seccionados por edificio → piso → zona
  // ═══════════════════════════════════════════════

  Widget _buildDestinationsMap() {
    final destCount = MockCampusData.getDestinations().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                Icons.map,
                'Destinos del campus',
                subtitle: 'Toca un destino para elegirlo.',
                showSubtitle: false,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$destCount destinos',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_buildingsWithData.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No hay destinos posibles en el campus.',
              style: const TextStyle(fontSize: 13, color: _kRedMid),
            ),
          ),
        for (final building in _buildingsWithData)
          _buildBuildingSection(building),
      ],
    );
  }

  List<BuildingModel> get _buildingsWithData {
    if (_campus.buildings.isEmpty) return [];
    return List<BuildingModel>.from(_campus.buildings);
  }

  List<BuildingModel> get _startBuildings {
    return List<BuildingModel>.from(_campus.buildings);
  }

  List<FloorModel> get _startFloors {
    if (_startBuildingId == null) return [];
    return _campus.getFloorsForBuilding(_startBuildingId!);
  }

  List<ZoneModel> get _startZones {
    if (_startFloorId == null) return [];
    return _campus.getZonesForFloor(_startFloorId!);
  }

  List<NodeModel> get _startNodes {
    if (_startZoneId == null) return [];
    return _campus.getNodesForZone(_startZoneId!)
        .where((n) => n.id != _selectedEndNodeId)
        .toList();
  }

  Widget _buildBuildingSection(BuildingModel building) {
    final floors = _campus.getFloorsForBuilding(building.id);
    final visibleFloors =
        floors.where((f) => _floorHasDestinations(f)).toList();
    if (visibleFloors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment, size: 16, color: _kRedDark),
              const SizedBox(width: 6),
              Text(
                building.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _kRedDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final floor in visibleFloors) _buildFloorSection(floor),
        ],
      ),
    );
  }

  bool _floorHasDestinations(FloorModel floor) {
    return _campus.getZonesForFloor(floor.id).any((z) =>
        z.nodeIds.any((id) => MockCampusData.getNodeById(id)?.isDestination == true));
  }

  Widget _buildFloorSection(FloorModel floor) {
    final zones = _campus.getZonesForFloor(floor.id)
        .where((z) =>
            z.nodeIds.any((id) => MockCampusData.getNodeById(id)?.isDestination == true))
        .toList();
    if (zones.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Piso ${floor.level}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _kRedMid,
              ),
            ),
          ),
          for (final zone in zones) _buildZoneDestinations(zone),
        ],
      ),
    );
  }

  Widget _buildZoneDestinations(ZoneModel zone) {
    final nodes = zone.nodeIds
        .map((id) => MockCampusData.getNodeById(id))
        .where((n) => n != null && n.isDestination)
        .cast<NodeModel>()
        .toList();
    if (nodes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, size: 13, color: _kRed),
              const SizedBox(width: 4),
              Text(
                zone.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _kRedDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nodes.map((node) => _buildDestinationCard(node)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(NodeModel node) {
    final isSelected = node.id == _selectedEndNodeId;
    final isStart = node.id == _selectedStartNodeId;

    return GestureDetector(
      onTap: () {
        if (isStart) return;
        setState(() => _selectedEndNodeId = node.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kRed : _kRedSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kRedDark : _kRedLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kRedDark.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.school,
              size: 18,
              color: isSelected ? Colors.white : _kRed,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.destinationLabel ?? node.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _kRedDark,
                  ),
                ),
                if (node.id.isNotEmpty)
                  Text(
                    node.id,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : _kRedMid,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HELPERS DE UI
  // ═══════════════════════════════════════════════

  Widget _sectionTitle(
    IconData icon,
    String title, {
    String? subtitle,
    bool showSubtitle = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: _kRed),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kRedDark,
                ),
              ),
              if (showSubtitle && subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _kRedMid),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCascadeDropdown<T>({
    required String label,
    required String? value,
    required List<T> items,
    required String Function(T) itemId,
    required String Function(T) itemLabel,
    required void Function(String?) onSelected,
    required bool enabled,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon ?? Icons.place_outlined, color: _kRed, size: 20),
        filled: true,
        fillColor: _kRedSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kRedLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: itemId(item), child: Text(itemLabel(item))),
      ],
      onChanged: !enabled || items.isEmpty ? null : onSelected,
    );
  }

  // ═══════════════════════════════════════════════
  // ACCIÓN — iniciar recorrido
  // ═══════════════════════════════════════════════

  void _startNavigation() {
    if (_selectedStartNodeId == null || _selectedEndNodeId == null) return;

    RouteReadiness.startGuidedRoute(
      context,
      startNodeId: _selectedStartNodeId!,
      endNodeId: _selectedEndNodeId!,
      mode: _selectedMode,
    );
  }
}