import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/zone_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/floor_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/features/navigation/presentation/utils/route_readiness.dart';

class Fase0TestScreen extends StatefulWidget {
  const Fase0TestScreen({super.key});

  @override
  State<Fase0TestScreen> createState() => _Fase0TestScreenState();
}

class _Fase0TestScreenState extends State<Fase0TestScreen> {
  String? _selectedStartNodeId;
  String? _selectedEndNodeId;
  RouteMode _selectedMode = RouteMode.guidedWalk;

  final _campus = MockCampusData.campus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSelector(),
            const SizedBox(height: 16),
            _buildRouteSelector(),
            const SizedBox(height: 16),
            _buildStartButton(),
            const SizedBox(height: 16),
            _buildCampusMap(),
            const SizedBox(height: 16),
            _buildDestinationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modo de Navegación', style: AppTheme.headingMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    mode: RouteMode.guidedWalk,
                    icon: Icons.directions_walk,
                    title: 'Ruta Guiada',
                    subtitle: 'Caminando, transiciones manuales',
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    mode: RouteMode.quickPreview,
                    icon: Icons.play_circle,
                    title: 'Ruta Rápida',
                    subtitle: 'Slider automático cada 2s',
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required RouteMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ROUTE SELECTOR — zone-aware dropdowns
  // ═══════════════════════════════════════════════

