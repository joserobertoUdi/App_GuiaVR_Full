import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import 'package:admin_web/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/hotspot_model.dart';
import 'package:admin_web/features/panorama_viewer/domain/models/panorama_overlay_model.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/overlay_storage.dart';
import 'package:admin_web/core/theme/app_theme.dart';
import 'package:admin_web/core/constants/app_constants.dart';
import 'package:admin_web/core/utils/local_image_storage.dart';
import 'package:admin_web/core/utils/panorama_geometry.dart';

/// Representa la flecha de guía automática: fija en la imagen 360 (yaw/pitch)
/// hacia donde debe dirigirse el usuario según la ruta calculada.
class GuidanceArrow {
  final double yaw;
  final double pitch;
  final String label;
  final String? targetNodeId;

  const GuidanceArrow({
    required this.yaw,
    required this.pitch,
    this.label = '',
    this.targetNodeId,
  });
}

class PanoramaViewerWidget extends StatefulWidget {
  final PanoramaModel panorama;
  final Function(String targetNodeId) onHotspotTap;
  final String? highlightedNodeId;
  final bool enableTransitions;
  final Duration transitionDuration;
  final GuidanceArrow? guidance;

  /// Cuando es `true`, al mostrar un nodo la cámara rota suavemente hacia la
  /// dirección de guía (yaw/pitch) para que el usuario vea el rumbo correcto
  /// apenas entra al nodo, y la flecha lo reafirma en la imagen 360°.
  final bool autoRotateToGuidance;
  final bool showDirectionHint;

  /// Lista opcional de overlays a mostrar. Cuando se provee, reemplaza la
  /// lectura de `OverlayStorage` y permite al editor de overlays pasar
  /// overlays temporales en tiempo real sin modificar el storage.
  final List<PanoramaOverlay>? overlays;

  const PanoramaViewerWidget({
    super.key,
    required this.panorama,
    required this.onHotspotTap,
    this.highlightedNodeId,
    this.enableTransitions = true,
    this.transitionDuration = const Duration(milliseconds: 450),
    this.guidance,
    this.autoRotateToGuidance = true,
    this.showDirectionHint = true,
    this.overlays,
  });

  @override
  State<PanoramaViewerWidget> createState() => _PanoramaViewerWidgetState();
}

