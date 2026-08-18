/// Acceso a archivos desde el navegador (selección y descarga) de forma
/// condicional: en la web usa `dart:html`, y en el resto de plataformas (p.ej.
/// la VM de `flutter test`) expone implementaciones stub que lanzan error.

// ignore_for_file: dangling_library_doc_comments
export 'web_file_io_stub.dart'
    if (dart.library.html) 'web_file_io_web.dart';