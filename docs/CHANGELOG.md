# Changelog: App Guía AR Campus

## [1.0.0] - 2026-08-10

### Added - Fase 0: Validación
- `Fase0TestScreen` con selección de nodos de inicio y destino
- Selector de modo: Ruta Guiada y Ruta Rápida
- Mapa visual interactivo del campus organizado por pisos
- Lista de destinos disponibles
- Integración con `GuidedRouteScreen`

### Added - Fase 1: Diseño de Experiencia
- Clean Architecture con estructura feature-based
- Modelos de dominio: `NodeModel`, `RouteModel`, `PanoramaModel`, `HotspotModel`
- Tema Material 3 personalizado (`AppTheme`)
- Constantes globales (`AppConstants`)
- Jerarquía de excepciones tipadas
- Repositorios abstractos por feature

### Added - Fase 2: Contenido Mock
- `MockCampusData` con 12 nodos en 2 pisos
- Grafo bidireccional con conexiones válidas
- `MockPanoramasData` con 12 panoramas y hotspots
- Placeholders de imagen generados dinámicamente
- Protocolo de formato para IDs: `P01`-`P09` (pasillos), `P_AULA_XXX` (aulas)

### Added - Fase 3.1: Visor 360° y Transiciones
- `PanoramaViewerWidget` con `panorama_viewer` package
- Hotspots interactivos con cálculo yaw/pitch
- Transiciones animadas cross-fade + scale
- Placeholder dinámico con colores únicos por nodo
- Indicador de dirección "Toca la flecha para navegar"

### Added - Fase 3.2: Motor de Rutas
- BFS para cálculo de ruta más corta
- Dijkstra implementado en `graph_utils.dart`
- A* con heurística Haversine
- Generación automática de instrucciones
- Cálculo de bearing, distancia y tiempo estimado
- Modos: `guidedWalk`, `quickPreview`, `freeRoam`

### Added - Fase 3.3: Posicionamiento del Usuario
- **QR Scanner** (`qr_scanner_screen.dart`):
  - Escaneo con `mobile_scanner`
  - Parsing de formatos: `NODE:XXX`, `XXX`, URLs con `?node=XXX`
  - Diálogo de nodo detectado
  - Selector de destino
- **Selección Manual** (`manual_location_screen.dart`):
  - Búsqueda por nombre, ID o destino
  - Filtros por piso y zona
  - Estadísticas en tiempo real
  - Lista agrupada por tipo (destinos, transiciones, pasillos)

### Added - Fase 3.4: Backend (Scaffold)
- Firebase Core configurado
- Firestore dependencia instalada
- Firebase Storage dependencia instalada
- `firebase_options.dart` placeholder

### Added - Panel de Administración
- **Tab Nodos:** Lista con estadísticas y acciones
- **Tab Agregar:** Formulario con validaciones:
  - ID único (verificación en tiempo real)
  - Mínimo 2 conexiones requeridas
  - Coordenadas GPS validadas (-90 a 90, -180 a 180)
  - Heading 0-360°
  - Captura de foto desde cámara/galería
  - Editor de conexiones con chips
- **Tab Config:** Resumen de calidad, exportar/importar

### Added - Home Screen Rediseñado
- 4 pestañas: Inicio, Navegar, Visor 360°, Admin
- Acceso rápido a QR y selección manual
- Lista de métodos de posicionamiento
- Rutas recientes (ejemplo)
- Sección Acerca de

### Added - Tests Unitarios
- `node_search_test.dart`: 10 tests
  - Lookup por ID
  - Filtrado por piso y destino
  - Conexiones bidireccionales
  - Integridad referencial
- `route_calculation_test.dart`: 14 tests
  - BFS pathfinding
  - Modelos de ruta
  - Modos guiada/preview
  - Instrucciones y bearing
  - Progreso y navegación entre pisos

### Changed
- `panorama_viewer_widget.dart`: Agregado sistema de transiciones animadas
- `home_screen.dart`: Reestructurado con pestañas y acceso rápido
- `fase0_test_screen.dart`: Integrado con `MockCampusData` y selectors
- `admin_screen.dart`: Validaciones completas y placeholders de guía

### Fixed
- `route_model.dart`: Agregado `failed` al enum `RouteStatus`
- `mock_panoramas_data.dart`: IDs actualizados para coincidir con `MockCampusData`
- Eliminado `widget_test.dart` obsoleto

### Dependencies Added
- `mobile_scanner: ^7.4.0` - Escaneo QR
- `panorama_viewer: ^2.0.7` - Visor 360°
- `image_picker: ^1.1.2` - Selección de imágenes

---

## Technical Notes

### Archivos Importantes
| Archivo | Descripción |
|---------|-------------|
| `lib/features/navigation/data/datasources/mock_campus_data.dart` | Grafo principal del campus |
| `lib/features/panorama_viewer/presentation/widgets/panorama_viewer_widget.dart` | Visor 360° con transiciones |
| `lib/features/navigation/presentation/screens/guided_route_screen.dart` | Experiencia de navegación |
| `lib/features/navigation/presentation/screens/admin_screen.dart` | Panel de administración |
| `lib/core/utils/graph_utils.dart` | Algoritmos Dijkstra/A* |
| `lib/core/theme/app_theme.dart` | Sistema de diseño |

### Convenciones de Código
- Imports: `package:app_guia_ar/...` (no rutas relativas)
- Modelos: Extienden `Equatable`, soporte `copyWith()` y JSON
- UI: Texto en español, constantes de color en `AppTheme`
- Tests: Organizados por feature, descripciones en español

### Pendiente de Migración
- State management: `setState` → Riverpod (providers ya implementados)
- DI: `get_it` registrado pero no consumido por pantallas
- Firebase: Conectado pero no funcional (credenciales placeholder)

---

*Changelog actualizado: 2026-08-10*