class _PanoramaViewerWidgetState extends State<PanoramaViewerWidget>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;

  PanoramaModel? _previousPanorama;
  bool _isTransitioning = false;

  final Map<String, Uint8List?> _imageCache = {};
  final Map<String, bool> _imageReady = {};

  /// Controlador de cámara del visor 360: permite rotar la vista de forma
  /// programática y fluida hacia la dirección de guía al entrar a un nodo.
  late final PanoramaController _cameraController;

  /// Dirección (izquierda/derecha/arriba/abajo) hacia donde queda el rumbo de
  /// guía fuera de vista. `null` = el rumbo ya está en pantalla (o no hay guía).
  final ValueNotifier<OffscreenDirection?> _edgeHint =
      ValueNotifier<OffscreenDirection?>(null);

  /// Temporizador que devuelve la cámara a la orientación previa luego de
  /// mirar la guía durante un par de segundos.
  Timer? _guidanceReturnTimer;

  /// Tiempo hasta que la rotación de `setView` (asintótica) queda imperceptible.
  static const Duration _guidanceSettleDuration = Duration(milliseconds: 1400);

  /// Tiempo que la cámara se mantiene fija en la guía antes de regresar.
  static const Duration _guidanceHoldDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _cameraController = PanoramaController();
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // El primer panorama se muestra completo (sin fade) apenas esté listo.
    _transitionController.value = 1;
    _loadAndPrecache(widget.panorama);
  }

  @override
  void didUpdateWidget(PanoramaViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panorama.id != widget.panorama.id ||
        oldWidget.guidance != widget.guidance) {
      _guidanceReturnTimer?.cancel();
    }
    if (oldWidget.panorama.id != widget.panorama.id) {
      if (widget.enableTransitions) {
        _startTransition(oldWidget.panorama);
      } else {
        _loadAndPrecache(widget.panorama);
      }
    }
  }

  @override
  void dispose() {
    _guidanceReturnTimer?.cancel();
    _edgeHint.dispose();
    _cameraController.dispose();
    _transitionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAndPrecache(PanoramaModel panorama) async {
    Uint8List? imageBytes;
    try {
      imageBytes = await LocalImageStorage.getImageBytes(panorama.nodeId);
    } catch (_) {
      imageBytes = null;
    }
    if (!mounted) return;
    _imageCache[panorama.nodeId] = imageBytes;
    setState(() {});

    final provider = imageBytes != null
        ? MemoryImage(imageBytes) as ImageProvider
        : AssetImage(panorama.imageUrl) as ImageProvider;
    try {
      await precacheImage(provider, context);
    } catch (_) {
      // Si la imagen no puede decodificarse, se muestra el placeholder.
    }
    if (!mounted) return;
    _imageReady[panorama.nodeId] = true;
    setState(() {});
    _maybeRotateToGuidance();
  }

  /// Rota la cámara hacia la dirección de guía del nodo actual una vez que el
  /// panorama está visible. La rotación es suave (el paquete amortigua los
  /// deltas hacia el objetivo) y queda alineada con la flecha de guía.
  void _maybeRotateToGuidance() {
    if (!widget.autoRotateToGuidance) return;
    final guidance = widget.guidance;
    if (guidance == null) return;
    if (!(_imageReady[widget.panorama.nodeId] ?? false)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cameraController.setView(
        guidance.pitch.clamp(-90.0, 90.0).toDouble(),
        yawToLongitude(guidance.yaw),
      );
    });
  }

  /// Al tocar la brújula de borde, la cámara rota de forma fluida hacia el
  /// rumbo de guía, se mantiene unos segundos apuntando ahí y luego regresa a
  /// la orientación que tenía antes del toque. No altera la orientación base
  /// del usuario: solo la mira temporalmente y la restaura.
  void _focusOnGuidance() {
    final guidance = widget.guidance;
    if (guidance == null) return;
    _guidanceReturnTimer?.cancel();

    final fromLatitude = _cameraController.getLatitude();
    final fromLongitude = _cameraController.getLongitude();
    final toLatitude = guidance.pitch.clamp(-90.0, 90.0).toDouble();
    final toLongitude = yawToLongitude(guidance.yaw);

    _cameraController.setView(toLatitude, toLongitude);

    _guidanceReturnTimer = Timer(
      _guidanceSettleDuration + _guidanceHoldDuration,
      () {
        if (!mounted) return;
        _cameraController.setView(fromLatitude, fromLongitude);
      },
    );
  }

  /// Mantiene el panorama anterior visible (sin negro) hasta que la textura
  /// del siguiente esté lista, y recién entonces cruza el fade.
  Future<void> _startTransition(PanoramaModel oldPanorama) async {
    setState(() {
      _previousPanorama = oldPanorama;
      _isTransitioning = true;
      _transitionController.value = 0;
    });
    await _loadAndPrecache(widget.panorama);
    if (!mounted) return;
    _transitionController.reset();
    _transitionController.forward().then((_) {
      if (mounted) {
        setState(() {
          _previousPanorama = null;
          _isTransitioning = false;
        });
        _maybeRotateToGuidance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isTransitioning && _previousPanorama != null)
          _buildPanoramaLayer(_previousPanorama!, isFading: true),
        _buildPanoramaLayer(widget.panorama, isFading: false),
        _buildEdgeHint(),
        if (widget.showDirectionHint) _buildDirectionIndicator(),
        if (_isTransitioning) _buildTransitionOverlay(),
      ],
    );
  }

  Widget _buildPanoramaLayer(PanoramaModel panorama, {required bool isFading}) {
    final imageBytes = _imageCache[panorama.nodeId];
    final ready = _imageReady[panorama.nodeId] ?? false;

    final Image image;
    if (imageBytes != null) {
      image = Image.memory(
        imageBytes,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(panorama);
        },
      );
    } else {
      image = Image.asset(
        panorama.imageUrl,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(panorama);
        },
      );
    }

    final Widget content = !ready
        ? _buildPlaceholderImage(panorama)
        : PanoramaViewer(
            animSpeed: 0,
            zoom: 0.7,
            minZoom: 0.5,
            maxZoom: 5,
            sensorControl: SensorControl.orientation,
            panoramaController: _cameraController,
            hotspots: _buildHotspots(panorama),
            onViewChanged: isFading ? null : _handleViewChanged,
            child: image,
          );

    return AnimatedBuilder(
      animation: _transitionController,
      child: content,
      builder: (context, child) {
        return FadeTransition(
          opacity: isFading
              ? ReverseAnimation(_fadeAnimation)
              : _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(PanoramaModel panorama) {
    final colors = _getPlaceholderColors(panorama.id);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Vista 360°',
              style: AppTheme.headingMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              panorama.nodeId,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Cargando panorama…',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getPlaceholderColors(String nodeId) {
    final hash = nodeId.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;

    return [
      Color.fromARGB(255, r, g, b),
      Color.fromARGB(255, (r * 0.7).round(), (g * 0.7).round(), (b * 0.7).round()),
      Color.fromARGB(255, (r * 0.4).round(), (g * 0.4).round(), (b * 0.4).round()),
    ];
  }

  /// Hotspots fijados a la esfera 360 (latitud/longitud). El paquete los
  /// oculta cuando quedan detrás de la cámara.
  List<Hotspot> _buildHotspots(PanoramaModel panorama) {
    final result = <Hotspot>[];
    final guidance = widget.guidance;

    for (final hotspot in panorama.hotspots) {
      // La flecha de guía reemplaza al hotspot del nodo siguiente de la ruta.
      if (guidance != null &&
          guidance.targetNodeId != null &&
          hotspot.targetNodeId == guidance.targetNodeId) {
        continue;
      }
      result.add(
        Hotspot(
          latitude: hotspot.pitch.clamp(-90.0, 90.0).toDouble(),
          longitude: yawToLongitude(hotspot.yaw),
          width: 160,
          height: 160,
          orgin: const Offset(0.5, 0.5),
          widget: Center(child: _buildHotspotButton(hotspot)),
        ),
      );
    }

    final overlaysToShow = widget.overlays ?? OverlayStorage.getOverlaysForNode(panorama.nodeId);
    for (final overlay in overlaysToShow) {
      final anchor = overlayAnchor(yaw: overlay.yaw, pitch: overlay.pitch);
      result.add(
        Hotspot(
          latitude: anchor.$1,
          longitude: anchor.$2,
          width: 240,
          height: 240,
          orgin: const Offset(0.5, 0.5),
          widget: Center(child: _buildOverlayWidget(overlay)),
        ),
      );
    }

    // Flecha de guía del nodo actual (no durante el fade del anterior).
    if (panorama.nodeId == widget.panorama.nodeId && guidance != null) {
      result.add(
        Hotspot(
          latitude: guidance.pitch.clamp(-90.0, 90.0).toDouble(),
          longitude: yawToLongitude(guidance.yaw),
          width: 200,
          height: 220,
          orgin: const Offset(0.5, 0.5),
          widget: Center(child: _buildGuidanceWidget(guidance)),
        ),
      );
    }

    return result;
  }

  Widget _buildGuidanceWidget(GuidanceArrow guidance) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 1.0 + 0.18 * _pulseController.value;
        return Transform.scale(
          scale: pulse,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warningColor.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              if (guidance.label.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    guidance.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEdgeHint() {
    return Positioned.fill(
      child: ValueListenableBuilder<OffscreenDirection?>(
        valueListenable: _edgeHint,
        builder: (context, direction, _) {
          if (direction == null || !direction.outsideView) {
            return const SizedBox.shrink();
          }
          final alignmentX = direction.horizontal == 0
              ? 0.0
              : direction.horizontal.clamp(-0.8, 0.8).toDouble();
          final alignmentY = direction.vertical == 0
              ? 0.0
              : (-direction.vertical).clamp(-0.8, 0.8).toDouble();
          return Align(
            alignment: Alignment(alignmentX, alignmentY),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focusOnGuidance,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulse = 1.0 + 0.22 * _pulseController.value;
                    return Transform.scale(scale: pulse, child: child);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: direction.arrowRotation,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.warningColor.withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          describeGuidanceDirection(direction),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleViewChanged(double longitude, double latitude, double tilt) {
    if (_isTransitioning) return;
    final guidance = widget.guidance;
    if (guidance == null) {
      if (_edgeHint.value != null) _edgeHint.value = null;
      return;
    }
    final direction = computeOffscreenDirection(
      targetYaw: guidance.yaw,
      targetPitch: guidance.pitch,
      viewLongitude: longitude,
      viewLatitude: latitude,
    );
    final previous = _edgeHint.value;
    final changed = previous == null ||
        previous.outsideView != direction.outsideView ||
        previous.horizontal != direction.horizontal ||
        previous.vertical != direction.vertical;
    if (changed) _edgeHint.value = direction;
  }

  Widget _buildOverlayWidget(PanoramaOverlay overlay) {
    final color = Color(overlay.colorValue);
    final scale = overlay.scale;

    return GestureDetector(
      onTap: () {
        if (overlay.action == OverlayAction.navigateToNode &&
            overlay.actionTarget != null) {
          widget.onHotspotTap(overlay.actionTarget!);
        }
      },
      child: Opacity(
        opacity: overlay.opacity,
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: overlay.rotation * 3.14159 / 180,
            child: _buildOverlayContent(overlay, color),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent(PanoramaOverlay overlay, Color color) {
    switch (overlay.type) {
      case OverlayType.arrow:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.arrow_forward, color: Colors.white, size: 22),
              if (overlay.text.isNotEmpty)
                Positioned(
                  bottom: -20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      overlay.text,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
            ],
          ),
        );

      case OverlayType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            overlay.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case OverlayType.button:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                overlay.text,
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
  }

  Widget _buildHotspotButton(HotspotModel hotspot) {
    final isHighlighted = hotspot.targetNodeId == widget.highlightedNodeId;

    return GestureDetector(
      onTap: () => widget.onHotspotTap(hotspot.targetNodeId),
      child: AnimatedContainer(
        duration: AppConstants.defaultAnimationDuration,
        width: isHighlighted ? 56 : 44,
        height: isHighlighted ? 56 : 44,
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppTheme.warningColor
              : AppTheme.hotspotColor.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: isHighlighted ? 12 : 8,
              offset: const Offset(0, 2),
            ),
            if (isHighlighted)
              BoxShadow(
                color: AppTheme.warningColor.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: isHighlighted ? 28 : 22,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionIndicator() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Toca la flecha para navegar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _transitionController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(
              alpha: 0.3 * (1 - _transitionController.value),
            ),
          );
        },
      ),
    );
  }
}