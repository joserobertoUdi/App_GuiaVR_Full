import 'package:campus_domain/campus_domain.dart' as shared;
import 'package:admin_web/features/navigation/data/datasources/mock_campus_data.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/overlay_storage.dart';
import 'package:admin_web/features/panorama_viewer/data/datasources/connection_direction_storage.dart';

/// Enlace entre la web de administración y el bundle que consume la app móvil.
///
/// La web es PRODUCTORA del bundle: parte de los datos locales (campus +
/// overlays + direcciones de conexión) y genera el JSON que el operador
/// exporta y luego importa en la app (`buildBundle`). También permite
/// re-importar un bundle ya generado para seguir editándolo (`importFromBundle`).
/// El formato del bundle lo define `package:campus_domain`.
class CampusBundleExport {
  CampusBundleExport._();

  /// Genera el bundle completo a partir de los datos locales actuales.
  static String buildBundle({
    shared.HomeBackgroundConfig? home,
    shared.NavigationConfig? navigation,
  }) {
    return shared.CampusBundle.buildJson(
      campus: MockCampusData.campus,
      overlays: OverlayStorage.exportToJson(),
      connectionDirections: ConnectionDirectionStorage.exportToJson(),
      home: home,
      navigation: navigation,
    );
  }

  /// Aplica un bundle JSON a los datos locales de la web.
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