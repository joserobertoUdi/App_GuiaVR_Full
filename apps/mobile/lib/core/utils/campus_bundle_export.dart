import 'package:campus_domain/campus_domain.dart' as shared;
import 'package:app_guia_ar/core/utils/home_content_storage.dart';
import 'package:app_guia_ar/core/utils/navigation_settings.dart';
import 'package:app_guia_ar/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/overlay_storage.dart';
import 'package:app_guia_ar/features/panorama_viewer/data/datasources/connection_direction_storage.dart';

/// Enlace entre la app móvil y el bundle generado por la web de administración.
///
/// La app es consumidora del bundle: recibe el JSON exportado por el admin
/// (`importFromBundle`) y lo aplica localmente (campus + overlays + direcciones).
/// El formato del bundle lo define `package:campus_domain`.
class CampusBundleExport {
  CampusBundleExport._();

  /// Aplica un bundle JSON generado por la web de administración.
  /// Devuelve `true` si fue exitoso, `false` si el JSON es inválido.
  static bool importFromBundle(String jsonString) {
    try {
      final data = shared.CampusBundle.parse(jsonString);

      if (data.campus.nodes.isNotEmpty || data.campus.zones.isNotEmpty) {
        MockCampusData.repository.updateCampus(data.campus);
        MockCampusData.saveToFile();
      }

      if (data.overlays.isNotEmpty) {
        OverlayStorage.importFromJson(data.overlays);
      }

      if (data.connectionDirections.isNotEmpty) {
        ConnectionDirectionStorage.importFromJson(data.connectionDirections);
      }

      final home = data.home;
      if (home != null) {
        HomeContentStorage.saveConfig(home);
      }

      final navigation = data.navigation;
      NavigationSettings.applyNavigationConfig(navigation);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Genera un resumen legible del bundle para mostrar en el admin.
  static String describeBundle(String jsonString) {
    return shared.CampusBundle.describe(jsonString);
  }
}