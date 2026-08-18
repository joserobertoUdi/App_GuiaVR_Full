# App Guía AR Campus — Navegación 360° para Campus Universitario

Monorepo de **Flutter** con tres piezas que trabajan juntas: una **app móvil** para
el usuario final, un **panel de administración web** para gestionar el campus y un
**backend local de push** que transporta el contenido publicado desde el web hasta
la app móvil. Todo comparte el dominio y el formato de intercambio de datos en el
paquete `packages/campus_domain`.

```
App_GuiaAR/
├── packages/
│   └── campus_domain/        # ⚙️ Contrato compartido (Clean Architecture):
│                             #   modelos, CampusRepository y CampusBundle (JSON).
├── apps/
│   ├── mobile/               # 📱 App Flutter del usuario final (guía/navegación).
│   └── admin_web/            # 🖥️ Panel web de administración (Flutter web).
├── tools/
│   ├── backend_server.dart   # 🔌 Backend de push local (HTTP, puerto 8082).
│   ├── push_simulator.dart   # 🧪 Simulador E2E que publica un bundle de prueba.
│   └── e2e_panos/            # Imágenes panorámicas para pruebas E2E.
└── docs/                     # 📚 Documentación técnica y changelog.
```

---

## 1. Problemática

Orientarse dentro de un campus universitario (edificios de varios pisos, aulas y
laboratorios distribuidos en pasillos) es difícil para estudiantes y visitantes:
- Los mapas 2D no reflejan el entorno real a la altura de los ojos.
- Los buscadores GPS pierden precisión en interiores.
- La información de las instalaciones cambia constantemente (aulas, accesos,
  señales) y actualizarla requiere personal técnico.

La idea es **replicar la experiencia de navegación de un tour virtual 360°**
(street‑view del interior): el usuario se mueve entre "fotos esféricas" tomadas en
puntos clave del campus (nodos), y cada foto muestra **flechas direccionales** que
lo guían hacia el siguiente nodo hasta llegar a su destino.

### Problemas concretos que resolvimos
1. **Crear y mantener el mapa del campus** sin escribir código: un panel web que
   modela la jerarquía *edificio → piso → zona → nodo*, valida la integridad del
   grafo y edita las flechas sobre la foto 360°.
2. **Llevar el contenido al teléfono**: un formato de intercambio (`CampusBundle`)
   que serializa todo el campus (nodos, conexiones, overlays 360° y direcciones), y
   un backend de push local que lo publica; la app móvil lo descarga y aplica solo.
3. **Calcular rutas reales**: Dijkstra/A*/BFS sobre el grafo de nodos para mostrar
   la ruta más corta entre dos puntos del campus.
4. **Posicionar al usuario** en el edificio: escaneo de QR y selección manual.

---

## 2. Solución: arquitectura de la solución (app ⇄ back ⇄ web)

El sistema se divide en **web** (autoría), **backend** (transporte) y **app**
(consumo). El paquete `campus_domain` es el **contrato** que une los tres.

### 2.1 Diagrama de flujo

```
┌──────────────────────┐        PUT /api/bundle         ┌──────────────────────┐
│   admin_web (Flutter)│ ─────────────────────────────▶ │  BACKEND (Dart)      │
│  panel de admin      │   PUT /api/images/<nodeId>     │  tools/backend_server│
│  edición + overlays  │                                │  HTTP puerto 8082    │
│  exportar/publicar   │                                │  persiste en         │
│                      │          ping                  │  tools/backend_data/ │
└──────────────────────┘        GET /api/health  ◀──────└──────────┬───────────┘
         │                                                            │
         │  (mismo código compartido)                                 │ GET /api/bundle
         ▼                                                            ▼ GET /api/images
┌─────────────────────────────────────────┐                ┌──────────────────────┐
│  packages/campus_domain (contrato)      │                │   mobile (Flutter)   │
│  modelos + CampusRepository +           │                │  arranque: sync      │
│  CampusBundle.parse/buildJson           │                │  importa bundle e    │
│  (version, exportedAt, campus,          │                │  imágenes, aplica    │
│  overlays, connectionDirections)        │                │  local, sin botones  │
└─────────────────────────────────────────┘                └──────────────────────┘
```

### 2.2 Las tres piezas

#### a) `apps/admin_web` — Panel de administración (FUENTE DE VERDAD)
Flutter web que edita el campus y genera el bundle JSON.

