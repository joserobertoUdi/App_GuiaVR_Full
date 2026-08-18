# App Móvil Guía AR Campus

Aplicación Flutter para el usuario final: navegación por el campus mediante fotos
360° con flechas direccionales encadenadas en un grafo de rutas.

Sincroniza **automáticamente** con el backend de push local publicado por el panel
web de administración: al arrancar descarga el bundle (`/api/bundle`) y las imágenes
(`/api/images`) y los aplica a los datos locales sin ningún botón o configuración.

## Funcionalidades

- **Navegación 360°**: visor panorámico con hotspots/flechas y transiciones
  animadas; placeholder dinámico por nodo cuando no hay foto real.
- **Motor de rutas**: BFS + Dijkstra + A* sobre el grafo del campus, con
  instrucciones (bearing, distancia, tiempo) y modos *guiada / rápida / libre*.
- **Posicionamiento del usuario**: escáner QR (`NODE:XXX`, `XXX`, URL `?node=XXX`)
  y selección manual con filtros por piso y zona.
- **Sync transparente**: `CampusSyncService` importa el bundle y descarga solo las
  imágenes que faltan en el almacenamiento local.

## Requisitos

- Flutter ≥ 3.44 stable.
- (Opcional) `adb reverse tcp:8082 tcp:8082` para que el teléfono alcance el
  backend local del PC.

## Ejecutar

```sh
flutter pub get
flutter run                       # emulador/dispositivo
```

## Pruebas

```sh
flutter test && flutter analyze
```

Suite en `test/`: integridad del campus, búsqueda, rutas, geometría panorama,
resolución de guía, overlays, app settings.

## Arquitectura

Ver el README principal del monorepo para el diagrama **web ⇄ backend ⇄ app**.