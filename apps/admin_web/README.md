# Panel de Administración Web del Campus

Panel de administración en Flutter web para gestionar el campus de la **App Guía AR**.
Es la fuente de verdad: edita el grafo de nodos, posiciona overlays 360° sobre las
fotos panorámicas, y publica el bundle JSON al backend de push local que consume la
app móvil.

## Funcionalidades

- **Estructura**: jerarquía *edificio → piso → zona → nodo* con filtros, ficha del
  nodo y edición/eliminación.
- **Catálogo**: CRUD de pisos, zonas y tipos de nodo (etiquetas/descripciones).
- **Overlays 360°**: editor que coloca flechas, textos y botones sobre la foto
  panorámica (posicionados por yaw/pitch) y define direcciones de salida.
- **Config**: resumen de calidad del campus (`CampusRepository.validate()`),
  preferencias, exportar/importar bundle y **publicar** al backend.

## Requisitos

- Flutter ≥ 3.44 stable.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome --web-port=8080
flutter build web        # producción
```

## Publicar a la app móvil

1. Arranca el backend: `dart run ../tools/backend_server.dart 8082`.
2. En Config → Publicar, fija la URL `http://127.0.0.1:8082` y publica el bundle +
   las imágenes.
3. La app móvil sincroniza automáticamente al arrancar.

## Tests

```sh
flutter test && flutter analyze
```

Los src que usan `dart:html` (selección/descarga de archivos) se resuelven con
stubs en la VM de tests (`web_file_io_stub.dart`, `backend_client_stub.dart`).

## Arquitectura

Ver el README principal del monorepo para el diagrama completo **web ⇄ backend ⇄ app**.