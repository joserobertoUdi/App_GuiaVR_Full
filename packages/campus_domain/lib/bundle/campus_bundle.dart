import 'dart:convert';
import 'package:campus_domain/home/home_background_config.dart';
import 'package:campus_domain/models/campus_model.dart';
import 'package:campus_domain/navigation/navigation_config.dart';

/// Formato de intercambio entre la web de administración y la app móvil.
///
/// El admin web edita el campus y genera un bundle JSON:
/// - `version`: versión del formato de intercambio
/// - `exportedAt`: fecha de exportación
/// - `campus`: campus completo (edificios, pisos, zonas, nodos)
/// - `overlays`: overlays (flechas/textos/botones) agrupados por nodo
/// - `connectionDirections`: direcciones de salida (yaw/pitch) por conexión
///
/// La app móvil importa el bundle con [parse] y lo aplica localmente.
/// Este módulo es el CONTRATO: si cambia, ambas apps deben actualizarse.
class CampusBundle {
  CampusBundle._();

  /// Versión del formato de bundle.
  static const String version = '1.0.0';

  /// Serializa el bundle completo a un string JSON.
  static String buildJson({
    required CampusModel campus,
    Map<String, dynamic> overlays = const {},
    Map<String, dynamic> connectionDirections = const {},
    HomeBackgroundConfig? home,
    NavigationConfig? navigation,
    bool pretty = true,
  }) {
    final data = buildData(
      campus: campus,
      overlays: overlays,
      connectionDirections: connectionDirections,
      home: home,
      navigation: navigation,
    );
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    }
    return json.encode(data);
  }

  /// Construye el mapa del bundle (sin serializar).
  static Map<String, dynamic> buildData({
    required CampusModel campus,
    Map<String, dynamic> overlays = const {},
    Map<String, dynamic> connectionDirections = const {},
    HomeBackgroundConfig? home,
    NavigationConfig? navigation,
  }) {
    return {
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'campus': campus.toJson(),
      'overlays': overlays,
      'connectionDirections': connectionDirections,
      if (home != null) 'home': home.toJson(),
      if (navigation != null) 'navigation': navigation.toJson(),
    };
  }

  /// Analiza un bundle JSON. Lanza [FormatException] si el contenido no es
  /// un bundle válido.
  static CampusBundleData parse(String jsonString) {
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El bundle no es un JSON válido.');
    }
    return parseData(decoded);
  }

  /// Analiza el mapa de un bundle ya decodificado.
  static CampusBundleData parseData(Map<String, dynamic> map) {
    final version = map['version'] as String?;
    if (version == null || version.isEmpty) {
      throw const FormatException('El bundle no tiene versión.');
    }

    final campusJson = map['campus'];
    final CampusModel campus;
    if (campusJson is Map<String, dynamic>) {
      campus = CampusModel.fromJson(campusJson);
    } else {
      campus = const CampusModel(id: 'campus_vacio', name: 'Campus vacío');
    }

    return CampusBundleData(
      version: version,
      campus: campus,
      overlays: (map['overlays'] as Map<String, dynamic>?) ?? const {},
      connectionDirections:
          (map['connectionDirections'] as Map<String, dynamic>?) ?? const {},
      home: HomeBackgroundConfig.fromJson(map['home']),
      navigation: NavigationConfig.fromJson(map['navigation']),
    );
  }

  /// Genera un resumen legible del bundle para mostrar en el admin.
  static String describe(String jsonString) {
    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) return 'Bundle inválido';
      final campus = decoded['campus'] as Map<String, dynamic>?;
      final overlays = decoded['overlays'] as Map<String, dynamic>?;
      final directions = decoded['connectionDirections'] as Map<String, dynamic>?;

      final floors = (campus?['floors'] as List?)?.length ?? 0;
      final zones = (campus?['zones'] as List?)?.length ?? 0;
      final nodes = (campus?['nodes'] as List?)?.length ?? 0;
      final overlayCount =
          overlays?.values.fold<int>(0, (sum, v) => sum + (v as List).length) ?? 0;
      final directionCount =
          directions?.values.fold<int>(0, (sum, v) => sum + (v as List).length) ?? 0;
      final home = HomeBackgroundConfig.fromJson(decoded['home']);
      final navigation = NavigationConfig.fromJson(decoded['navigation']);

      return 'Pisos: $floors | Zonas: $zones | Nodos: $nodes | '
          'Overlays: $overlayCount | Direcciones: $directionCount'
          '${home != null ? ' | Home: ${home.describe()}' : ''}'
          '${navigation != null ? ' | ${navigation.describe()}' : ''}';
    } catch (_) {
      return 'Bundle inválido';
    }
  }
}

/// Resultado de [CampusBundle.parse] con los datos crudos del bundle.
class CampusBundleData {
  final String version;
  final CampusModel campus;
  final Map<String, dynamic> overlays;
  final Map<String, dynamic> connectionDirections;

  /// Fondo de la pantalla de inicio (null si no está publicado).
  final HomeBackgroundConfig? home;

  /// Configuración de navegación (inicio por defecto) del bundle.
  final NavigationConfig? navigation;

  const CampusBundleData({
    required this.version,
    required this.campus,
    required this.overlays,
    required this.connectionDirections,
    this.home,
    this.navigation,
  });
}