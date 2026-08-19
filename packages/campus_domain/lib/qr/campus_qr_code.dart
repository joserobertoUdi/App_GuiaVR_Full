/// Código QR de ubicación del campus.
///
/// Formato seguro con delimitadores `* ... *`: impide lecturas parciales o
/// duplicados accidentales, y permite al escáner reconocer el patrón de forma
/// inequívoca. Cada QR codifica DOS identificadores redundantes:
///   - `id`   → referencia técnica (ej: `z_aulas_p1`, `P01`, `piso_1`)
///   - `name` → nombre legible (ej: `Aulas P1`, `Entrada Principal`)
///
/// Si el `id` no se encuentra, el lector puede resolver por `name`, y viceversa.
///
/// El tipo (`building` | `floor` | `zone` | `node`) define qué entidad del
/// campus referencia el QR, con prefijos de una letra:
///   - `B` → edificio (building)
///   - `F` → piso (floor)
///   - `Z` → zona (zone)
///   - `N` → nodo (node)
///
/// Ejemplo (zona): `* Z:z_aulas_p1|Aulas P1 *`
/// Ejemplo (nodo): `* N:P01|Entrada Principal *`
///
/// Este módulo vive en el dominio compartido para que la web de administración
/// (generación) y la app móvil (escaneo) usen exactamente el mismo formato.
library;

enum CampusQrEntityType { building, floor, zone, node }

class CampusQrReference {
  final CampusQrEntityType type;
  final String id;
  final String name;

  const CampusQrReference({
    required this.type,
    required this.id,
    required this.name,
  });

  @override
  String toString() => 'CampusQrReference(${type.name}, $id, $name)';

  @override
  bool operator ==(Object other) =>
      other is CampusQrReference &&
      other.type == type &&
      other.id == id &&
      other.name == name;

  @override
  int get hashCode => Object.hash(type, id, name);
}

class CampusQrCode {
  CampusQrCode._();

  /// Letra prefijo por tipo.
  static String prefixFor(CampusQrEntityType type) {
    switch (type) {
      case CampusQrEntityType.building:
        return 'B';
      case CampusQrEntityType.floor:
        return 'F';
      case CampusQrEntityType.zone:
        return 'Z';
      case CampusQrEntityType.node:
        return 'N';
    }
  }

  static CampusQrEntityType? typeForPrefix(String prefix) {
    switch (prefix.toUpperCase()) {
      case 'B':
        return CampusQrEntityType.building;
      case 'F':
        return CampusQrEntityType.floor;
      case 'Z':
        return CampusQrEntityType.zone;
      case 'N':
        return CampusQrEntityType.node;
      default:
        return null;
    }
  }

  /// Codifica una referencia en el formato `* T:id|nombre *`.
  static String encode(CampusQrReference ref) {
    final prefix = prefixFor(ref.type);
    return '* $prefix:${ref.id}|${ref.name} *';
  }

  /// Intenta decodificar un valor escaneado al formato `* T:id|nombre *`.
  ///
  /// Tolerante a espacios y a que el delimitador se reciba completo o sin él
  /// (compatibilidad con códigos `NODE:...` o IDs planos). Devuelve `null` si
  /// el valor no se reconoce.
  static CampusQrReference? parse(String raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    var s = raw.trim();

    // Quitar asteriscos envolventes si existen.
    final wasFramed = s.startsWith('*') && s.endsWith('*');
    if (wasFramed) {
      s = s.substring(1, s.length - 1).trim();
    }

    // Detectar prefijo de tipo: "T:" al inicio del contenido.
    final prefixMatch =
        RegExp(r'^([BZFN])[:]\s*(.+)$', caseSensitive: false).firstMatch(s);
    if (prefixMatch != null) {
      final type = typeForPrefix(prefixMatch.group(1)!);
      final rest = prefixMatch.group(2)!.trim();
      if (type == null || rest.isEmpty) return null;

      final sepIndex = rest.indexOf('|');
      if (sepIndex < 0) {
        // Sin "|": asumimos que el contenido completo es el id (sin nombre).
        return CampusQrReference(type: type, id: rest, name: '');
      }
      final id = rest.substring(0, sepIndex).trim();
      final name = rest.substring(sepIndex + 1).trim();
      if (id.isEmpty) return null;
      return CampusQrReference(type: type, id: id, name: name);
    }

    // Sin prefijo: compatibilidad con formatos previos.
    if (s.toUpperCase().startsWith('NODE:')) {
      return CampusQrReference(
        type: CampusQrEntityType.node,
        id: s.substring(5).trim(),
        name: '',
      );
    }

    if (RegExp(r'^[A-Za-z0-9_]+$').hasMatch(s)) {
      return CampusQrReference(
        type: CampusQrEntityType.node,
        id: s,
        name: '',
      );
    }

    try {
      final uri = Uri.parse(raw);
      if (uri.queryParameters.containsKey('node')) {
        return CampusQrReference(
          type: CampusQrEntityType.node,
          id: uri.queryParameters['node'] ?? '',
          name: '',
        );
      }
    } catch (_) {}

    return null;
  }
}