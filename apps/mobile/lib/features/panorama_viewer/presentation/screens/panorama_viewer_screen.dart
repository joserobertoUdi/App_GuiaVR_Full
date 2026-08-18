import 'package:flutter/material.dart';

import 'package:app_guia_ar/core/theme/app_theme.dart';

class PanoramaViewerScreen extends StatelessWidget {
  const PanoramaViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.view_in_ar,
                size: 100,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Visor 360°',
                style: AppTheme.headingLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Esta funcionalidad está en la pestaña "Fase 0"',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Fase 0 - Validación',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usa la pestaña "Fase 0" para probar la navegación 360° con 2 nodos conectados.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
