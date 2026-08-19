import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:campus_domain/campus_domain.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/core/utils/home_content_storage.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/fase0_test_screen.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/qr_scanner_screen.dart';

/// Pantalla de inicio: una sola vista con fondo dinámico configurable desde el
/// panel de administración (imagen, video, carrusel o panorama 360°) y dos
/// botones inferiores para escanear un QR o iniciar el recorrido. No hay barra
/// de navegación inferior: la única vía a la navegación es "Iniciar recorrido".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  HomeBackgroundConfig? _config;
  final Map<String, Uint8List> _mediaBytes = {};
  VideoPlayerController? _videoController;
  PanoramaController? _panoramaController;
  Timer? _carouselTimer;
  int _carouselIndex = 0;
  bool _loading = true;

  // Slider de panoramas 360°: una vuelta horizontal por imagen y avance.
  AnimationController? _panoTurnController;
  final List<PanoramaController> _retiredPanoramaControllers = [];
  int _panoramaIndex = 0;
  static const Duration _panoTurnFade = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _panoramaController = PanoramaController();
    HomeContentStorage.changes.addListener(_onHomeContentChanged);
    _loadContent();
  }

  @override
  void dispose() {
    HomeContentStorage.changes.removeListener(_onHomeContentChanged);
    _stopPanoramaSlider();
    _carouselTimer?.cancel();
    _videoController?.dispose();
    _panoramaController?.dispose();
    super.dispose();
  }

  void _onHomeContentChanged() {
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Reinicia el estado de media previo antes de recargar.
    _carouselTimer?.cancel();
    _stopPanoramaSlider();
    final oldVideo = _videoController;
    _videoController = null;
    oldVideo?.dispose();

    final config = await HomeContentStorage.loadConfig();
    if (config == null || config.isEmpty) {
      if (!mounted) return;
      setState(() {
        _config = null;
        _mediaBytes.clear();
        _carouselIndex = 0;
        _loading = false;
      });
      return;
    }

    final bytesMap = <String, Uint8List>{};
    for (final id in config.mediaIds) {
      if (config.type == HomeBackgroundType.video) {
        final file = await HomeContentStorage.mediaFile(id, config.type);
        if (file != null && await file.exists()) {
          final video = VideoPlayerController.file(file);
          try {
            await video.initialize();
          } catch (_) {
            video.dispose();
            continue;
          }
          if (mounted && _videoController == null) {
            setState(() {
              _videoController = video;
              _config = config;
              _loading = false;
            });
            await video.setLooping(true);
            await video.play();
          } else {
            video.dispose();
          }
        }
      } else {
        final file = await HomeContentStorage.mediaFile(id, config.type);
        if (file != null && await file.exists()) {
          bytesMap[id] = await file.readAsBytes();
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _config = config;
      _mediaBytes
        ..clear()
        ..addAll(bytesMap);
      _loading = false;
      if (config.type == HomeBackgroundType.carousel &&
          _mediaBytes.length > 1) {
        _startCarousel(config.intervalSeconds);
      }
    });

    // Pre-carga la siguiente imagen del fondo antes de mostrarla.
    if (config.type == HomeBackgroundType.panorama &&
        _mediaBytes.length > 1) {
      _panoramaIndex = 0;
      _startPanoramaSlider(config.intervalSeconds);
      _precachePanorama(_panoramaIndex + 1);
    }
  }

  void _startCarousel(int intervalSeconds) {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) {
        if (!mounted || _mediaBytes.isEmpty) return;
        setState(() {
          _carouselIndex = (_carouselIndex + 1) % _mediaBytes.keys.length;
        });
      },
    );
  }

  // ═══════════════════════════════════════════
  // SLIDER DE PANORAMAS 360°
  // ═══════════════════════════════════════════

  /// Arranca el slider: durante [intervalSeconds] el panorama actual hace una
  /// vuelta horizontal completa (0°→360°) y al terminar avanza al siguiente
  /// con un crossfade suave. La siguiente imagen se pre-carga con anticipación
  /// para que la transición no tenga delay.
  void _startPanoramaSlider(int intervalSeconds) {
    _panoTurnController?.dispose();
    final turn = AnimationController(
      vsync: this,
      duration: Duration(seconds: intervalSeconds),
    );
    turn.addListener(_onPanoramaTurnTick);
    turn.addStatusListener(_onPanoramaTurnStatus);
    _panoTurnController = turn;
    // Cada slide usa su propio controller: durante el crossfade conviven dos
    // PanoramaViewer y un controller compartido haría que ambos giren a la vez.
    _panoramaController?.dispose();
    _panoramaController = PanoramaController()..setView(0, 0);
    turn.forward(from: 0);
  }

  void _stopPanoramaSlider() {
    _panoTurnController?.removeListener(_onPanoramaTurnTick);
    _panoTurnController?.removeStatusListener(_onPanoramaTurnStatus);
    _panoTurnController?.dispose();
    _panoTurnController = null;
    for (final controller in _retiredPanoramaControllers) {
      controller.dispose();
    }
    _retiredPanoramaControllers.clear();
    _panoramaController?.dispose();
    _panoramaController = null;
    _panoramaIndex = 0;
  }

  void _onPanoramaTurnTick() {
    final t = _panoTurnController!.value;
    _panoramaController?.setView(0, 360.0 * t);
  }

  void _onPanoramaTurnStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final keys = _mediaBytes.keys.toList();
    if (keys.length < 2) return;

    final next = (_panoramaIndex + 1) % keys.length;
    // Pre-carga la imagen siguiente a la nueva activa para el fade sin delay.
    _precachePanorama(next + 1);
    if (!mounted) return;

    // El viewer saliente del crossfade conserva su propio controller; se
    // descarta una vez terminada la transición para no acumular listeners.
    final retiring = _panoramaController;
    setState(() {
      _panoramaIndex = next;
      _panoramaController = PanoramaController()..setView(0, 0);
    });
    if (retiring != null) {
      _retiredPanoramaControllers.add(retiring);
      Future<void>.delayed(_panoTurnFade, () {
        final index = _retiredPanoramaControllers.indexOf(retiring);
        if (!mounted || index == -1) return;
        _retiredPanoramaControllers.removeAt(index).dispose();
      });
    }
    _panoTurnController?.forward(from: 0);
  }

  Future<void> _precachePanorama(int index) async {
    final keys = _mediaBytes.keys.toList();
    if (keys.isEmpty) return;
    final bytes = _mediaBytes[keys[index % keys.length]];
    if (bytes == null) return;
    try {
      await precacheImage(MemoryImage(bytes), context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildOverlay(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: _buildTitle(),
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // FONDO
  // ═══════════════════════════════════════════

  Widget _buildBackground() {
    if (_loading) {
      return const ColoredBox(color: Color(0xFF37474F));
    }

    final config = _config;
    if (config == null || config.isEmpty) return _buildDefaultGradient();

    switch (config.type) {
      case HomeBackgroundType.image:
        return _buildImageBackground(_firstBytes());
      case HomeBackgroundType.video:
        return _buildVideoBackground();
      case HomeBackgroundType.carousel:
        return _buildCarouselBackground();
      case HomeBackgroundType.panorama:
        return _buildPanoramaBackground();
    }
  }

  Widget _buildDefaultGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF455A64), Color(0xFF263238)],
        ),
      ),
    );
  }

  Widget _buildImageBackground(Uint8List? bytes) {
    if (bytes == null) return _buildDefaultGradient();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _buildDefaultGradient(),
    );
  }

  Widget _buildVideoBackground() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return _buildDefaultGradient();
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildCarouselBackground() {
    if (_mediaBytes.isEmpty) return _buildDefaultGradient();
    final keys = _mediaBytes.keys.toList();
    final key = keys[_carouselIndex % keys.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: Image.memory(
        _mediaBytes[key]!,
        key: ValueKey(key),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildDefaultGradient(),
      ),
    );
  }

  Widget _buildPanoramaBackground() {
    final keys = _mediaBytes.keys.toList();
    if (keys.isEmpty) return _buildDefaultGradient();
    final key = keys[_panoramaIndex % keys.length];
    final bytes = _mediaBytes[key];
    if (bytes == null) return _buildDefaultGradient();
    return AnimatedSwitcher(
      duration: _panoTurnFade,
      child: PanoramaViewer(
        key: ValueKey(key),
        animSpeed: 0,
        interactive: true,
        sensorControl: SensorControl.none,
        panoramaController: _panoramaController,
        child: Image.memory(
          bytes,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, _, _) => _buildDefaultGradient(),
        ),
      ),
    );
  }

  Uint8List? _firstBytes() {
    return _mediaBytes.values.firstOrNull;
  }

  // ═══════════════════════════════════════════
  // CAPAS SUPUESTAS
  // ═══════════════════════════════════════════

  Widget _buildOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87.withValues(alpha: 0.45),
            Colors.transparent,
            Colors.black87.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'explora y sigue tu camino con nosotros',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              shadows: [
                Shadow(blurRadius: 14, color: Colors.black87),
                Shadow(blurRadius: 4, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _UDIWaveText(),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 380.0 ? 14.0 : 22.0;
    final buttonHeight = (size.height * 0.095).clamp(62.0, 84.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = constraints.maxWidth < 360.0 ? 12.0 : 16.0;
          return Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Escanear QR',
                  icon: Icons.qr_code_scanner,
                  height: buttonHeight,
                  onTap: () => _navigateTo(const QRScannerScreen()),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _buildActionButton(
                  label: 'Iniciar recorrido',
                  icon: Icons.directions_walk,
                  height: buttonHeight,
                  onTap: () => _navigateTo(const Fase0TestScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required double height,
    required VoidCallback onTap,
  }) {
    final red = AppTheme.errorColor.withValues(alpha: 0.92);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 32),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: red,
          elevation: 0,
          shadowColor: Colors.transparent,
          overlayColor: red.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: red.withValues(alpha: 0.45), width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

/// Logotipo "UDI" con ondulación en tonos de rojo: un gradiente oscila
/// horizontalmente como ola de mar sobre el texto, mientras el nivel de rojo
/// sube y baja con un movimiento repetido y suave.
class _UDIWaveText extends StatefulWidget {
  const _UDIWaveText();

  @override
  State<_UDIWaveText> createState() => _UDIWaveTextState();
}

class _UDIWaveTextState extends State<_UDIWaveText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Onda de mar: el foco del gradiente viaja de izquierda a derecha.
        final dx = -1.4 + 2.8 * t;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(dx - 0.9, 0),
            end: Alignment(dx + 0.9, 0),
            colors: const [
              Color(0xFF7A0000),
              Color(0xFFC62828),
              Color(0xFFE53935),
              Color(0xFFFF5252),
              Color(0xFFE53935),
              Color(0xFFC62828),
              Color(0xFF7A0000),
            ],
            stops: const [0.0, 0.25, 0.45, 0.55, 0.65, 0.85, 1.0],
          ).createShader(rect),
          child: Text(
            'UDI',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: 14,
              fontStyle: FontStyle.italic,
              shadows: const [
                Shadow(blurRadius: 24, color: Colors.black87),
                Shadow(
                  blurRadius: 10,
                  color: Color(0x99E53935),
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}