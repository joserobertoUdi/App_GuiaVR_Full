/// Dominio compartido del campus: modelos, repositorio y formato de bundle.
/// Lo usan tanto la app móvil (`apps/mobile`) como la web de administración
/// (`apps/admin_web`). Cambios aquí requieren regenerar dependencias en ambas.
library campus_domain;

export 'models/building_model.dart';
export 'models/campus_model.dart';
export 'models/connection_direction_model.dart';
export 'models/floor_model.dart';
export 'models/node_model.dart';
export 'models/panorama_overlay_model.dart';
export 'models/zone_model.dart';
export 'repository/campus_repository.dart';
export 'bundle/campus_bundle.dart';