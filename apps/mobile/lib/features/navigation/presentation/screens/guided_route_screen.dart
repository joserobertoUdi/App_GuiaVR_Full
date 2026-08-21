import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/features/panorama_viewer/presentation/widgets/panorama_viewer_widget.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/mock_panoramas_data.dart';
import 'package:app_guia_ar/core/utils/app_notifications.dart';
import 'package:app_guia_ar/core/utils/local_image_storage.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/utils/guidance_resolver.dart';
import 'package:app_guia_ar/core/utils/app_settings.dart';

class GuidedRouteScreen extends StatefulWidget {
  final String startNodeId;
  final String endNodeId;
  final RouteMode mode;

  const GuidedRouteScreen({
    super.key,
    required this.startNodeId,
    required this.endNodeId,
    this.mode = RouteMode.guidedWalk,
  });

  @override
  State<GuidedRouteScreen> createState() => _GuidedRouteScreenState();
}

class _GuidedRouteScreenState extends State<GuidedRouteScreen> {
  late RouteModel _route;
  bool _showDirectionWarning = false;
  int _autoAdvanceIndex = 0;

  @override
  void initState() {
    super.initState();
    _route = MockCampusData.calculateRoute(
      startId: widget.startNodeId,
      endId: widget.endNodeId,
      mode: widget.mode,
    );

    _preloadRouteImages();

    if (widget.mode == RouteMode.quickPreview) {
      _startAutoAdvance();
    }
  }

  /// Precalienta las imágenes del disco para que la primera transición y las
  /// siguientes no muestren pantallas en negro o de carga.
  void _preloadRouteImages() {
    for (final node in _route.nodes) {
      LocalImageStorage.getImageBytes(node.id);
    }
  }

  Future<void> _startAutoAdvance() async {
    final delay = Duration(
      seconds: await AppSettings.quickPreviewDelaySeconds(),
    );
    Future.doWhile(() async {
      await Future.delayed(delay);
      if (!mounted || _autoAdvanceIndex >= _route.nodes.length - 1) return false;
      setState(() {
        _autoAdvanceIndex++;
        _route = _route.copyWith(currentStepIndex: _autoAdvanceIndex);
      });
      return _autoAdvanceIndex < _route.nodes.length - 1;
    });
  }

  void _previousStep() {
    if (_autoAdvanceIndex <= 0) return;
    setState(() {
      _autoAdvanceIndex--;
      _route = _route.copyWith(currentStepIndex: _autoAdvanceIndex);
    });
  }

  void _nextStep() {
    if (_autoAdvanceIndex >= _route.nodes.length - 1) return;
    setState(() {
      _autoAdvanceIndex++;
      _route = _route.copyWith(currentStepIndex: _autoAdvanceIndex);
    });
  }

