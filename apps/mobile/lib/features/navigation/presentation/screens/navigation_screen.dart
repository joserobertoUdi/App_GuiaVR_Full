import 'package:flutter/material.dart';

import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/zone_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/mock_panoramas_data.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/features/panorama_viewer/presentation/widgets/panorama_viewer_widget.dart';

class NavigationScreen extends StatefulWidget {
  final String startNodeId;
  final String? destinationNodeId;

  const NavigationScreen({
    super.key,
    required this.startNodeId,
    this.destinationNodeId,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  NodeModel? _currentNode;
  PanoramaModel? _currentPanorama;
  List<NodeModel> _connectedNodes = [];
  List<String> _visitedNodeIds = [];
  bool _isLoading = true;
  String? _error;
  ZoneModel? _currentZone;
  String? _currentFloorName;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final node = MockCampusData.getNodeById(widget.startNodeId);
      if (node == null) {
        setState(() {
          _isLoading = false;
          _error = 'Nodo inicial no encontrado: ${widget.startNodeId}';
        });
        return;
      }

      final panorama = MockPanoramasData.getOrCreateForNode(widget.startNodeId);
      final connectedNodes = MockCampusData.getConnectedNodes(widget.startNodeId);

      _updateContext(node);

      setState(() {
        _currentNode = node;
        _currentPanorama = panorama;
        _connectedNodes = connectedNodes;
        _visitedNodeIds = [widget.startNodeId];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al inicializar: $e';
      });
    }
  }

  void _updateContext(NodeModel node) {
    if (node.zoneId != null) {
      _currentZone = MockCampusData.campus.getZone(node.zoneId!);
      if (_currentZone != null) {
        final floor = MockCampusData.campus.getFloor(_currentZone!.floorId);
        _currentFloorName = floor?.name;
      }
    } else {
      _currentZone = null;
      _currentFloorName = node.floorLevel != null ? 'Piso ${node.floorLevel}' : null;
    }
  }

  Future<void> _navigateToNode(String targetNodeId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final targetNode = MockCampusData.getNodeById(targetNodeId);
      if (targetNode == null) {
        setState(() {
          _isLoading = false;
          _error = 'Nodo destino no encontrado: $targetNodeId';
        });
        return;
      }

      final targetPanorama = MockPanoramasData.getOrCreateForNode(targetNodeId);
      final connectedNodes = MockCampusData.getConnectedNodes(targetNodeId);

      _updateContext(targetNode);

      setState(() {
        _currentNode = targetNode;
        _currentPanorama = targetPanorama;
        _connectedNodes = connectedNodes;
        _isLoading = false;
        if (!_visitedNodeIds.contains(targetNodeId)) {
          _visitedNodeIds.add(targetNodeId);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al navegar: $e';
      });
    }
  }

  bool get _isAtDestination =>
      widget.destinationNodeId != null &&
      _currentNode?.id == widget.destinationNodeId;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando panorama...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _currentNode == null || _currentPanorama == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(_error ?? 'Error desconocido', textAlign: TextAlign.center, style: AppTheme.bodyLarge),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeNavigation,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PanoramaViewerWidget(
            panorama: _currentPanorama!,
            onHotspotTap: _navigateToNode,
            highlightedNodeId: widget.destinationNodeId,
          ),
          _buildTopBar(),
          _buildNodeInfo(),
          if (_isAtDestination) _buildDestinationBanner(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentNode!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (_currentFloorName != null) ...[
                        Icon(Icons.layers, color: Colors.white.withValues(alpha: 0.7), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          _currentFloorName!,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (_currentZone != null) ...[
                        Icon(Icons.category, color: Colors.white.withValues(alpha: 0.7), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          _currentZone!.name,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (widget.destinationNodeId != null)
                        Text(
                          '→ ${_getDestinationName()}',
                          style: TextStyle(color: Colors.amber.withValues(alpha: 0.9), fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _buildVisitedCounter(),
          ],
        ),
      ),
    );
  }

  String _getDestinationName() {
    final destinationNode = MockCampusData.getNodeById(widget.destinationNodeId!);
    return destinationNode?.name ?? 'Desconocido';
  }

  Widget _buildVisitedCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place, color: Colors.white.withValues(alpha: 0.8), size: 16),
          const SizedBox(width: 4),
          Text(
            '${_visitedNodeIds.length} visitados',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeInfo() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentNode!.description.isNotEmpty ? _currentNode!.description : _currentNode!.name,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_currentZone != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildContextChip(_currentFloorName ?? '', Icons.layers),
                  const SizedBox(width: 6),
                  _buildContextChip(_currentZone!.name, Icons.category),
                  const SizedBox(width: 6),
                  _buildContextChip(_getZoneTypeLabel(_currentZone!.type), Icons.label),
                ],
              ),
            ],
            if (_connectedNodes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Nodos conectados (${_connectedNodes.length}):',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _connectedNodes.map((node) {
                  final isConnectedToDestination = node.id == widget.destinationNodeId;
                  return ActionChip(
                    label: Text(node.name, style: TextStyle(color: isConnectedToDestination ? Colors.white : Colors.black87, fontSize: 12)),
                    backgroundColor: isConnectedToDestination ? AppTheme.secondaryColor : Colors.white,
                    onPressed: () => _navigateToNode(node.id),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContextChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 10),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
        ],
      ),
    );
  }

  String _getZoneTypeLabel(ZoneType type) {
    switch (type) {
      case ZoneType.vesticulo: return 'Vestíbulo';
      case ZoneType.pasillo: return 'Pasillo';
      case ZoneType.aula: return 'Aula';
      case ZoneType.laboratorio: return 'Laboratorio';
      case ZoneType.biblioteca: return 'Biblioteca';
      case ZoneType.deporte: return 'Deportes';
      case ZoneType.servicio: return 'Servicio';
      case ZoneType.destino: return 'Destino';
      case ZoneType.transicion: return 'Transición';
    }
  }

  Widget _buildDestinationBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppTheme.successColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¡Llegaste a tu destino!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_currentNode!.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
