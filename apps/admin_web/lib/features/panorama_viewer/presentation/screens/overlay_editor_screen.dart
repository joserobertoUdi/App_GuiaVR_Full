import 'package:flutter/material.dart';
import 'package:admin_web/features/navigation/domain/models/node_model.dart';
import 'package:admin_web/features/navigation/domain/models/zone_model.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/panorama_overlay_model.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/connection_direction_model.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/overlay_storage.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/connection_direction_storage.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/mock_panoramas_data.dart';
import 'package:admin_web/features/panorama_viewer/domain/utils/guidance_resolver.dart';
import 'package:admin_web/features/panorama_viewer/presentation/widgets/panorama_viewer_widget.dart';
import 'package:admin_web/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/utils/panorama_geometry.dart';

class OverlayEditorScreen extends StatefulWidget {
  const OverlayEditorScreen({super.key});

  @override
  State<OverlayEditorScreen> createState() => _OverlayEditorScreenState();
}

class _OverlayEditorScreenState extends State<OverlayEditorScreen> {
  String? _selectedFloorId;
  String? _selectedZoneId;
  String? _selectedNodeId;
  PanoramaOverlay? _editingOverlay;
  bool _isAddingNew = false;

  final _textController = TextEditingController();
  OverlayType _newType = OverlayType.arrow;
  double _newYaw = 0;
  double _newPitch = 0;
  int _newColorValue = 0xFF2196F3;
  double _newScale = 1.0;
  OverlayAction _newAction = OverlayAction.none;
  String? _newActionTarget;
  double _newRotation = 0;

