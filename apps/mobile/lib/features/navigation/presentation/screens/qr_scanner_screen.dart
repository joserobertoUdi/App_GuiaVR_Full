import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/features/navigation/presentation/utils/route_readiness.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/core/utils/app_notifications.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    final nodeId = _parseNodeId(barcode.rawValue!);
    if (nodeId != null) {
      final node = MockCampusData.getNodeById(nodeId);
      if (node != null) {
        _showNodeDetectedDialog(node);
      } else {
        _showError('Nodo no encontrado: $nodeId');
      }
    } else {
      _showError('Código QR no válido para navegación');
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  String? _parseNodeId(String qrData) {
    final data = qrData.trim().toUpperCase();

    if (data.startsWith('NODE:')) {
      return data.substring(5);
    }

    if (RegExp(r'^[A-Z0-9_]+$').hasMatch(data) && data.length >= 2) {
      return data;
    }

    try {
      final uri = Uri.parse(qrData);
      if (uri.queryParameters.containsKey('node')) {
        return uri.queryParameters['node'];
      }
    } catch (_) {}

    return null;
  }

  void _showNodeDetectedDialog(NodeModel node) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: AppTheme.successColor, size: 48),
        title: Text(' Nodo Detectado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.name,
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${node.id} • Piso ${node.floorLevel}',
              style: AppTheme.bodySmall,
            ),
            if (node.hasDestination) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.destinationLabel!,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '¿Quieres iniciar la navegación desde aquí?',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Escanear de nuevo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDestinationSelector(node);
            },
            child: const Text('Seleccionar destino'),
          ),
        ],
      ),
    );
  }

  void _showDestinationSelector(NodeModel startNode) {
    final destinations = MockCampusData.getDestinations();

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
                  final isSameNode = dest.id == startNode.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSameNode
                          ? Colors.grey
                          : AppTheme.primaryColor,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(dest.destinationLabel ?? dest.name),
                    subtitle: Text('Piso ${dest.floorLevel}'),
                    trailing: isSameNode
                        ? null
                        : Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: isSameNode
                        ? null
                        : () {
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

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    AppNotifications.showError(
      context,
      title: 'Error de escaneo',
      description: message,
      retryLabel: 'Reintentar',
      onRetry: _resetScanner,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Escanear QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController?.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildScanOverlay(),
          _buildInstructions(),
          if (_isProcessing) _buildProcessingIndicator(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_scannerController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return MobileScanner(
      controller: _scannerController!,
      onDetect: _onDetect,
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -1,
              left: -1,
              right: -1,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.5),
                      AppTheme.primaryColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Apunta al código QR del nodo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El código contiene la información del punto de navegación',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Procesando código...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
