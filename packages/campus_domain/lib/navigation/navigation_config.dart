/// Configuración de navegación que llega a la app móvil vía el bundle.
///
/// Por ahora contiene únicamente el nodo de inicio por defecto que el operador
/// define en el panel de administración: la app lo preselecciona como "punto de
/// inicio" al entrar en la pantalla de planificación de ruta.
class NavigationConfig {
  const NavigationConfig({this.defaultStartNodeId});

  /// Nodo donde la app móvil debe iniciar el recorrido por defecto.
  final String? defaultStartNodeId;

  bool get isEmpty => defaultStartNodeId == null;

  Map<String, dynamic> toJson() => {
        'defaultStartNodeId': defaultStartNodeId,
      };

  static NavigationConfig? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return NavigationConfig(
      defaultStartNodeId: json['defaultStartNodeId'] as String?,
    );
  }

  String describe() {
    return 'Inicio por defecto: ${defaultStartNodeId ?? '—'}';
  }
}