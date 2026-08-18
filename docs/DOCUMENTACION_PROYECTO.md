# Documentación del Proyecto: Guía AR Campus

## Índice
1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Información del Proyecto](#2-información-del-proyecto)
3. [Estructura del Proyecto](#3-estructura-del-proyecto)
4. [Validación de Fases del Roadmap](#4-validación-de-fases-del-roadmap)
5. [Funcionalidades Implementadas](#5-funcionalidades-implementadas)
6. [Dependencias y Tecnologías](#6-dependencias-y-tecnologías)
7. [Arquitectura y Diseño](#7-arquitectura-y-diseño)
8. [Tests Unitarios](#8-tests-unitarios)
9. [Estado de Implementación](#9-estado-de-implementación)
10. [Próximos Pasos](#10-próximos-pasos)

---

## 1. Resumen Ejecutivo

**App de Navegación Interactiva 360° para Campus Universitario** — Aplicación móvil en Flutter que permite a estudiantes y visitantes navegar el campus mediante fotos 360° con hotspots direccionales, encadenados en un grafo de rutas.

**Estado actual:** Fases 0-3 parcialmente completadas. MVP funcional con navegación por hotspots, cálculo de rutas, posicionamiento por QR y selección manual.

---

## 2. Información del Proyecto

| Campo | Valor |
|-------|-------|
| **Nombre** | `app_guia_ar` |
| **Versión** | 1.0.0+1 |
| **Plataformas** | Android, iOS, macOS, Linux, Web, Windows |
| **SDK Dart** | ^3.12.2 |
| **Flutter** | 3.44.2 stable |
| **Arquitectura** | Clean Architecture + SOLID |
| **Paquete** | `com.guiaar.app_guia_ar` |

---

## 3. Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada
├── app.dart                           # MaterialApp configuration
├── config/
│   └── firebase_options.dart          # Configuración Firebase (placeholder)
├── core/
│   ├── constants/app_constants.dart   # Constantes globales
│   ├── theme/app_theme.dart           # Tema Material 3
│   ├── di/dependency_injection.dart   # Inyección de dependencias (get_it)
│   ├── errors/app_exceptions.dart     # Jerarquía de excepciones
│   └── utils/
│       ├── graph_utils.dart           # Dijkstra y A*
│       └── location_utils.dart        # Cálculos GPS/Haversine
├── features/
│   ├── navigation/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── node_model.dart    # Modelo de nodo de navegación
│   │   │   │   └── route_model.dart   # Modelo de ruta con pasos
│   │   │   └── repositories/
│   │   │       ├── node_repository.dart
│   │   │       └── route_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── mock_campus_data.dart    # Datos mock campus (12 nodos)
│   │   │   │   └── mock_nodes_data.dart     # Datos mock simples (4 nodos)
│   │   │   └── repositories_impl/
│   │   │       └── node_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── home_screen.dart              # Inicio con pestañas
│   │       │   ├── fase0_test_screen.dart        # Selección de ruta
│   │       │   ├── navigation_screen.dart        # Navegación libre
│   │       │   ├── guided_route_screen.dart      # Ruta guiada/preview
│   │       │   ├── admin_screen.dart             # Panel administración
│   │       │   ├── qr_scanner_screen.dart        # Escáner QR
│   │       │   └── manual_location_screen.dart   # Selección manual
│   │       ├── widgets/
│   │       │   ├── route_info_widget.dart
│   │       │   └── navigation_controls_widget.dart
│   │       └── providers/
│   │           └── guided_route_provider.dart
│   ├── panorama_viewer/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── panorama_model.dart   # Modelo de panorama 360°
│   │   │   │   └── hotspot_model.dart    # Modelo de hotspot
│   │   │   ├── repositories/
│   │   │   │   └── panorama_repository.dart
│   │   │   └── usecases/
│   │   │       └── navigation_usecases.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── mock_panoramas_data.dart  # Panoramas mock (12)
│   │   │   └── repositories_impl/
│   │   │       └── panorama_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── panorama_viewer_screen.dart
│   │       ├── widgets/
│   │       │   └── panorama_viewer_widget.dart  # Visor 360° core
│   │       └── providers/
│   │           └── panorama_navigation_provider.dart
│   ├── location/
│   │   ├── domain/
│   │   │   ├── models/location_model.dart
│   │   │   └── repositories/location_repository.dart
│   │   └── presentation/
│   │       └── screens/location_screen.dart
│   └── route_engine/
│       ├── domain/
│       │   ├── models/graph_model.dart
│       │   └── repositories/graph_repository.dart
│       └── presentation/
│           └── screens/route_planner_screen.dart
test/
├── node_search_test.dart        # 10 tests de búsqueda de nodos
└── route_calculation_test.dart  # 14 tests de cálculo de rutas
```

---

## 4. Validación de Fases del Roadmap

### FASE 0 — Validación ✅ COMPLETADA

| Punto del Roadmap | Estado | Evidencia |
|---|---|---|
| Elegir edificio/zona pequeña como piloto | ✅ | `MockCampusData` define "Edificio A" con 2 pisos |
| Definir 5-8 nodos clave | ✅ | 12 nodos definidos en `mock_campus_data.dart` (P01-P09 + P_AULA_101/201/204) |
| Prototipo con `panorama_viewer` mostrando 2 nodos conectados | ✅ | `NavigationScreen` y `GuidedRouteScreen` implementan esto |
| Botón "siguiente" (sin transición animada) | ✅ | Hotspots en `PanoramaViewerWidget` permiten navegar entre nodos |

**Criterio de éxito:** La app permite navegar entre nodos usando fotos 360° + flechas → **VALIDADO**

---

### FASE 1 — Diseño de la Experiencia ✅ COMPLETADA

| Punto del Roadmap | Estado | Evidencia |
|---|---|---|
| Mapear grafo completo del campus | ✅ | `MockCampusData.allNodes` con 12 nodos y conexiones bidireccionales |
| Definir lenguaje visual (flechas, colores, iconos) | ✅ | `AppTheme` con colores específicos: hotspot=amber, route=blue, error=red, success=green |
| Diseñar flujo de UI: búsqueda → cálculo → reproducción → llegada | ✅ | `Fase0TestScreen` → `GuidedRouteScreen` con progreso y banner de llegada |
| Diseñar posicionamiento de usuarios | ✅ | Implementado en `QRScannerScreen` y `ManualLocationScreen` |

---

### FASE 2 — Captura de Contenido ⚠️ PARCIAL

| Punto del Roadmap | Estado | Evidencia |
|---|---|---|
| Definir protocolo de captura | ⏳ | Pendiente (requiere decisiones de hardware) |
| Capturar fotos 360° en cada nodo | ⏳ | Solo placeholders generados (`tools/generate_placeholders.dart`) |
| Procesar/editar contenido | ⏳ | Pendiente |
| Etiquetar nodos con coordenadas GPS | ✅ | `NodeModel` incluye `latitude`, `longitude`, `heading` |
| Subir a almacenamiento | ⏳ | Firebase Storage configurado pero no conectado |

---

### FASE 3 — Desarrollo Técnico MVP ✅ COMPLETADA

#### 3.1 Visor 360° y Transiciones ✅

| Punto | Estado | Archivo |
|---|---|---|
| Implementar `panorama_viewer` para fotos 360° | ✅ | `panorama_viewer_widget.dart` usa `PanoramaViewer` |
| Hotspots tocables sobre la esfera | ✅ | `_buildHotspotOverlays()` calcula posición yaw/pitch |
| Transición cross-fade/zoom simple | ✅ | `AnimatedBuilder` con `_fadeAnimation` y `_scaleAnimation` |

#### 3.2 Motor de Rutas ✅

| Punto | Estado | Archivo |
|---|---|---|
| Modelar campus como grafo (nodos + aristas) | ✅ | `MockCampusData.allNodes` con `connectedNodeIds` |
| Implementar Dijkstra o A* | ✅ | `graph_utils.dart` con ambos algoritmos |
| Calcular ruta más corta | ✅ | `MockCampusData.findRoute()` usa BFS, `calculateRoute()` genera `RouteModel` |
| Traducir secuencia a lista de hotspots | ✅ | `GuidedRouteScreen` muestra hotspots por nodo |

#### 3.3 Posicionamiento del Usuario ✅

| Método | Estado | Archivo |
|---|---|---|
| QR codes en cada nodo | ✅ | `qr_scanner_screen.dart` con `mobile_scanner` |
| Selección manual ("¿dónde estás?") | ✅ | `manual_location_screen.dart` con búsqueda y filtros |
| GPS puro | ⏳ | Listado como "Próximamente" en UI |
| BLE beacons | ⏳ | Listado como "Próximamente" en UI |

#### 3.4 Backend ⚠️ PARCIAL

| Punto | Estado | Evidencia |
|---|---|---|
| Firebase (Firestore + Storage) | ⏳ | `firebase_options.dart` placeholder, dependencias instaladas |
| Alternativa Supabase | ⏳ | No implementada |

---

### FASE 4 — Piloto y Ajuste ⏳ PENDIENTE

| Punto del Roadmap | Estado |
|---|---|
| Lanzar app para edificio piloto | ⏳ Pendiente |
| Medir tasa de éxito | ⏳ Pendiente |
| Ajustar densidad de nodos | ⏳ Pendiente |
| Ajustar lenguaje visual | ⏳ Pendiente |

---

### FASE 5 — Escalar al Resto del Campus ⏳ PENDIENTE

| Punto del Roadmap | Estado |
|---|---|
| Repetir captura para otros edificios | ⏳ Pendiente |
| Automatizar subida/etiquetado (panel admin) | ⚠️ Panel admin implementado, sin backend |
| CMS interno | ⏳ Pendiente |

---

## 5. Funcionalidades Implementadas

### 5.1 Navegación 360°
- **Visor panorámico** con `panorama_viewer` package
- **Hotspots interactivos** con cálculo de posición yaw/pitch
- **Transiciones animadas** (cross-fade + scale) entre panoramas
- **Placeholder dinámico** con colores únicos por nodo cuando no hay imagen real

### 5.2 Cálculo de Rutas
- **BFS** para encontrar ruta más corta en el grafo
- **Dijkstra y A*** implementados en `graph_utils.dart`
- **Instrucciones de navegación** generadas automáticamente (dirección, distancia, tiempo estimado)
- **Modos de ruta:**
  - **Ruta Guiada:** El usuario avanza manualmente entre nodos
  - **Ruta Rápida:** Avance automático cada 2 segundos
  - **Navegación Libre:** Exploración sin ruta predefinida

### 5.3 Posicionamiento del Usuario
- **Escáner QR:** Detecta códigos con formatos `NODE:XXX`, `XXX`, o URLs con `?node=XXX`
- **Selección Manual:** Búsqueda por nombre/ID/destino, filtros por piso y zona
- **Estadísticas en tiempo real:** Nodos filtrados, destinos, transiciones

### 5.4 Panel de Administración
- **Gestión de nodos:** Lista, edición, eliminación
- **Agregar nodo:** Formulario completo con validaciones:
  - ID único (verificación en tiempo real)
  - Mínimo 2 conexiones requeridas
  - Coordenadas GPS validadas
  - Captura de foto desde cámara/galería
- **Configuración:** Resumen de calidad de datos, exportar/importar

### 5.5 Interfaz de Usuario
- **Pestañas de navegación:** Inicio, Navegar, Visor 360°, Admin
- **Home screen:** Acceso rápido, métodos de posicionamiento, rutas recientes
- **Indicadores visuales:** Barra de progreso, puntos de paso, flechas de dirección
- **Banner de advertencia:** Simulación de dirección incorrecta
- **Banner de completado:** Confirmación de llegada al destino

---

## 6. Dependencias y Tecnologías

### Dependencias Principales
| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_riverpod` | ^2.5.1 | State management |
| `firebase_core` | ^3.12.1 | Firebase initialization |
| `cloud_firestore` | ^5.6.5 | Base de datos |
| `firebase_storage` | ^12.4.3 | Almacenamiento de imágenes |
| `geolocator` | ^13.0.2 | Servicios GPS |
| `mobile_scanner` | ^7.4.0 | Escaneo QR |
| `panorama_viewer` | ^2.0.7 | Visor 360° |
| `equatable` | ^2.0.5 | Igualdad de valores |
| `get_it` | ^8.0.3 | Inyección de dependencias |
| `image_picker` | ^1.1.2 | Selección de imágenes |

### Dependencias de Desarrollo
| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_test` | SDK | Testing |
| `mockito` | ^5.4.4 | Mock generation |
| `build_runner` | ^2.4.13 | Code generation |
| `json_serializable` | ^6.8.0 | JSON serialization |

---

## 7. Arquitectura y Diseño

### Patrón: Clean Architecture
- **Domain:** Modelos, repositorios abstractos, casos de uso
- **Data:** Fuentes de datos mock, implementaciones de repositorios
- **Presentation:** Pantallas, widgets, providers

### Principios SOLID aplicados:
- **S**ingle Responsibility: Cada modelo, pantalla y widget tiene una responsabilidad única
- **O**pen/Closed: Modelos extensibles via `copyWith()`, repositorios abstractos
- **L**iskov Substitution: Repositorios mock implementan interfaces abstractas
- **I**nterface Segregation: Repositorios granulares por feature
- **D**ependency Inversion: Dependencias de alto nivel no dependen de bajo nivel (get_it)

### Convenciones:
- **Imports:** Usar `package:app_guia_ar/...` (no rutas relativas)
- **Nodos:** IDs `P01`-`P09` para pasillos, `P_AULA_XXX` para aulas
- **Idioma:** UI en español, comentarios en español
- **Colores:** Constantes en `AppTheme` para consistencia visual

---

## 8. Tests Unitarios

### `test/node_search_test.dart` — 10 tests ✅
| Test | Descripción |
|------|-------------|
| `getNodeById returns correct node` | Verifica lookup por ID |
| `getNodeById returns null for non-existent node` | Manejo de nodos inexistentes |
| `getNodesByFloor returns correct floor nodes` | Filtrado por piso |
| `getDestinations returns only destination nodes` | Filtrado de destinos |
| `getConnectedNodes returns correct connections` | Obtener conexiones |
| `getConnectedNodes returns empty for non-existent node` | Manejo de errores |
| `getAllNodes returns all campus nodes` | Conteo total (12) |
| `node properties are correctly set` | Propiedades del modelo |
| `node connectedNodeIds are valid` | Integridad referencial |
| `node connections are bidirectional` | Conexiones bidireccionales |

### `test/route_calculation_test.dart` — 14 tests ✅
| Test | Descripción |
|------|-------------|
| `findRoute returns path between connected nodes` | Ruta básica |
| `findRoute returns empty for non-existent start` | Error de inicio |
| `findRoute returns empty for non-existent end` | Error de destino |
| `findRoute returns shortest path` | Verificación de optimalidad |
| `calculateRoute returns valid route model` | Modelo de ruta válido |
| `calculateRoute returns failed status for no route` | Estado failed |
| `calculateRoute with guidedWalk mode` | Modo ruta guiada |
| `calculateRoute with quickPreview mode` | Modo vista rápida |
| `route steps have instructions` | Instrucciones generadas |
| `route steps have bearing and distance` | Bearing y distancia |
| `route total distance is sum of steps` | Distancia total correcta |
| `route progress tracking works` | Seguimiento de progreso |
| `route current and destination nodes are correct` | Nodos actuales/destino |
| `route cross-floor navigation works` | Navegación entre pisos |

**Total: 24 tests pasados ✅**

---

## 9. Estado de Implementación

### Completado ✅
| Funcionalidad | Archivo |
|---------------|---------|
| Visor 360° con hotspots | `panorama_viewer_widget.dart` |
| Transiciones animadas | `panorama_viewer_widget.dart` |
| Cálculo de rutas BFS | `mock_campus_data.dart` |
| Dijkstra y A* | `graph_utils.dart` |
| Ruta guiada | `guided_route_screen.dart` |
| Vista rápida (auto-advance) | `guided_route_screen.dart` |
| Escáner QR | `qr_scanner_screen.dart` |
| Selección manual | `manual_location_screen.dart` |
| Panel de administración | `admin_screen.dart` |
| Validación de nodos | `admin_screen.dart` |
| Tests unitarios | `test/` |
| Clean Architecture | Estructura completa |

### Parcial ⚠️
| Funcionalidad | Estado |
|---------------|--------|
| Firebase integration | Dependencias instaladas, placeholders |
| Riverpod providers | Implementados pero no conectados a UI |
| Exportar/Importar datos | UI placeholder sin backend |

### Pendiente ⏳
| Funcionalidad |
|---------------|
| Imágenes 360° reales |
| GPS positioning |
| BLE beacons |
| Firebase Firestore connection |
| Piloto con usuarios reales |
| Escalar a otros edificios |
| CMS interno |

---

## 10. Próximos Pasos

### Inmediatos (Fase 4)
1. **Capturar fotos 360° reales** para los 12 nodos
2. **Configurar Firebase** con credenciales reales
3. **Conectar Firestore** para persistencia de datos
4. **Implementar GPS positioning** para exteriores

### Corto plazo
5. **Migrar a Riverpod** completamente (los providers ya están escritos)
6. **Implementar exportar/importar** datos reales
7. **Agregar más nodos** según feedback de usuarios
8. **Optimizar transiciones** de panorama

### Mediano plazo (Fase 5)
9. **Agregar edificios** adicionales
10. **Implementar CMS** para gestión no-técnica
11. **BLE beacons** para interiores de alta precisión
12. **Analytics** para medir uso y mejorar rutas

---

## Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `lib/features/navigation/data/datasources/mock_campus_data.dart` | Grafo completo del campus |
| `lib/features/navigation/domain/models/route_model.dart` | Modelos de ruta y pasos |
| `lib/features/panorama_viewer/presentation/widgets/panorama_viewer_widget.dart` | Visor 360° core |
| `lib/features/navigation/presentation/screens/guided_route_screen.dart` | Experiencia de navegación |
| `lib/features/navigation/presentation/screens/admin_screen.dart` | Panel de administración |
| `lib/core/utils/graph_utils.dart` | Algoritmos de pathfinding |
| `lib/core/theme/app_theme.dart` | Sistema de diseño visual |
| `test/node_search_test.dart` | Tests de búsqueda |
| `test/route_calculation_test.dart` | Tests de rutas |

---

*Documentación generada: 2026-08-10*
*Última actualización: Fases 0-3 completadas, 24 tests pasados*
