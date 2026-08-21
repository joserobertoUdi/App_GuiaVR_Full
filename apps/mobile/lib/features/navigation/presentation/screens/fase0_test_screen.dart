import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/campus_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/core/utils/campus_sync_service.dart';
import 'package:app_guia_ar/core/utils/navigation_settings.dart';
import 'package:app_guia_ar/core/utils/popular_destinations.dart';
import 'package:app_guia_ar/features/navigation/presentation/utils/route_readiness.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/quick_preview_screen.dart';

class Fase0TestScreen extends StatefulWidget {
  const Fase0TestScreen({super.key});
  @override
  State<Fase0TestScreen> createState() => _Fase0TestScreenState();
}

const Color _kRed = Color(0xFFE53935);
const Color _kRedDark = Color(0xFFB71C1C);
const Color _kRedMid = Color(0xFFC62828);
const Color _kRedLight = Color(0xFFFFEBEE);
const Color _kRedSoft = Color(0xFFFBE9E9);

enum _InputMode { select, search }

class _Fase0TestScreenState extends State<Fase0TestScreen> {
  RouteMode _selectedMode = RouteMode.guidedWalk;
  String? _selectedStartNodeId;
  String? _selectedEndNodeId;
  String? _defaultStartNodeId;
  bool _loadingDefault = true;
  CampusModel get _campus => MockCampusData.campus;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _InputMode _destinationInputMode = _InputMode.select;
  bool _showDestinationPanel = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultStart();
    _syncSub = CampusSyncNotifier.instance.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  StreamSubscription? _syncSub;

