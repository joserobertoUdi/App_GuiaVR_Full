/// Almacenamiento de bytes de imagen de forma condicional:
/// - Web: IndexedDB (cuota de cientos de MB, apta para panoramas 360°).
/// - VM / resto: base64 en `PlatformStorage` (mantiene el comportamiento previo
///   para la VM de tests).
library;

export 'image_byte_store_stub.dart'
    if (dart.library.html) 'image_byte_store_web.dart';