- **Estructura**: jerarquía *edificio → piso → zona → nodo* con filtros por piso y zona.
- **Catálogo** (`catalog_tab.dart`): CRUD de pisos, zonas y tipos de nodo
  (`NodeTypeSettings` persiste etiquetas en `PlatformStorage`).
- **Editor de overlays 360°** (`overlay_editor_screen.dart`): coloca flechas,
  textos y botones sobre la foto panorámica (posicionados por yaw/pitch vía
  `panorama_geometry.dart`), y define las direcciones de salida por conexión.
- **Publicar**: envía el bundle y las imágenes al backend (`backend_client.dart`).
- **Importar/exportar** el bundle como archivo (`campus_bundle_export.dart`).

#### b) `tools/backend_server.dart` — Backend de push local (TRANSPORTE)
Servidor HTTP mínimo en Dart puro (sin dependencias externas):

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/health` | GET | estado del servicio |
| `/api/bundle` | GET/PUT | leer / publicar el bundle JSON |
| `/api/bundle/version` | GET | versión y resumen del bundle |
| `/api/images` | GET | lista de `nodeId` con imagen |
| `/api/images/<nodeId>` | GET/PUT | leer / publicar imagen de un nodo |

Persiste en `tools/backend_data/` (bundle.json + imágenes `.img`) y responde CORS
para que la web (otro origen) pueda publicar.

#### c) `apps/mobile` — App móvil (CONSUMIDOR)
App Flutter del usuario final:
- **Sincronización automática**: al arrancar consulta `/api/bundle` y `/api/images`.
  Si hay un bundle nuevo, lo aplica con `CampusBundleExport.importFromBundle` y
  descarga las imágenes solo si no existen en `LocalImageStorage`
  (`campus_sync_service.dart`). Es transparente: no hay botones.
- **Navegación 360°**: visor `panorama_viewer` con hotspots/flechas, transiciones
  cross‑fade y placeholders dinámicos por nodo.
- **Motor de rutas**: BFS + Dijkstra + A* (`graph_utils.dart`), instrucciones de
  navegación (bearing, distancia, tiempo) y modos *guiada / rápida / libre*.
- **Posicionamiento**: escáner QR (`NODE:XXX`, `XXXX` o URL `?node=`) y selección
  manual con filtros por piso y zona.

### 2.3 El contrato: `packages/campus_domain`

- **Modelos**: `CampusModel`, `BuildingModel`, `FloorModel`, `ZoneModel`,
  `NodeModel`, `PanoramaOverlayModel`, `ConnectionDirectionModel`.
- **`CampusRepository`**: CRUD con validación, búsqueda y cálculo de rutas
  (incluye `validate()` que reporta nodos aislados, conexiones unidireccionales,
  zonas sin entrada/salida, referencias rotas, etc.).
- **`CampusBundle`**: formato JSON de intercambio:
  `version`, `exportedAt`, `campus`, `overlays`, `connectionDirections`.
  **Si cambia este formato, web y móvil deben actualizarse a la vez.**

> Los tests de integridad (`campus_integrity_test.dart`, `node_search_test.dart`,
> `route_calculation_test.dart`) validan que las tres piezas usan el mismo contrato.

---

## 3. Guía de funcionamiento

### 3.1 Requisitos
- Flutter ≥ 3.44 stable (Dart ≥ 3.12) en `PATH`.
- Un dispositivo/emulador Android o un navegador Chrome.
- (Opcional) teléfono conectado vía `adb reverse tcp:8082 tcp:8082` para que la
  app móvil alcance el backend local del PC.

### 3.2 Ejecutar el backend de push
```sh
cd tools
dart run backend_server.dart 8082
# Backend Push corriendo en http://0.0.0.0:8082
```

### 3.3 Ejecutar la web de administración
```sh
cd apps/admin_web
flutter pub get
flutter run -d chrome --web-port=8080     # desarrollo
flutter build web                          # producción (build/web)
```
En la pestaña **Config → Publicar** indica la URL del backend
(`http://127.0.0.1:8082`) y publica el bundle + imágenes.

### 3.4 Ejecutar la app móvil
```sh
cd apps/mobile
flutter pub get
flutter run                                # emulador/dispositivo
```
Al arrancar sincroniza automáticamente con el backend. Para probar las rutas:
**Inicio → buscar destino → Ruta Guiada/Rápida**, o **Visor 360° → selección manual/QR**.

