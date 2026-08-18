import 'package:flutter/material.dart';

import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/features/navigation/data/repositories/campus_repository.dart';
import 'package:app_guia_ar/features/navigation/domain/models/route_model.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/guided_route_screen.dart';

/// Valida el campus antes de abrir la navegación y, si algo falta,
/// muestra una guía clara con el problema y los pasos para corregirlo.
class RouteReadiness {
  RouteReadiness._();

  /// Calcula la ruta; si falla muestra un diálogo detallado y devuelve `false`.
  /// Si es válida, abre [GuidedRouteScreen] y devuelve `true`.
  static Future<bool> startGuidedRoute(
    BuildContext context, {
    required String startNodeId,
    required String endNodeId,
    RouteMode mode = RouteMode.guidedWalk,
  }) async {
    final repo = MockCampusData.repository;
    final result = repo.findRoute(startNodeId, endNodeId);

    if (result.hasError) {
      await showRouteIssueDialog(
        context,
        error: result.error ?? 'No se pudo calcular la ruta.',
        issues: repo.validate(),
      );
      return false;
    }

    if (!context.mounted) return false;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuidedRouteScreen(
          startNodeId: startNodeId,
          endNodeId: endNodeId,
          mode: mode,
        ),
      ),
    );
    return true;
  }

  static Future<void> showRouteIssueDialog(
    BuildContext context, {
    required String error,
    List<CampusValidationError> issues = const [],
  }) async {
    final critical = issues.where((e) => e.severity == 'error').toList();
    final warnings = issues.where((e) => e.severity == 'warning').toList();

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.route, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No se pudo calcular la ruta',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              if (critical.isNotEmpty || warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Qué falta para corregir:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...critical.take(6).map((e) => _issueTile(Icons.error, AppTheme.errorColor, e.message)),
                ...warnings.take(4).map((e) => _issueTile(Icons.warning_amber, AppTheme.warningColor, e.message)),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Los datos del campus se ven correctos. Verifica que inicio y destino sean nodos diferentes y con zona asignada.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static Widget _issueTile(IconData icon, Color color, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}
