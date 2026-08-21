import 'package:flutter/material.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/features/panorama_viewer/presentation/widgets/panorama_viewer_widget.dart';
import 'package:app_guia_ar/features/panorama_viewer/domain/models/panorama_model.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/mock_panoramas_data.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';

/// Pantalla de vista rapida: muestra unicamente el panorama 360 del destino
/// con rotacion automatica lenta. Sin navegacion paso a paso.
class QuickPreviewScreen extends StatefulWidget {
  final String endNodeId;

  const QuickPreviewScreen({super.key, required this.endNodeId});

  @override
  State<QuickPreviewScreen> createState() => _QuickPreviewScreenState();
}

class _QuickPreviewScreenState extends State<QuickPreviewScreen> {
  late final PanoramaModel _panorama;
  late final NodeModel? _destinationNode;

  @override
  void initState() {
    super.initState();
    _panorama = MockPanoramasData.getOrCreateForNode(widget.endNodeId);
    _destinationNode = MockCampusData.getNodeById(widget.endNodeId);
  }

  @override
  Widget build(BuildContext context) {
    final destName = _destinationNode?.destinationLabel ??
        _destinationNode?.name ??
        widget.endNodeId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PanoramaViewerWidget(
            panorama: _panorama,
            onHotspotTap: (_) {},
            enableTransitions: false,
            showDirectionHint: false,
            autoRotateToGuidance: false,
            guidance: null,
            animSpeed: 1.2,
            minZoom: 0.5,
            maxZoom: 5,
          ),
          _buildTopBar(destName),
          _buildBottomLabel(destName),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildTopBar(String destName) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.view_in_ar, color: Colors.white.withValues(alpha: 0.6), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Vista 360 - Vista rapida',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Rapida',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLabel(String destName) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rotate_right, color: Colors.white.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
            Text(
              'Rotacion automatica - $destName',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 6,
      left: 8,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
