import 'package:flutter/material.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';
import 'package:app_guia_ar/core/constants/app_constants.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/fase0_test_screen.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/qr_scanner_screen.dart';
import 'package:app_guia_ar/features/navigation/presentation/screens/manual_location_screen.dart';
import 'package:app_guia_ar/features/panorama_viewer/presentation/screens/panorama_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Navegar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'Visor 360°',
          ),
        ],
      ),
    );
  }

  List<Widget> get _screens => [
    _buildHomeTab(),
    const Fase0TestScreen(),
    const PanoramaViewerScreen(),
  ];

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildLocationMethods(),
          const SizedBox(height: 24),
          _buildRecentRoutes(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_in_ar, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Navegación 360° Campus',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Explora el campus de forma interactiva',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acceso Rápido',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Escanear QR',
                subtitle: 'Identificar nodo',
                color: Colors.blue,
                onTap: () => _navigateTo(const QRScannerScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.location_searching,
                title: '¿Dónde estoy?',
                subtitle: 'Selección manual',
                color: Colors.green,
                onTap: () => _navigateTo(const ManualLocationScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métodos de Posicionamiento',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 12),
            _buildMethodTile(
              icon: Icons.qr_code,
              title: 'Código QR',
              description: 'Escanea el código en el nodo para identificar tu posición exacta',
              isAvailable: true,
            ),
            const Divider(),
            _buildMethodTile(
              icon: Icons.touch_app,
              title: 'Selección Manual',
              description: 'Selecciona tu ubicación actual en la lista de nodos',
              isAvailable: true,
            ),
            const Divider(),
            _buildMethodTile(
              icon: Icons.gps_fixed,
              title: 'GPS (Exteriores)',
              description: 'Detección automática por GPS en zonas abiertas',
              isAvailable: false,
            ),
            const Divider(),
            _buildMethodTile(
              icon: Icons.bluetooth,
              title: 'BLE Beacons',
              description: 'Señales Bluetooth para interior (requiere hardware)',
              isAvailable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile({
    required IconData icon,
    required String title,
    required String description,
    required bool isAvailable,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isAvailable
              ? AppTheme.successColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isAvailable ? AppTheme.successColor : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isAvailable ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: isAvailable ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAvailable
              ? AppTheme.successColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isAvailable ? 'Disponible' : 'Próximamente',
          style: TextStyle(
            fontSize: 10,
            color: isAvailable ? AppTheme.successColor : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRoutes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rutas Recientes',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 12),
            _buildRouteTile(
              from: 'Entrada Principal',
              to: 'Aula 204',
              time: '2 min',
            ),
            const Divider(),
            _buildRouteTile(
              from: 'Escalera P2',
              to: 'Aula 101',
              time: '1 min',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTile({
    required String from,
    required String to,
    required String time,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.history,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        '$from → $to',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Tiempo estimado: $time',
        style: AppTheme.bodySmall,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acerca de',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Aplicación de navegación interactiva 360° para campus universitario. '
              'Explora el edificio usando fotos panorámicas con hotspots de navegación.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('v${AppConstants.appVersion}', Icons.info_outline),
                const SizedBox(width: 8),
                _buildInfoChip('Flutter', Icons.flutter_dash),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
