/// Tipos de contenido que la app móvil puede mostrar como fondo de la
/// pantalla de inicio. Lo configura el operador desde el panel de
/// administración y llega a la app a través del bundle + media del backend.
enum HomeBackgroundType { image, video, carousel, panorama }

/// Configuración del fondo de la pantalla de inicio de la app móvil.
///
/// - [type]: cómo se renderiza el fondo (imagen única, video, carrusel de
///   imágenes o panorama interactivo 360°).
/// - [mediaIds]: identificadores de los archivos de media que el backend
///   sirve en `/api/home-media/<id>` y que la app descarga al sincronizar.
/// - [intervalSeconds]: tiempo entre cambios en modo carrusel.
class HomeBackgroundConfig {
  const HomeBackgroundConfig({
    required this.type,
    required this.mediaIds,
    this.intervalSeconds = 5,
  });

  final HomeBackgroundType type;
  final List<String> mediaIds;
  final int intervalSeconds;

  bool get isEmpty => mediaIds.isEmpty;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'mediaIds': mediaIds,
        'intervalSeconds': intervalSeconds,
      };

  static HomeBackgroundConfig? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final typeName = json['type'] as String?;
    final type = HomeBackgroundType.values.asNameMap()[typeName];
    final ids = (json['mediaIds'] as List?)?.cast<String>() ?? const <String>[];
    if (type == null || ids.isEmpty) return null;
    final interval = (json['intervalSeconds'] as num?)?.toInt() ?? 5;
    return HomeBackgroundConfig(
      type: type,
      mediaIds: ids,
      intervalSeconds: interval < 1 ? 1 : interval,
    );
  }

  String describe() {
    final label = switch (type) {
      HomeBackgroundType.image => 'Imagen',
      HomeBackgroundType.video => 'Video',
      HomeBackgroundType.carousel => 'Carrusel ($intervalSeconds s)',
      HomeBackgroundType.panorama => 'Panorama 360°',
    };
    return '$label · ${mediaIds.length} media';
  }
}