  Widget _buildRouteSelector() {
    final allNodes = MockCampusData.getAllNodes();
    final floors = _campus.floors..sort((a, b) => a.level.compareTo(b.level));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seleccionar Ruta', style: AppTheme.headingMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStartNodeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Punto de inicio',
                prefixIcon: Icon(Icons.circle_outlined),
              ),
              items: _buildNodeDropdownItems(allNodes, floors, excludeNodeId: null),
              onChanged: (v) => setState(() => _selectedStartNodeId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedEndNodeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Destino',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _buildNodeDropdownItems(allNodes, floors, excludeNodeId: _selectedStartNodeId),
              onChanged: (v) => setState(() => _selectedEndNodeId = v),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildNodeDropdownItems(
    List<NodeModel> allNodes,
    List<FloorModel> floors, {
    String? excludeNodeId,
  }) {
    final items = <DropdownMenuItem<String>>[];

    for (final floor in floors) {
      final floorZones = _campus.zones
          .where((z) => z.floorId == floor.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      bool floorHeaderAdded = false;

      for (final zone in floorZones) {
        final zoneNodes = zone.nodeIds
            .map((id) => MockCampusData.getNodeById(id))
            .whereType<NodeModel>()
            .toList();

        if (zoneNodes.isEmpty) continue;

        if (!floorHeaderAdded) {
          items.add(DropdownMenuItem<String>(
            enabled: false,
            value: '__floor_${floor.id}',
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '── Piso ${floor.level} ──',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
          ));
          floorHeaderAdded = true;
        }

        for (final node in zoneNodes) {
          if (node.id == excludeNodeId) continue;
          final zoneIcon = _getZoneIcon(zone.type);

          items.add(DropdownMenuItem<String>(
            value: node.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Icon(zoneIcon, size: 14, color: _getZoneColor(zone.type)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${node.destinationLabel ?? node.name} · ${zone.name}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    node.id,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ));
        }
      }
    }

    return items;
  }

  // ═══════════════════════════════════════════════
  // START BUTTON
  // ═══════════════════════════════════════════════

  Widget _buildStartButton() {
    final canStart = _selectedStartNodeId != null &&
        _selectedEndNodeId != null &&
        _selectedStartNodeId != _selectedEndNodeId;

    return ElevatedButton.icon(
      onPressed: canStart ? _startNavigation : null,
      icon: Icon(_selectedMode == RouteMode.quickPreview
          ? Icons.play_arrow
          : Icons.directions_walk),
      label: Text(
        _selectedMode == RouteMode.quickPreview
            ? 'Iniciar Vista Rápida'
            : 'Iniciar Ruta Guiada',
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // CAMPUS MAP — zone-based grouped view
  // ═══════════════════════════════════════════════

  Widget _buildCampusMap() {
    final floors = _campus.floors..sort((a, b) => a.level.compareTo(b.level));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Mapa del Campus', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Toca un nodo para seleccionarlo como inicio/destino',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            ...floors.map((floor) => _buildFloorMapSection(floor)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorMapSection(FloorModel floor) {
    final zones = _campus.zones
        .where((z) => z.floorId == floor.id)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Piso ${floor.level} — ${floor.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...zones.map((zone) => _buildZoneMapSection(zone)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildZoneMapSection(ZoneModel zone) {
    final nodes = zone.nodeIds
        .map((id) => MockCampusData.getNodeById(id))
        .whereType<NodeModel>()
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getZoneIcon(zone.type), size: 14, color: _getZoneColor(zone.type)),
              const SizedBox(width: 4),
              Text(
                zone.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _getZoneColor(zone.type),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _getZoneColor(zone.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getZoneTypeName(zone.type),
                  style: TextStyle(fontSize: 9, color: _getZoneColor(zone.type)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: nodes.map((node) => _buildNodeChip(node, zone)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeChip(NodeModel node, ZoneModel zone) {
    final isStart = node.id == _selectedStartNodeId;
    final isEnd = node.id == _selectedEndNodeId;
    final isDestination = node.isDestination;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedStartNodeId == null) {
            _selectedStartNodeId = node.id;
          } else if (_selectedEndNodeId == null && node.id != _selectedStartNodeId) {
            _selectedEndNodeId = node.id;
          } else {
            _selectedStartNodeId = node.id;
            _selectedEndNodeId = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isStart
              ? AppTheme.primaryColor
              : isEnd
                  ? AppTheme.secondaryColor
                  : isDestination
                      ? AppTheme.errorColor.withValues(alpha: 0.1)
                      : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isStart || isEnd
                ? Colors.white
                : isDestination
                    ? AppTheme.errorColor
                    : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStart
                  ? Icons.play_arrow
                  : isEnd
                      ? Icons.flag
                      : isDestination
                          ? Icons.school
                          : Icons.location_on,
              color: isStart || isEnd
                  ? Colors.white
                  : isDestination
                      ? AppTheme.errorColor
                      : Colors.grey,
              size: 14,
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.id,
                  style: TextStyle(
                    color: isStart || isEnd ? Colors.white : Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  node.destinationLabel ?? node.name,
                  style: TextStyle(
                    color: isStart || isEnd ? Colors.white70 : Colors.grey[600],
                    fontSize: 9,
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
  // DESTINATIONS LIST — zone-grouped, all nodes
  // ═══════════════════════════════════════════════

  Widget _buildDestinationsList() {
    final floors = _campus.floors..sort((a, b) => a.level.compareTo(b.level));
    final allNodes = MockCampusData.getAllNodes();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: AppTheme.errorColor, size: 20),
                const SizedBox(width: 8),
                Text('Destinos Disponibles', style: AppTheme.headingMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allNodes.length} nodos',
                    style: TextStyle(fontSize: 11, color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona un nodo como destino',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            ...floors.map((floor) => _buildDestinationsFloorSection(floor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationsFloorSection(FloorModel floor) {
    final zones = _campus.zones
        .where((z) => z.floorId == floor.id)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final hasNodes = zones.any((z) => z.nodeIds.isNotEmpty);
    if (!hasNodes) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Piso ${floor.level}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(height: 4),
        ...zones.map((zone) => _buildDestinationsZoneSection(zone)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDestinationsZoneSection(ZoneModel zone) {
    final nodes = zone.nodeIds
        .map((id) => MockCampusData.getNodeById(id))
        .whereType<NodeModel>()
        .toList();

    if (nodes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getZoneIcon(zone.type), size: 13, color: _getZoneColor(zone.type)),
              const SizedBox(width: 4),
              Text(
                zone.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _getZoneColor(zone.type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: nodes.map((node) => _buildDestinationChip(node, zone)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationChip(NodeModel node, ZoneModel zone) {
    final isSelected = node.id == _selectedEndNodeId;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedStartNodeId == node.id) return;
          _selectedEndNodeId = node.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryColor
              : node.isDestination
                  ? AppTheme.errorColor.withValues(alpha: 0.08)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondaryColor
                : node.isDestination
                    ? AppTheme.errorColor.withValues(alpha: 0.3)
                    : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              node.isDestination ? Icons.school : Icons.location_on,
              size: 12,
              color: isSelected ? Colors.white : (node.isDestination ? AppTheme.errorColor : Colors.grey),
            ),
            const SizedBox(width: 4),
            Text(
              node.destinationLabel ?? node.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════

  IconData _getZoneIcon(ZoneType type) {
    switch (type) {
      case ZoneType.vesticulo:
        return Icons.door_front_door;
      case ZoneType.pasillo:
        return Icons.compare_arrows;
      case ZoneType.aula:
        return Icons.school;
      case ZoneType.laboratorio:
        return Icons.science;
      case ZoneType.biblioteca:
        return Icons.menu_book;
      case ZoneType.deporte:
        return Icons.sports_basketball;
      case ZoneType.servicio:
        return Icons.build;
      case ZoneType.destino:
        return Icons.flag;
      case ZoneType.transicion:
        return Icons.stairs;
    }
  }

  Color _getZoneColor(ZoneType type) {
    switch (type) {
      case ZoneType.vesticulo:
        return Colors.teal;
      case ZoneType.pasillo:
        return Colors.blueGrey;
      case ZoneType.aula:
        return Colors.blue;
      case ZoneType.laboratorio:
        return Colors.deepPurple;
      case ZoneType.biblioteca:
        return Colors.brown;
      case ZoneType.deporte:
        return Colors.orange;
      case ZoneType.servicio:
        return Colors.grey;
      case ZoneType.destino:
        return Colors.red;
      case ZoneType.transicion:
        return Colors.amber;
    }
  }

  String _getZoneTypeName(ZoneType type) {
    switch (type) {
      case ZoneType.vesticulo:
        return 'Vestíbulo';
      case ZoneType.pasillo:
        return 'Pasillo';
      case ZoneType.aula:
        return 'Aula';
      case ZoneType.laboratorio:
        return 'Laboratorio';
      case ZoneType.biblioteca:
        return 'Biblioteca';
      case ZoneType.deporte:
        return 'Deporte';
      case ZoneType.servicio:
        return 'Servicio';
      case ZoneType.destino:
        return 'Destino';
      case ZoneType.transicion:
        return 'Transición';
    }
  }

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
