import 'package:flutter/material.dart';

import 'package:app_guia_ar/core/theme/app_theme.dart';

class RoutePlannerScreen extends StatelessWidget {
  const RoutePlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planificar Ruta',
                      style: AppTheme.headingMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Punto de inicio',
                        prefixIcon: Icon(Icons.circle_outlined),
                        hintText: 'Selecciona tu ubicación actual',
                      ),
                      readOnly: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Destino',
                        prefixIcon: Icon(Icons.location_on),
                        hintText: '¿A dónde quieres ir?',
                      ),
                      readOnly: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Función en desarrollo'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.route),
                        label: const Text('Calcular Ruta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 80,
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mapa de Ruta',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La ruta aparecerá aquí',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