### 3.5 Modo rápido E2E (sin interacción manual)
```sh
# 1) arranca el backend
dart run tools/backend_server.dart 8082
# 2) publica un campus de prueba (edificio Push E2E con 3 nodos y panoramas)
dart run tools/push_simulator.dart http://127.0.0.1:8082
```
El simulador usa el **mismo** `CampusBundle.buildJson` y los **mismos** endpoints
que la web, así valida el contrato completo publicar→descargar→aplicar.

---

## 4. Guía de pruebas

### 4.1 Tests unitarios
```sh
# Web de administración
cd apps/admin_web && flutter test && flutter analyze

# App móvil
cd apps/mobile && flutter test && flutter analyze
```

Suite de la app móvil (`apps/mobile/test/`):

| Archivo | Cobertura |
|---|---|
| `campus_integrity_test.dart` | integridad del grafo y del bundle |
| `node_search_test.dart` | búsqueda por ID/nombre/piso/destino |
| `route_calculation_test.dart` | rutas BFS/Dijkstra, instrucciones, cruces de piso |
| `panorama_geometry_test.dart` | proyección yaw/pitch ↔ pantalla |
| `guidance_resolver_test.dart` | resolución de flechas de guía |
| `overlay_storage_test.dart` / `app_settings_test.dart` | persistencia local |
| `node_selector_test.dart` / `offscreen_direction_test.dart` | selección y señales |

> Los tests del web corren en la VM, por lo que `dart:html` (selección de archivos,
> descarga) se resuelve con stubs que lanzan `UnsupportedError` en tests
> (`backend_client_stub.dart`, `web_file_io_stub.dart`).

### 4.2 Prueba funcional manual (loop completo)
1. **Backend**: `dart run tools/backend_server.dart 8082`.
2. **Web**: `cd apps/admin_web && flutter run -d chrome --web-port=8080`.
3. En la web: crea/edita nodos, en el editor de overlays coloca flechas y
   direcciones de salida, y en **Config → Publicar** envía el bundle al backend.
4. **Móvil**: arranca la app; en **Inicio → Navegar** busca un destino y sigue la
   ruta guiada a través de los panoramas con flechas.
5. Verifica: el bundle llega sin interacción (sincronización automática), las
   imágenes se descargan, los nodos se muestran con sus overlays, y los QR
   (`NODE:ENTRADA`, `ENTRADA`, o URL con `?node=ENTRADA`) posicionan al usuario.

### 4.3 Escenarios críticos que validar
- **Grafo**: nodo aislado sin conexiones, conexión unidireccional, zona sin
  nodo entrada/salida → el web los detecta en `CampusRepository.validate()`.
- **Bundle**: versión incompatible entre web y móvil → `CampusBundle.parse` lanza
  `FormatException`.
- **Imágenes**: nodo sin foto → placeholder dinámico; con foto → se muestra y se
  usa en el editor de overlays para posicionar flechas.
- **Sincronización**: apagar el backend → la app funciona con datos locales;
  encenderlo y publicar un bundle nuevo → la app lo detecta al reiniciar.

---

## 5. Documentación adicional

| Documento | Contenido |
|---|---|
| `docs/DOCUMENTACION_PROYECTO.md` | arquitectura, fases del roadmap, dependencias, tests |
| `docs/CHANGELOG.md` | historial de funcionalidades |
| `docs/PROTOCOLO_CAPTURA.md` | guía para capturar fotos 360° reales |
| `docs/campus_schema.json` | esquema del data model del campus |
| `roadmap-navegacion-360-campus.md` | roadmap del producto por fases |

## 6. Stack

- **Flutter / Dart** (3.44 / 3.12) en las tres piezas.
- **Flutter web** para el panel de admin; **Dart puro + `dart:io`** para el backend.
- **Riverpod**, **get_it**, **equatable** para estado y DI.
- **panorama_viewer** para el visor 360°, **mobile_scanner** para QR,
  **geolocator**/GPS, **shared_preferences**/archivos para persistencia local.
- **Clean Architecture + SOLID** a nivel del dominio compartido y por feature.

---

## 7. Convenciones

- UI y comentarios en **español**; imports con `package:<app>/...`.
- IDs de nodos: `P01`–`P09` para pasillos, `P_AULA_XXX` para aulas.
- Modelos con `Equatable`, `copyWith()` y serialización JSON.
- Antes de cada cambio estructural: `CampusRepository.validate()`.