  void _simulateWrongDirection() {
    setState(() => _showDirectionWarning = true);
    AppNotifications.showWarning(
      context,
      title: 'Dirección incorrecta',
      description:
          'La ruta correcta es: ${_route.currentStep?.instruction ?? "sigue recto"}',
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showDirectionWarning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_route.hasError || _route.nodes.isEmpty) {
      final issues = MockCampusData.repository.validate();
      final critical = issues.where((e) => e.severity == 'error').take(6).toList();
      final warnings = issues.where((e) => e.severity == 'warning').take(4).toList();

      return Scaffold(
        appBar: AppBar(
          title: const Text('Error de Ruta'),
          backgroundColor: AppTheme.errorColor,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.error_outline, color: AppTheme.errorColor, size: 56),
                const SizedBox(height: 12),
                Text(
                  'No se pudo calcular la ruta',
                  style: AppTheme.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _route.errorMessage ?? 'Error desconocido',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (critical.isNotEmpty || warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Qué falta para corregir:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...critical.map((e) => _errorTile(Icons.error, AppTheme.errorColor, e.message)),
                  ...warnings.map((e) => _errorTile(Icons.warning_amber, AppTheme.warningColor, e.message)),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentNode = _route.nodes[_autoAdvanceIndex];
    final isCompleted = _autoAdvanceIndex >= _route.nodes.length - 1;
    final panorama = MockPanoramasData.getOrCreateForNode(currentNode.id);
    final guidance = _buildGuidance(currentNode, panorama);

    return Scaffold(
      body: Stack(
        children: [
          _buildPanorama(currentNode, panorama, guidance),
          _buildTopBar(currentNode),
          _buildProgressBar(),
          if (_showDirectionWarning) _buildWrongDirectionBanner(),
          if (isCompleted) _buildCompletedBanner(),
          if (!isCompleted) _buildNavigationControls(),
          if (widget.mode == RouteMode.quickPreview)
            _buildQuickPreviewOverlay(guidance),
        ],
      ),
    );
  }

  Widget _buildPanorama(
    NodeModel node,
    PanoramaModel panorama,
    GuidanceArrow? guidance,
  ) {
    return PanoramaViewerWidget(
      panorama: panorama,
      onHotspotTap: (targetId) {
        final idx = _route.nodeIds.indexOf(targetId);
        if (idx >= 0 && idx > _autoAdvanceIndex) {
          setState(() {
            _autoAdvanceIndex = idx;
            _route = _route.copyWith(currentStepIndex: _autoAdvanceIndex);
          });
        }
      },
      guidance: guidance,
      showDirectionHint: false,
    );
  }

  /// Flecha de guía automática: apunta (en la imagen 360) hacia el siguiente
  /// nodo de la ruta. Resuelve la dirección con la prioridad:
  /// dirección del operador → hotspot de la conexión → rumbo geográfico.
  GuidanceArrow? _buildGuidance(NodeModel node, PanoramaModel panorama) {
    if (_autoAdvanceIndex >= _route.nodes.length - 1) return null;
    final nextNode = _route.nodes[_autoAdvanceIndex + 1];

    final resolved = GuidanceResolver.resolve(
      node: node,
      nextNode: nextNode,
      panorama: panorama,
    );
    if (resolved == null) return null;

    return GuidanceArrow(
      yaw: resolved.yaw,
      pitch: resolved.pitch,
      label: nextNode.destinationLabel ?? nextNode.name,
      targetNodeId: nextNode.id,
    );
  }

  Widget _buildTopBar(NodeModel currentNode) {
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
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _route.destinationNode?.destinationLabel ??
                        _route.destinationNode?.name ??
                        'Destino',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (currentNode.floorLevel != null) ...[
                        Icon(Icons.layers, color: Colors.white.withValues(alpha: 0.6), size: 11),
                        const SizedBox(width: 2),
                        Text(
                          'Piso ${currentNode.floorLevel}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (currentNode.zoneId != null) ...[
                        Icon(Icons.category, color: Colors.white.withValues(alpha: 0.6), size: 11),
                        const SizedBox(width: 2),
                        Text(
                          MockCampusData.campus.getZone(currentNode.zoneId!)?.name ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.mode == RouteMode.quickPreview
                            ? 'Vista rápida'
                            : 'Ruta guiada',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildModeBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.mode == RouteMode.quickPreview
            ? AppTheme.warningColor
            : AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.mode == RouteMode.quickPreview
                ? Icons.play_circle
                : Icons.directions_walk,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            widget.mode == RouteMode.quickPreview ? 'Rápida' : 'Guiada',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _route.nodes.length > 1
        ? _autoAdvanceIndex / (_route.nodes.length - 1)
        : 0.0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_autoAdvanceIndex + 1} / ${_route.nodes.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStepDots(),
        ],
      ),
    );
  }

  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_route.nodes.length, (index) {
        final isCurrent = index == _autoAdvanceIndex;
        final isPassed = index < _autoAdvanceIndex;
        final node = _route.nodes[index];

        return GestureDetector(
          onTap: () {
            setState(() {
              _autoAdvanceIndex = index;
              _route = _route.copyWith(currentStepIndex: index);
            });
          },
          child: Container(
            width: isCurrent ? 14 : 8,
            height: isCurrent ? 14 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? AppTheme.warningColor
                  : isPassed
                      ? AppTheme.successColor
                      : node.isDestination
                          ? AppTheme.errorColor
                          : Colors.white54,
              border: isCurrent
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppTheme.warningColor.withValues(alpha: 0.6),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWrongDirectionBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 110,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showDirectionWarning ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dirección incorrecta',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'La ruta correcta es: ${_route.currentStep?.instruction ?? "sigue recto"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(_route.isWrong ? Icons.arrow_back : Icons.check),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 110,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            const Text(
              '¡Llegaste a tu destino!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _route.destinationNode?.destinationLabel ??
                  _route.destinationNode?.name ??
                  '',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    final isLast = _autoAdvanceIndex >= _route.nodes.length - 1;
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_route.currentStep?.instruction != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getDirectionIcon(),
                      color: AppTheme.warningColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _route.currentStep!.instruction!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _autoAdvanceIndex > 0 ? _previousStep : null,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Atrás'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: _autoAdvanceIndex > 0 ? Colors.white30 : Colors.white12,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLast ? null : _nextStep,
                    icon: Icon(
                      isLast ? Icons.check_circle : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(isLast ? 'Llegaste' : 'Siguiente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast ? AppTheme.successColor : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.successColor,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPreviewOverlay(GuidanceArrow? guidance) {
    final isLast = _autoAdvanceIndex >= _route.nodes.length - 1;
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLast
                    ? 'Destino alcanzado — Paso ${_autoAdvanceIndex + 1} de ${_route.nodes.length}'
                    : 'Paso ${_autoAdvanceIndex + 1} de ${_route.nodes.length} · rumbo ${guidance != null ? '${guidance.yaw.toStringAsFixed(0)}° → ${guidance.label}' : '—'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDirectionIcon() {
    final bearing = _route.currentStep?.bearingToNext ?? 0;
    if (bearing >= 315 || bearing < 45) return Icons.arrow_upward;
    if (bearing >= 45 && bearing < 135) return Icons.arrow_forward;
    if (bearing >= 135 && bearing < 225) return Icons.arrow_downward;
    return Icons.arrow_back;
  }

  Widget _errorTile(IconData icon, Color color, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}