  String? _editingConnectionTargetId;
  double _editConnectionYaw = 0;
  double _editConnectionPitch = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _textController.clear();
    _newType = OverlayType.arrow;
    _newYaw = 0;
    _newPitch = 0;
    _newColorValue = 0xFF2196F3;
    _newScale = 1.0;
    _newAction = OverlayAction.none;
    _newActionTarget = null;
    _newRotation = 0;
    _editingOverlay = null;
    _isAddingNew = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de overlays 360°'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildNodeSelector(),
          if (_selectedNodeId != null) ...[
            _buildConnectionsSection(),
            _buildOverlayList(),
            if (_isAddingNew || _editingOverlay != null) _buildOverlayForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildNodeSelector() {
    final campus = MockCampusData.campus;
    final floors = campus.floors.toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    final zones = _selectedFloorId != null
        ? campus.getZonesForFloor(_selectedFloorId!)
        : const <ZoneModel>[];
    final nodes = _selectedZoneId != null
        ? campus.getNodesForZone(_selectedZoneId!)
        : const <NodeModel>[];

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_in_ar, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text('Editor de Overlays 360°', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Filtra por piso y zona, luego elige el nodo a editar',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('overlay_floor_selector'),
              initialValue: _selectedFloorId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Piso',
                prefixIcon: Icon(Icons.layers),
              ),
              items: floors.map((f) {
                return DropdownMenuItem(
                  value: f.id,
                  child: Text(
                    '${f.name} (Nivel ${f.level})',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedFloorId = v;
                  _selectedZoneId = null;
                  _selectedNodeId = null;
                  _resetForm();
                });
              },
            ),
            if (_selectedFloorId != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('overlay_zone_selector'),
                initialValue: _selectedZoneId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Zona',
                  prefixIcon: Icon(Icons.category),
                ),
                items: zones.map((z) {
                  return DropdownMenuItem(
                    value: z.id,
                    child: Text(
                      z.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedZoneId = v;
                    _selectedNodeId = null;
                    _resetForm();
                  });
                },
              ),
            ],
            if (_selectedZoneId != null) ...[
              const SizedBox(height: 12),
              if (nodes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          size: 14, color: AppTheme.warningColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Esta zona no tiene nodos. Agrega uno desde "Agregar".',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.warningColor),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  key: const ValueKey('overlay_node_selector'),
                  initialValue: _selectedNodeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Nodo',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: nodes.map((n) {
                    return DropdownMenuItem(
                      value: n.id,
                      child: Text(
                        '${n.id} — ${n.name}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedNodeId = v;
                      _resetForm();
                    });
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sección para que el operador defina, de forma simple, hacia qué punto de
  /// la foto 360° apunta cada salida del nodo. Estas direcciones alimentan la
  /// flecha de guía y la auto-rotación de la cámara de cada ruta.
  Widget _buildConnectionsSection() {
    final node = MockCampusData.getNodeById(_selectedNodeId!);
    if (node == null) return const SizedBox.shrink();

    final connected = node.connectedNodeIds
        .map((id) => MockCampusData.getNodeById(id))
        .whereType<NodeModel>()
        .toList();

    if (connected.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direcciones de salida (guía automática)',
                    style: AppTheme.headingMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Indica hacia qué punto de la foto 360° apunta cada salida. '
              'Al llegar a este nodo la cámara rotará ahí y la flecha lo '
              'reafirmará. Sin configuración se usa el rumbo geográfico.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ...connected.map(_buildConnectionTile),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(NodeModel target) {
    final node = MockCampusData.getNodeById(_selectedNodeId!);
    final autoYaw = node != null
        ? GuidanceResolver.autoYawFor(node: node, nextNode: target)
        : 0.0;
    final override =
        ConnectionDirectionStorage.getDirection(_selectedNodeId!, target.id);
    final isEditing = _editingConnectionTargetId == target.id;
    final isAuto = override == null;

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Icon(
            isAuto ? Icons.auto_mode : Icons.alt_route,
            color: isAuto ? Colors.grey : AppTheme.primaryColor,
            size: 20,
          ),
          title: Text(
            target.destinationLabel ?? target.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            isAuto
                ? 'Automático (geo): yaw ${autoYaw.toStringAsFixed(0)}°'
                : 'Manual: yaw ${override.yaw.toStringAsFixed(0)}° · pitch ${override.pitch.toStringAsFixed(0)}°',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => setState(() {
                  if (isEditing) {
                    _editingConnectionTargetId = null;
                  } else {
                    _editingConnectionTargetId = target.id;
                    _editConnectionYaw = override?.yaw ?? autoYaw;
                    _editConnectionPitch = override?.pitch ?? 0;
                  }
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (!isAuto)
                IconButton(
                  icon: const Icon(Icons.autorenew, size: 16, color: AppTheme.warningColor),
                  tooltip: 'Usar automático',
                  onPressed: () {
                    ConnectionDirectionStorage.removeDirection(
                        _selectedNodeId!, target.id);
                    setState(() {
                      if (_editingConnectionTargetId == target.id) {
                        _editingConnectionTargetId = null;
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
        if (isEditing) _buildConnectionEditor(target, autoYaw),
      ],
    );
  }

  Widget _buildConnectionEditor(NodeModel target, double autoYaw) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dirección hacia ${target.destinationLabel ?? target.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _editConnectionYaw = autoYaw;
                  _editConnectionPitch = 0;
                }),
                icon: const Icon(Icons.autorenew, size: 16),
                label: const Text('Auto', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Text('Yaw: ${_editConnectionYaw.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 11)),
          Slider(
            value: _editConnectionYaw,
            min: 0,
            max: 360,
            divisions: 72,
            onChanged: (v) => setState(() => _editConnectionYaw = v),
          ),
          Text(
            'Altura: ${_editConnectionPitch > 0 ? '${_editConnectionPitch.toStringAsFixed(0)}° arriba' : _editConnectionPitch < 0 ? '${_editConnectionPitch.abs().toStringAsFixed(0)}° abajo' : 'centrado'}',
            style: const TextStyle(fontSize: 11),
          ),
          Slider(
            value: _editConnectionPitch,
            min: -90,
            max: 90,
            divisions: 36,
            onChanged: (v) => setState(() => _editConnectionPitch = v),
          ),
          const SizedBox(height: 8),
          _YawPitchPreview(
            yaw: _editConnectionYaw,
            pitch: _editConnectionPitch,
            footerLabel: target.id,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ConnectionDirectionStorage.setDirection(
                  ConnectionDirection(
                    nodeId: _selectedNodeId!,
                    targetNodeId: target.id,
                    yaw: _editConnectionYaw,
                    pitch: _editConnectionPitch,
                  ),
                );
                setState(() => _editingConnectionTargetId = null);
              },
              icon: const Icon(Icons.save, size: 16),
              label: Text(
                ConnectionDirectionStorage.hasDirection(
                        _selectedNodeId!, target.id)
                    ? 'Actualizar dirección'
                    : 'Guardar dirección',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayList() {
    final overlays = OverlayStorage.getOverlaysForNode(_selectedNodeId!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Overlays', style: AppTheme.headingMedium),
                const Spacer(),
                Text(
                  '${overlays.length} elemento${overlays.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _resetForm();
                      _isAddingNew = true;
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            if (overlays.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.layers_clear, size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Sin overlays',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      Text(
                        'Agrega flechas, textos o botones al panorama',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...overlays.map((overlay) => _buildOverlayItem(overlay)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayItem(PanoramaOverlay overlay) {
    final isSelected = _editingOverlay?.id == overlay.id;
    final typeIcon = _getTypeIcon(overlay.type);
    final typeColor = Color(overlay.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: typeColor, size: 18),
        ),
        title: Text(
          overlay.text.isNotEmpty ? overlay.text : overlay.type.name.toUpperCase(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${overlay.type.name} · yaw: ${overlay.yaw.toStringAsFixed(0)}° · pitch: ${overlay.pitch.toStringAsFixed(0)}°${overlay.action == OverlayAction.navigateToNode ? ' → ${overlay.actionTarget}' : ''}',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: () => _startEditing(overlay),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
              onPressed: () => _deleteOverlay(overlay),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayForm() {
    final isEditing = _editingOverlay != null;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isEditing ? Icons.edit : Icons.add_circle, size: 18),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Editar Overlay' : 'Nuevo Overlay',
                  style: AppTheme.headingMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _resetForm()),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 12),
            _buildTextInput(),
            const SizedBox(height: 12),
            _buildPositionSliders(),
            const SizedBox(height: 12),
            _buildOverlayPreview(),
            const SizedBox(height: 12),
            _buildStyleControls(),
            const SizedBox(height: 12),
            _buildActionSelector(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveOverlay,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Actualizar' : 'Crear Overlay'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: OverlayType.values.map((type) {
            final isSelected = _newType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _newType = type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(_getTypeIcon(type), color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeName(type),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: _newType == OverlayType.arrow ? 'Etiqueta (opcional)' : 'Texto',
        prefixIcon: Icon(_getTypeIcon(_newType)),
        hintText: _newType == OverlayType.arrow
            ? 'Ej: Entrar al pasillo'
            : _newType == OverlayType.text
                ? 'Ej: Aula 101'
                : 'Ej: Ir a Aula 101',
      ),
    );
  }

  Widget _buildPositionSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Posición', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yaw (izquierda / derecha): ${_newYaw.toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 11),
            ),
            Slider(
              value: _newYaw,
              min: 0,
              max: 360,
              divisions: 36,
              onChanged: (v) => setState(() => _newYaw = v),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _newPitch > 5
                      ? Icons.arrow_upward
                      : _newPitch < -5
                          ? Icons.arrow_downward
                          : Icons.remove,
                  size: 12,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Altura (subir / bajar en la imagen): ${_newPitch > 0 ? '${_newPitch.toStringAsFixed(0)}° arriba' : _newPitch < 0 ? '${_newPitch.abs().toStringAsFixed(0)}° abajo' : 'centrado'}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            Slider(
              value: _newPitch,
              min: -90,
              max: 90,
              divisions: 36,
              onChanged: (v) => setState(() => _newPitch = v),
            ),
          ],
        ),
        if (_newType == OverlayType.arrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rotación: ${_newRotation.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 11)),
              Slider(
                value: _newRotation,
                min: 0,
                max: 360,
                divisions: 36,
                onChanged: (v) => setState(() => _newRotation = v),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildOverlayPreview() {
    final lon = yawToLongitude(_newYaw);
    final isBehind = lon.abs() > 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vista Previa — Imagen 360° en tiempo real', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          isBehind
              ? 'Queda DETRÁS de la cámara: solo se verá al girar la vista.'
              : 'Flecha anclada a la imagen 360: se oculta automáticamente al quedar atrás.',
          style: TextStyle(fontSize: 10, color: isBehind ? AppTheme.warningColor : Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        _LivePanoramaPreview(
          key: ValueKey('preview_${_selectedNodeId}_$_newType'),
          nodeId: _selectedNodeId!,
          temporaryOverlay: PanoramaOverlay(
            id: '_preview_temp',
            nodeId: _selectedNodeId!,
            type: _newType,
            yaw: _newYaw,
            pitch: _newPitch,
            text: _textController.text,
            colorValue: _newColorValue,
            scale: _newScale,
            opacity: 1.0,
            action: _newAction,
            actionTarget: _newActionTarget,
            rotation: _newRotation,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleControls() {
    final colors = [
      0xFF2196F3, 0xFF4CAF50, 0xFFFF9800, 0xFFF44336,
      0xFF9C27B0, 0xFF00BCD4, 0xFFFFEB3B, 0xFFFFFFFF,
      0xFF795548, 0xFF607D8B,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estilo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Color:', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            ...colors.map((c) {
              final isSelected = _newColorValue == c;
              return GestureDetector(
                onTap: () => setState(() => _newColorValue = c),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 14, color: c == 0xFFFFFFFF ? Colors.black : Colors.white)
                      : null,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Tamaño: ${_newScale.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: _newScale,
                min: 0.5,
                max: 3.0,
                divisions: 10,
                onChanged: (v) => setState(() => _newScale = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acción', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<OverlayAction>(
          initialValue: _newAction,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Acción al tocar',
            prefixIcon: Icon(Icons.touch_app),
          ),
          items: OverlayAction.values.map((a) {
            return DropdownMenuItem(
              value: a,
              child: Text(_getActionName(a)),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _newAction = v ?? OverlayAction.none;
              if (_newAction != OverlayAction.navigateToNode) {
                _newActionTarget = null;
              }
            });
          },
        ),
        if (_newAction == OverlayAction.navigateToNode) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _newActionTarget,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Nodo destino',
              prefixIcon: Icon(Icons.arrow_forward),
            ),
            items: MockCampusData.getAllNodes().map((n) {
              return DropdownMenuItem(
                value: n.id,
                child: Text('${n.id} — ${n.name}', style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _newActionTarget = v),
          ),
        ],
      ],
    );
  }

  void _startEditing(PanoramaOverlay overlay) {
    setState(() {
      _editingOverlay = overlay;
      _isAddingNew = false;
      _textController.text = overlay.text;
      _newType = overlay.type;
      _newYaw = overlay.yaw;
      _newPitch = overlay.pitch;
      _newColorValue = overlay.colorValue;
      _newScale = overlay.scale;
      _newAction = overlay.action;
      _newActionTarget = overlay.actionTarget;
      _newRotation = overlay.rotation;
    });
  }

  void _saveOverlay() {
    if (_selectedNodeId == null) return;
    if (_newType != OverlayType.arrow && _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El texto es obligatorio para textos y botones')),
      );
      return;
    }

    final overlay = PanoramaOverlay(
      id: _editingOverlay?.id ?? 'ov_${DateTime.now().millisecondsSinceEpoch}',
      nodeId: _selectedNodeId!,
      type: _newType,
      yaw: _newYaw,
      pitch: _newPitch,
      text: _textController.text,
      colorValue: _newColorValue,
      scale: _newScale,
      opacity: 1.0,
      action: _newAction,
      actionTarget: _newActionTarget,
      rotation: _newRotation,
    );

    if (_editingOverlay != null) {
      OverlayStorage.updateOverlay(overlay);
    } else {
      OverlayStorage.addOverlay(overlay);
    }

    setState(() => _resetForm());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingOverlay != null ? 'Overlay actualizado' : 'Overlay creado'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _deleteOverlay(PanoramaOverlay overlay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar overlay'),
        content: Text('¿Eliminar "${overlay.text.isNotEmpty ? overlay.text : overlay.type.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              OverlayStorage.removeOverlay(_selectedNodeId!, overlay.id);
              Navigator.pop(ctx);
              setState(() => _resetForm());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(OverlayType type) {
    switch (type) {
      case OverlayType.arrow:
        return Icons.arrow_forward;
      case OverlayType.text:
        return Icons.text_fields;
      case OverlayType.button:
        return Icons.touch_app;
    }
  }

  String _getTypeName(OverlayType type) {
    switch (type) {
      case OverlayType.arrow:
        return 'Flecha';
      case OverlayType.text:
        return 'Texto';
      case OverlayType.button:
        return 'Botón';
    }
  }

  String _getActionName(OverlayAction action) {
    switch (action) {
      case OverlayAction.none:
        return 'Sin acción (solo visual)';
      case OverlayAction.navigateToNode:
        return 'Navegar a nodo';
    }
  }
}

/// Vista previa fiel de una posición en la imagen 360°: escala ±90°…±180°,
/// regla de grados, línea de horizonte y marcador "DETRÁS — no visible"
/// cuando el punto quedaría fuera de la cámara.
class _YawPitchPreview extends StatelessWidget {
  final double yaw;
  final double pitch;
  final String? footerLabel;

  const _YawPitchPreview({
    required this.yaw,
    required this.pitch,
    this.footerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lon = yawToLongitude(yaw);
    final isBehind = lon.abs() > 90;
    final normalizedPitch = (pitch + 90) / 180;
    final x = ((lon + 180) / 360) * 280;
    final top = normalizedPitch * 140 - 10;

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue[900]!,
                    Colors.blue[600]!,
                    Colors.green[800]!,
                    Colors.green[600]!,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.view_in_ar,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Container(height: 1, color: Colors.white.withValues(alpha: 0.35)),
            ),
            ..._buildYawRuler(),
            if (!isBehind)
              Positioned(
                left: x - 20,
                top: top,
                child: _defaultMarker(),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                top: 60,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DETRÁS — no visible',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'yaw: ${yaw.toStringAsFixed(0)}° pitch: ${pitch.toStringAsFixed(0)}°',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
            if (footerLabel != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    footerLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 72,
              left: 138,
              child: Text(
                '▲',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultMarker() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.warningColor,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Icon(Icons.navigation, color: Colors.white, size: 18),
    );
  }

  List<Widget> _buildYawRuler() {
    const width = 280.0;
    final ticks = <Widget>[];
    for (var deg = -180; deg <= 180; deg += 15) {
      final x = ((deg + 180) / 360) * width;
      final isMajor = deg % 45 == 0;
      if (isMajor) {
        final String label;
        if (deg == 0) {
          label = '0°';
        } else if (deg == 180 || deg == -180) {
          label = '180°';
        } else {
          label = '${deg > 0 ? '+' : ''}$deg°';
        }
        ticks.add(Positioned(
          left: x - 12,
          top: 58,
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 8),
          ),
        ));
        ticks.add(Positioned(
          left: x,
          top: 70,
          child: Container(width: 1, height: 12, color: Colors.white.withValues(alpha: 0.5)),
        ));
      } else {
        ticks.add(Positioned(
          left: x,
          top: 70,
          child: Container(width: 1, height: 6, color: Colors.white.withValues(alpha: 0.25)),
        ));
      }
    }
    return ticks;
  }
}

/// Vista previa en vivo de la imagen 360° con overlays posicionados en tiempo
/// real. Muestra el panorama real del nodo seleccionado usando el mismo
/// `PanoramaViewerWidget` que se usa en la app, permitiendo al operador ver
/// exactamente cómo se verán los overlays en la imagen 360 antes de guardar.
class _LivePanoramaPreview extends StatefulWidget {
  final String nodeId;
  final PanoramaOverlay temporaryOverlay;

  const _LivePanoramaPreview({
    super.key,
    required this.nodeId,
    required this.temporaryOverlay,
  });

  @override
  State<_LivePanoramaPreview> createState() => _LivePanoramaPreviewState();
}

class _LivePanoramaPreviewState extends State<_LivePanoramaPreview> {
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _precacheImage();
  }

  @override
  void didUpdateWidget(_LivePanoramaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId) {
      _imageLoaded = false;
      _precacheImage();
    }
  }

  Future<void> _precacheImage() async {
    final panorama = MockPanoramasData.getOrCreateForNode(widget.nodeId);
    try {
      await precacheImage(AssetImage(panorama.imageUrl), context);
    } catch (_) {}
    if (mounted) setState(() => _imageLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final panorama = MockPanoramasData.getOrCreateForNode(widget.nodeId);

    final savedOverlays = OverlayStorage.getOverlaysForNode(widget.nodeId);
    final allOverlays = [...savedOverlays, widget.temporaryOverlay];

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (!_imageLoaded)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else
            PanoramaViewerWidget(
              panorama: panorama,
              onHotspotTap: (_) {},
              enableTransitions: false,
              autoRotateToGuidance: false,
              showDirectionHint: false,
              overlays: allOverlays,
            ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'yaw: ${widget.temporaryOverlay.yaw.toStringAsFixed(0)}° · pitch: ${widget.temporaryOverlay.pitch.toStringAsFixed(0)}°',
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'EN VIVO',
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Toca y arrastra para explorar — ${widget.nodeId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}