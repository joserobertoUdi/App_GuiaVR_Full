// Cliente HTTP hacia el backend de push local.
// En el navegador usa `dart:html`; en la VM de tests expone stubs que lanzan
// UnsupportedError (publicación solo disponible dentro del navegador).
export 'backend_client_stub.dart'
    if (dart.library.html) 'backend_client_web.dart';