  @override
  void dispose() {
    _syncSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultStart() async {
    final id = await NavigationSettings.loadDefaultStartNodeId();
    if (!mounted) return;
    setState(() {
      _loadingDefault = false;
      if (id != null && MockCampusData.getNodeById(id) != null) {
        _defaultStartNodeId = id;
        _selectedStartNodeId = id;
      }
    });
  }

  bool _isTotem(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonalPx = sqrt(size.width * size.width + size.height * size.height);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return (diagonalPx / dpr / 25.4) >= 12.0;
  }

  @override
  Widget build(BuildContext context) {
    final totem = _isTotem(context);
    return Scaffold(
      backgroundColor: _kRedSoft,
      appBar: AppBar(
        title: Text(totem ? 'Totem - Planificar ruta' : 'Planificar ruta'),
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showPopularDestinations,
            icon: const Icon(Icons.star_rounded, color: Colors.white),
            tooltip: 'Destinos populares',
          ),
        ],
      ),
      body: totem ? _buildTotemLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeSelector(),
          const SizedBox(height: 20),
          _buildOriginBox(totem: false),
          const SizedBox(height: 16),
          if (_selectedStartNodeId != null) ...[
            _buildDestinationBox(totem: false),
            const SizedBox(height: 20),
          ],
          if (_selectedStartNodeId != null && _selectedEndNodeId != null)
            _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildTotemLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeSelector(),
          const SizedBox(height: 24),
          _buildOriginBox(totem: true),
          const SizedBox(height: 20),
          if (_selectedStartNodeId != null) ...[
            _buildDestinationBox(totem: true),
            if (_showDestinationPanel && _selectedStartNodeId != null) ...[
              const SizedBox(height: 12),
              _buildDestinationInlinePanel(),
            ],
            const SizedBox(height: 24),
          ],
          if (_selectedStartNodeId != null && _selectedEndNodeId != null)
            _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.directions_walk,
            title: 'Ruta guiada',
            subtitle: 'Paso a paso',
            isSelected: _selectedMode == RouteMode.guidedWalk,
            onTap: () => setState(() => _selectedMode = RouteMode.guidedWalk),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: Icons.play_circle_fill,
            title: 'Ruta rapida',
            subtitle: 'Automatica',
            isSelected: _selectedMode == RouteMode.quickPreview,
            onTap: () => setState(() => _selectedMode = RouteMode.quickPreview),
          ),
        ),
      ],
    );
  }
  Widget _buildOriginBox({required bool totem}) {
    final node = _selectedStartNodeId != null
        ? MockCampusData.getNodeById(_selectedStartNodeId!)
        : null;
    final isDefault = _selectedStartNodeId == _defaultStartNodeId && _defaultStartNodeId != null;
    return _SectionBox(
      label: 'Origen',
      icon: Icons.flag,
      child: GestureDetector(
        onTap: () => totem ? _showOriginInline() : _showOriginSelector(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: node != null ? _kRedSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: node != null ? _kRed : _kRedLight, width: node != null ? 2 : 1.5),
          ),
          child: node != null
              ? Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                    child: const Icon(Icons.flag, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name, style: TextStyle(fontSize: totem ? 17.0 : 15.0, fontWeight: FontWeight.w700, color: _kRedDark)),
                      if (isDefault) const Text('Inicio por defecto', style: TextStyle(fontSize: 11, color: _kRedMid, fontStyle: FontStyle.italic)),
                    ],
                  )),
                  const Icon(Icons.chevron_right, color: _kRed),
                ])
              : Row(children: [
                  Icon(_loadingDefault ? Icons.hourglass_empty : Icons.add_circle_outline, color: _kRed, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_loadingDefault ? 'Cargando...' : 'Toca para seleccionar origen',
                    style: TextStyle(fontSize: totem ? 16.0 : 14.0, color: _loadingDefault ? Colors.grey : _kRedMid))),
                  const Icon(Icons.chevron_right, color: _kRed),
                ]),
        ),
      ),
    );
  }

  Widget _buildDestinationBox({required bool totem}) {
    final node = _selectedEndNodeId != null ? MockCampusData.getNodeById(_selectedEndNodeId!) : null;
    if (totem) return _buildTotemDestinationBox(node);
    return _buildMobileDestinationBox(node);
  }

  Widget _buildMobileDestinationBox(NodeModel? node) {
    return _SectionBox(
      label: 'Destino',
      icon: Icons.location_on,
      child: GestureDetector(
        onTap: _showDestinationSelector,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: node != null ? _kRedSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: node != null ? _kRed : _kRedLight, width: node != null ? 2 : 1.5),
          ),
          child: node != null
              ? Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(node.destinationLabel ?? node.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kRedDark))),
                  const Icon(Icons.chevron_right, color: _kRed),
                ])
              : const Row(children: [
                  Icon(Icons.search, color: _kRed, size: 22),
                  SizedBox(width: 12),
                  Expanded(child: Text('Buscar destino...', style: TextStyle(fontSize: 14, color: _kRedMid))),
                  Icon(Icons.chevron_right, color: _kRed),
                ]),
        ),
      ),
    );
  }

  Widget _buildTotemDestinationBox(NodeModel? node) {
    return _SectionBox(
      label: 'Destino',
      icon: Icons.location_on,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _showDestinationPanel = !_showDestinationPanel),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: node != null ? _kRedSoft : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: node != null ? _kRed : _kRedLight, width: node != null ? 2 : 1.5),
            ),
            child: node != null
                ? Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(node.destinationLabel ?? node.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kRedDark))),
                    Icon(_showDestinationPanel ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _kRed),
                  ])
                : Row(children: [
                    const Icon(Icons.search, color: _kRed, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Toca para buscar o seleccionar destino',
                      style: TextStyle(fontSize: 16, color: _kRedMid))),
                    Icon(_showDestinationPanel ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _kRed),
                  ]),
          ),
        ),
        if (_showDestinationPanel) ...[
          const SizedBox(height: 12),
          _buildInputModeToggle(),
        ],
      ]),
    );
  }

  Widget _buildInputModeToggle() {
    return Container(
      decoration: BoxDecoration(color: _kRedSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kRedLight)),
      child: Row(children: [
        Expanded(child: _buildToggleChip(
          icon: Icons.grid_view, label: 'Seleccionar',
          isActive: _destinationInputMode == _InputMode.select,
          onTap: () => setState(() { _destinationInputMode = _InputMode.select; _searchController.clear(); _searchQuery = ''; }),
        )),
        Expanded(child: _buildToggleChip(
          icon: Icons.keyboard, label: 'Escribir',
          isActive: _destinationInputMode == _InputMode.search,
          onTap: () => setState(() { _destinationInputMode = _InputMode.search; _showDestinationPanel = true; }),
        )),
      ]),
    );
  }

  Widget _buildToggleChip({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isActive ? _kRed : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: isActive ? Colors.white : _kRedMid),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : _kRedMid)),
        ]),
      ),
    );
  }
  Widget _buildDestinationInlinePanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRedLight, width: 1.5),
        boxShadow: [BoxShadow(color: _kRedDark.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: _destinationInputMode == _InputMode.select ? _buildInlineSelectPanel() : _buildInlineSearchPanel(),
    );
  }

  Widget _buildInlineSelectPanel() {
    final destinations = MockCampusData.getDestinations();
    if (destinations.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No hay destinos', style: TextStyle(color: _kRedMid))));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Align(alignment: Alignment.centerLeft,
          child: Text('Toca un destino', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kRedMid))),
      ),
      Flexible(child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: destinations.length,
        itemBuilder: (ctx, i) => _buildDestinationGridCard(destinations[i]),
      )),
    ]);
  }

  Widget _buildInlineSearchPanel() {
    final destinations = _getFilteredDestinations();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchController, autofocus: true,
          decoration: InputDecoration(
            hintText: 'Escribe el nombre del destino...',
            prefixIcon: const Icon(Icons.search, color: _kRed),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                : null,
            filled: true, fillColor: _kRedSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRedLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRed, width: 2)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
      if (destinations.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Text('No se encontraron destinos', style: TextStyle(color: _kRedMid)))
      else
        Flexible(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: destinations.length,
          itemBuilder: (ctx, i) => _buildDestinationGridCard(destinations[i]),
        )),
    ]);
  }

  Widget _buildDestinationGridCard(NodeModel node) {
    final isSelected = node.id == _selectedEndNodeId;
    final isStart = node.id == _selectedStartNodeId;
    return GestureDetector(
      onTap: isStart ? null : () => setState(() { _selectedEndNodeId = node.id; _showDestinationPanel = false; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? _kRed : _kRedSoft, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isStart ? Colors.grey[300]! : isSelected ? _kRedDark : _kRedLight, width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Icon(isSelected ? Icons.check_circle : Icons.location_on, size: 18,
            color: isStart ? Colors.grey : isSelected ? Colors.white : _kRed),
          const SizedBox(width: 8),
          Expanded(child: Text(node.destinationLabel ?? node.name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: isStart ? Colors.grey : isSelected ? Colors.white : _kRedDark),
            overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildStartButton() {
    final mode = _selectedMode;
    final totem = _isTotem(context);
    return ElevatedButton.icon(
      onPressed: _startNavigation,
      icon: Icon(mode == RouteMode.quickPreview ? Icons.play_arrow : Icons.directions_walk, size: totem ? 30.0 : 26.0),
      label: Text(mode == RouteMode.quickPreview ? 'Iniciar vista rapida' : 'Iniciar ruta guiada'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kRed, foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: totem ? 22.0 : 18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6, shadowColor: _kRedDark.withValues(alpha: 0.5),
        textStyle: TextStyle(fontSize: totem ? 20.0 : 17.0, fontWeight: FontWeight.w800),
      ),
    );
  }
  void _showOriginSelector() {
    final allNodes = MockCampusData.getAllNodes();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (ctx, scrollController) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(16),
            child: Text('Selecciona tu origen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kRedDark))),
          Expanded(child: ListView.builder(
            controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allNodes.length,
            itemBuilder: (ctx, i) {
              final node = allNodes[i];
              final isSel = node.id == _selectedStartNodeId;
              final zone = node.zoneId != null ? _campus.getZone(node.zoneId!) : null;
              final floor = zone != null ? _campus.getFloor(zone.floorId) : null;
              final bldg = floor != null ? _campus.getBuilding(floor.buildingId) : null;
              return ListTile(
                leading: Icon(isSel ? Icons.check_circle : Icons.flag, color: isSel ? _kRed : _kRedMid),
                title: Text(node.name, style: TextStyle(fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? _kRed : _kRedDark)),
                subtitle: Text('${bldg?.name ?? ''} - Piso ${floor?.level ?? ''} - ${zone?.name ?? ''}',
                  style: const TextStyle(fontSize: 12, color: _kRedMid)),
                trailing: isSel ? const Icon(Icons.check, color: _kRed) : null,
                onTap: () { setState(() => _selectedStartNodeId = node.id); Navigator.pop(ctx); },
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showOriginInline() {
    final allNodes = MockCampusData.getAllNodes();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Selecciona tu origen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kRedDark)),
            const SizedBox(height: 16),
            Flexible(child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: allNodes.length,
              itemBuilder: (ctx, i) {
                final node = allNodes[i];
                final isSel = node.id == _selectedStartNodeId;
                return GestureDetector(
                  onTap: () { setState(() => _selectedStartNodeId = node.id); Navigator.pop(ctx); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSel ? _kRed : _kRedSoft, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSel ? _kRedDark : _kRedLight, width: isSel ? 2 : 1),
                    ),
                    child: Row(children: [
                      Icon(isSel ? Icons.check_circle : Icons.flag, size: 18, color: isSel ? Colors.white : _kRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(node.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSel ? Colors.white : _kRedDark),
                        overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _showDestinationSelector() {
    _searchController.clear();
    _searchQuery = '';
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
          builder: (ctx, scrollController) {
            final dests = _getFilteredDestinations();
            return Column(children: [
              Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController, autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: const Icon(Icons.search, color: _kRed),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setSheetState(() => _searchQuery = ''); })
                        : null,
                    filled: true, fillColor: _kRedSoft,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRedLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRed, width: 2)),
                  ),
                  onChanged: (v) => setSheetState(() => _searchQuery = v),
                ),
              ),
              Expanded(child: _searchQuery.isNotEmpty
                  ? _buildFlatResults(dests, scrollController)
                  : _buildHierarchicalResults(dests, scrollController)),
            ]);
          },
        ),
      ),
    );
  }

  List<NodeModel> _getFilteredDestinations() {
    final all = MockCampusData.getDestinations();
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((n) {
      final name = (n.destinationLabel ?? n.name).toLowerCase();
      return name.contains(q) || n.id.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildFlatResults(List<NodeModel> nodes, ScrollController ctrl) {
    if (nodes.isEmpty) return const Center(child: Text('No se encontraron destinos', style: TextStyle(color: _kRedMid)));
    return ListView.builder(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: nodes.length, itemBuilder: (ctx, i) => _buildDestinationTile(nodes[i]));
  }

  Widget _buildHierarchicalResults(List<NodeModel> nodes, ScrollController ctrl) {
    if (nodes.isEmpty) return const Center(child: Text('No hay destinos disponibles', style: TextStyle(color: _kRedMid)));
    final grouped = <String, Map<String, List<NodeModel>>>{};
    for (final node in nodes) {
      final zone = node.zoneId != null ? _campus.getZone(node.zoneId!) : null;
      final floor = zone != null ? _campus.getFloor(zone.floorId) : null;
      final bldg = floor != null ? _campus.getBuilding(floor.buildingId) : null;
      final bKey = bldg?.name ?? 'Sin edificio';
      final fKey = floor != null ? 'Piso ${floor.level}' : 'Sin piso';
      grouped.putIfAbsent(bKey, () => {});
      grouped[bKey]!.putIfAbsent(fKey, () => []);
      grouped[bKey]![fKey]!.add(node);
    }
    final items = <Widget>[];
    grouped.forEach((buildingName, floors) {
      items.add(_hierarchyHeader(Icons.apartment, buildingName));
      floors.forEach((floorName, zoneNodes) {
        items.add(_hierarchyHeader(Icons.layers, floorName, indent: 24));
        for (final node in zoneNodes) {
          items.add(Padding(padding: const EdgeInsets.only(left: 48), child: _buildDestinationTile(node)));
        }
      });
    });
    return ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16), children: items);
  }

  Widget _hierarchyHeader(IconData icon, String text, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 12, bottom: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: _kRedDark),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kRedDark)),
      ]),
    );
  }

  Widget _buildDestinationTile(NodeModel node) {
    final isSel = node.id == _selectedEndNodeId;
    final isStart = node.id == _selectedStartNodeId;
    final zone = node.zoneId != null ? _campus.getZone(node.zoneId!) : null;
    return ListTile(
      enabled: !isStart,
      leading: Icon(isSel ? Icons.check_circle : Icons.location_on,
        color: isStart ? Colors.grey : (isSel ? _kRed : _kRedMid)),
      title: Text(node.destinationLabel ?? node.name,
        style: TextStyle(fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
          color: isStart ? Colors.grey : (isSel ? _kRed : _kRedDark))),
      subtitle: Text(zone?.name ?? '', style: const TextStyle(fontSize: 12, color: _kRedMid)),
      trailing: isSel ? const Icon(Icons.check, color: _kRed)
          : isStart ? const Text('Origen', style: TextStyle(fontSize: 11, color: Colors.grey)) : null,
      onTap: isStart ? null : () { setState(() => _selectedEndNodeId = node.id); Navigator.pop(context); },
    );
  }

  void _showPopularDestinations() async {
    final popular = await PopularDestinations.getPopular(limit: 10);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.8, expand: false,
        builder: (ctx, scrollController) {
          if (popular.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_border, size: 48, color: _kRedLight),
                SizedBox(height: 12),
                Text('Aun no hay destinos populares', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kRedDark)),
                SizedBox(height: 6),
                Text('Cada vez que inicies una ruta, tu destino se registrara aqui.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _kRedMid)),
              ]),
            ));
          }
          return Column(children: [
            Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.star, color: Color(0xFFFFC107), size: 22),
                SizedBox(width: 8),
                Text('Destinos populares', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kRedDark)),
              ]),
            ),
            Expanded(child: ListView.builder(
              controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popular.length,
              itemBuilder: (ctx, i) {
                final entry = popular[i];
                final node = MockCampusData.getNodeById(entry.nodeId);
                if (node == null) return const SizedBox.shrink();
                final zone = node.zoneId != null ? _campus.getZone(node.zoneId!) : null;
                final floor = zone != null ? _campus.getFloor(zone.floorId) : null;
                final bldg = floor != null ? _campus.getBuilding(floor.buildingId) : null;
                return ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  title: Text(node.destinationLabel ?? node.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _kRedDark)),
                  subtitle: Text('${bldg?.name ?? ''} - ${floor != null ? 'Piso ${floor.level}' : ''}',
                    style: const TextStyle(fontSize: 12, color: _kRedMid)),
                  trailing: Text('${entry.visitCount} vez${entry.visitCount > 1 ? 'es' : ''}',
                    style: const TextStyle(fontSize: 11, color: _kRedMid)),
                  onTap: () { Navigator.pop(ctx); setState(() => _selectedEndNodeId = entry.nodeId); },
                );
              },
            )),
          ]);
        },
      ),
    );
  }

  void _startNavigation() {
    if (_selectedStartNodeId == null || _selectedEndNodeId == null) return;
    PopularDestinations.trackVisit(_selectedEndNodeId!);

    if (_selectedMode == RouteMode.quickPreview) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuickPreviewScreen(endNodeId: _selectedEndNodeId!),
        ),
      );
    } else {
      RouteReadiness.startGuidedRoute(
        context,
        startNodeId: _selectedStartNodeId!,
        endNodeId: _selectedEndNodeId!,
        mode: _selectedMode,
      );
    }
  }
}

class _SectionBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _SectionBox({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRedLight, width: 1.5),
        boxShadow: [BoxShadow(color: _kRedDark.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: _kRed),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kRedDark)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _kRed : Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _kRedDark : _kRedLight, width: isSelected ? 2 : 1.5),
          boxShadow: isSelected ? [BoxShadow(color: _kRedDark.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
        ),
        child: Column(children: [
          Icon(icon, size: 36, color: isSelected ? Colors.white : _kRed),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : _kRedDark)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : _kRedMid)),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isSelected ? 40 : 18, height: 3,
            decoration: BoxDecoration(color: isSelected ? Colors.white : _kRedLight, borderRadius: BorderRadius.circular(2)),
          ),
        ]),
      ),
    );
  }
}
