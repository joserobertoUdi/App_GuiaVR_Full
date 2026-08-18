import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/features/navigation/presentation/utils/route_readiness.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';

class ManualLocationScreen extends StatefulWidget {
  const ManualLocationScreen({super.key});

  @override
  State<ManualLocationScreen> createState() => _ManualLocationScreenState();
}

class _ManualLocationScreenState extends State<ManualLocationScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFloor;
  NodeZone? _selectedZone;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NodeModel> _getFilteredNodes() {
    var nodes = MockCampusData.getAllNodes();

    if (_searchQuery.isNotEmpty) {
      nodes = nodes.where((node) {
        return node.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            node.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (node.destinationLabel?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    if (_selectedFloor != null) {
      nodes = nodes.where((n) => n.floorLevel == _selectedFloor).toList();
    }

    if (_selectedZone != null) {
      nodes = nodes.where((n) => n.zone == _selectedZone).toList();
    }

    return nodes;
  }

  void _showDestinationSelector(NodeModel startNode) {
    final destinations = MockCampusData.getDestinations()
        .where((d) => d.id != startNode.id)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seleccionar Destino',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desde: ${startNode.name}',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final dest = destinations[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(dest.destinationLabel ?? dest.name),
                    subtitle: Text('Piso ${dest.floorLevel}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).pop();
                      _startNavigation(startNode.id, dest.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNavigation(String startId, String endId) {
    RouteReadiness.startGuidedRoute(
      context,
      startNodeId: startId,
      endNodeId: endId,
      mode: RouteMode.guidedWalk,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNodes = _getFilteredNodes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Dónde estás?'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          _buildNodeStats(filteredNodes),
          Expanded(
            child: _buildNodesList(filteredNodes),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, ID o destino...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFloor,
              decoration: const InputDecoration(
                labelText: 'Piso',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...MockCampusData.campus.floors.map((f) => DropdownMenuItem(
                  value: f.level.toString(),
                  child: Text(f.name),
                )),
              ],
              onChanged: (v) => setState(() => _selectedFloor = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<NodeZone>(
              value: _selectedZone,
              decoration: const InputDecoration(
                labelText: 'Zona',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...NodeZone.values.map((z) => DropdownMenuItem(
                  value: z,
                  child: Text(_getZoneLabel(z)),
                )),
              ],
              onChanged: (v) => setState(() => _selectedZone = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeStats(List<NodeModel> nodes) {
    final destinations = nodes.where((n) => n.isDestination).length;
    final pasillos = nodes.where((n) => n.zone == NodeZone.pasillo).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatChip('${nodes.length} puntos', Icons.location_on, Colors.blue),
          const SizedBox(width: 8),
          _buildStatChip('$destinations destinos', Icons.school, Colors.orange),
          const SizedBox(width: 8),
          _buildStatChip('$pasillos pasillos', Icons.horizontal_rule, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodesList(List<NodeModel> nodes) {
    if (nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron puntos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros filtros',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final destinations = nodes.where((n) => n.isDestination).toList();
    final pasillos = nodes.where((n) => n.zone == NodeZone.pasillo).toList();
    final inicio = nodes.where((n) => n.zone == NodeZone.inicio).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (inicio.isNotEmpty) ...[
          _buildSectionHeader('Inicio', Icons.flag, Colors.green),
          ...inicio.map((node) => _buildNodeCard(node)),
          const SizedBox(height: 16),
        ],
        if (destinations.isNotEmpty) ...[
          _buildSectionHeader('Destinos', Icons.school, AppTheme.errorColor),
          ...destinations.map((node) => _buildNodeCard(node)),
          const SizedBox(height: 16),
        ],
        if (pasillos.isNotEmpty) ...[
          _buildSectionHeader('Pasillos', Icons.horizontal_rule, Colors.blue),
          ...pasillos.map((node) => _buildNodeCard(node)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(NodeModel node) {
    final zoneColors = {
      NodeZone.inicio: Colors.green,
      NodeZone.pasillo: Colors.blue,
      NodeZone.destino: Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: zoneColors[node.zone] ?? Colors.grey,
          child: Text(
            node.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          node.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(
              'Piso ${node.floorLevel}',
              style: AppTheme.bodySmall,
            ),
            if (node.hasDestination) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.destinationLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showDestinationSelector(node),
      ),
    );
  }

  String _getZoneLabel(NodeZone zone) {
    switch (zone) {
      case NodeZone.inicio:
        return 'Inicio';
      case NodeZone.pasillo:
        return 'Pasillo';
      case NodeZone.destino:
        return 'Destino';
    }
  }
}
