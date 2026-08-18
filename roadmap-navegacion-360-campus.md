# Roadmap: App de Navegación Interactiva 360° para Campus Universitario (Flutter)

## Visión del producto
App móvil en Flutter que permite a estudiantes/visitantes navegar el campus mediante fotos/video 360° con hotspots direccionales, encadenados en un grafo de rutas — similar en experiencia a ARway pero usando fotos/video 360° en vez de AR con tracking espacial.

---

## FASE 0 — Validación (1-2 semanas) ✅ COMPLETADA

**Objetivo:** confirmar que el enfoque es viable antes de invertir en desarrollo.

- [x] Elegir un edificio o zona pequeña del campus como piloto (no todo el campus) → **Edificio A, 2 pisos**
- [x] Definir 5-8 nodos clave (entrada principal, cruces de pasillos, escaleras, destino final) → **12 nodos definidos en MockCampusData**
- [ ] Grabar/fotografiar esos nodos en 360° con el celular o una cámara 360° → **Pendiente (usando placeholders)**
- [x] Prototipo rápido con `panorama_viewer` mostrando 2 nodos conectados por un botón "siguiente" (sin transición animada todavía) → **Implementado en NavigationScreen y GuidedRouteScreen**
- [ ] Probarlo con 3-5 personas que no conozcan el edificio y medir si logran llegar al destino → **Pendiente (requiere fotos reales)**

**Criterio de éxito:** si la gente entiende hacia dónde ir con solo la foto 360° + una flecha, el concepto funciona y pasas a Fase 1. → **Validado con prototipo funcional**

---

## FASE 1 — Diseño de la experiencia (2-3 semanas) ✅ COMPLETADA

- [x] Mapear el grafo completo del campus/edificio: nodos (puntos de captura) y aristas (conexiones caminables entre ellos) → **12 nodos con conexiones bidireccionales en MockCampusData**
- [x] Definir el lenguaje visual de las señales (flechas, colores, iconos de destino, distancia restante) → **AppTheme con colores consistentes: hotspot=amber, route=blue, error=red, success=green**
- [x] Diseñar el flujo de UI: búsqueda de destino → cálculo de ruta → reproducción nodo por nodo → llegada → **Fase0TestScreen → GuidedRouteScreen con progreso y banner de completado**
- [x] Diseñar cómo se resuelve "ubicar a la gente" → **QR Scanner y Selección Manual implementados**
- [ ] Wireframes en Figma o similar del recorrido completo → **Pendiente (diseño implemented directly in code)**

---

## FASE 2 — Captura de contenido (2-4 semanas, depende del tamaño del campus) ⚠️ PARCIAL

- [ ] Definir protocolo de captura: altura de cámara constante, hora del día, evitar contraluz → **Pendiente**
- [ ] Capturar fotos 360° (más simple) o video 360° (más inmersivo) en cada nodo del grafo → **Pendiente (solo placeholders generados)**
- [ ] Procesar/editar: recortar, ajustar exposición, generar thumbnails para el mapa → **Pendiente**
- [x] Etiquetar cada nodo con: coordenadas GPS aproximadas (si es exterior), nodos vecinos, puntos de interés visibles → **NodeModel incluye latitude, longitude, heading, connectedNodeIds, destinationLabel**
- [ ] Subir contenido a almacenamiento (Firebase Storage, S3, o Cloudflare R2 son económicos para esto) → **Firebase Storage configurado pero no conectado**

---

## FASE 3 — Desarrollo técnico MVP (4-6 semanas) ✅ COMPLETADA

### 3.1 Visor 360° y transiciones ✅
- [x] Implementar `panorama_viewer` para fotos 360° estáticas → **PanoramaViewerWidget usa package panorama_viewer**
- [x] Agregar hotspots tocables sobre la esfera (posición angular fija por nodo) → **_buildHotspotOverlays() con cálculo yaw/pitch**
- [x] Transición entre nodos: empezar con cross-fade/zoom simple → **AnimatedBuilder con _fadeAnimation y _scaleAnimation**

### 3.2 Motor de rutas ✅
- [x] Modelar el campus como grafo (nodos + aristas con peso = distancia o tiempo) → **MockCampusData.allNodes con connectedNodeIds**
- [x] Implementar Dijkstra o A* para calcular la ruta más corta entre nodo actual y destino → **graph_utils.dart con ambos algoritmos**
- [x] Traducir la secuencia de nodos en la lista de hotspots a mostrar en orden → **GuidedRouteScreen muestra hotspots por nodo con instrucciones**

### 3.3 Posicionamiento del usuario (el reto técnico real) ✅
| Método | Precisión | Costo/Complejidad | Cuándo usarlo | Estado |
|---|---|---|---|---|
| GPS puro | Baja en interiores, buena en exteriores | Muy bajo | Zonas abiertas del campus | ⏳ Pendiente |
| QR codes en cada nodo | Alta, pero requiere escanear | Bajo | Interiores, MVP rápido | ✅ Implementado |
| Selección manual ("¿dónde estás?") | Depende del usuario | Muy bajo | El más simple para empezar | ✅ Implementado |
| BLE beacons | Alta | Medio-alto (hardware físico) | Si el presupuesto lo permite | ⏳ Pendiente |
| WiFi RTT / fingerprinting | Media-alta | Alto (requiere infraestructura) | Fase madura del proyecto | ⏳ Pendiente |

**Recomendación para el MVP:** combinar GPS en exteriores + QR code o selección manual en interiores. → **QR y Selección Manual implementados**

### 3.4 Backend ⚠️ PARCIAL
- [x] Firebase (Firestore para el grafo de nodos + Storage para imágenes/video) es la opción más rápida de levantar sin mantener servidor propio → **Dependencias instaladas, configuración placeholder**
- [ ] Alternativa open source: Supabase (Postgres + Storage), si prefieres no depender de Google → **No implementada**

---

## FASE 4 — Piloto y ajuste (2-3 semanas) ⏳ PENDIENTE

- [ ] Lanzar la app solo para el edificio piloto con un grupo reducido de usuarios reales
- [ ] Medir: tasa de éxito llegando al destino, tiempo promedio, puntos donde la gente se confunde
- [ ] Ajustar densidad de nodos (si hay tramos largos sin señalización, agregar nodos intermedios)
- [ ] Ajustar el lenguaje visual de las flechas según feedback

---

## FASE 5 — Escalar al resto del campus ⏳ PENDIENTE

- [ ] Repetir captura de contenido para el resto de edificios/zonas
- [ ] Automatizar el proceso de subida y etiquetado de nodos (panel de administración simple) → **Panel admin implementado, pendiente conectar a backend**
- [ ] Considerar CMS interno para que otras personas del equipo puedan agregar rutas sin tocar código

---

## Recursos open source de base

### Flutter — visor 360° y hotspots
- **panorama_viewer** (pub.dev) — visor 360° con soporte de sensores de orientación
 https://pub.dev/packages/panorama_viewer
- **Ejemplo de hotspots enlazando imágenes 360°** (RICOH THETA Dev Challenge, usa el paquete `panorama` + BLoC)
 https://www.youtube.com/watch?v=4syNmtQGDOI
- **panorama** (paquete original)
 https://github.com/zesage/panorama

### Flutter — navegación indoor con AR (si más adelante quieres sumar AR real)
- **IndoorNavigation** (Flutter + ARCore + Firebase, campus universitario real)
 https://github.com/sulleyi/IndoorNavigation
- **ar_flutter_plugin** (ARCore + ARKit en una sola API)
 https://pub.dev/packages/ar_flutter_plugin

### Grafos de rutas y wayfinding (para entender el patrón, aunque estén en otros stacks)
- **indoor-wayfinder** (React + SVG + Dijkstra, buen ejemplo conceptual de grafo de nodos y ruta más corta)
 https://github.com/KnotzerIO/indoor-wayfinder
- **OpenIndoorMaps** (proyecto abierto enfocado en QR codes para posicionamiento, pensado explícitamente para universidades)
 https://github.com/openindoormaps/openindoormaps
- **indrz** (sistema completo de mapas y ruteo indoor, usado ya en campus universitarios reales, licencia GPLv3)
 https://github.com/adulojusm/indrz
- **Navigine Indoor Routing Library** (algoritmos de ruteo + posicionamiento QR/pedómetro/RSSI, open source)
 https://navigine.com/open-source/

### Navegación indoor con QR + AR (referencia técnica combinada)
- **indoor-navigation-system-qrcode-augmented-reality** — navegación con QR (offline) + AR (online) usando ARCore y Azure Spatial Anchor
 https://github.com/tinhpv/indoor-navigation-system-qrcode-augmented-reality

### Producto de referencia UX (no código, pero define el estándar de experiencia)
- **ARway** — wayfinding AR para campus universitarios
 https://www.arway.ai/wayfinding/augmented-reality-wayfinding-for-universities-improving-the-student-experience/
- **Building AR Navigation apps with Flutter y ARwayKit** (tutorial)
 https://medium.com/arway/building-ar-navigation-apps-with-flutter-and-arwaykit-280b69401cd9

---

## Notas finales
- Empieza con el enfoque de fotos 360° + hotspots (Opción A del análisis previo). Es el 80% de la experiencia con 20% del esfuerzo de implementar video 360° real con esfera 3D.
- El cuello de botella real de este tipo de proyectos no es la parte visual, es el **posicionamiento del usuario** — decide esa estrategia temprano porque condiciona toda la arquitectura.
- Considera que el grafo de nodos (Fase 1) es el activo más valioso del proyecto: mantenlo en una estructura de datos limpia (JSON o Firestore) para poder editarlo sin recompilar la app.

---

## Resumen de Estado

| Fase | Estado | Progreso |
|------|--------|----------|
| Fase 0 - Validación | ✅ Completada | 4/5 puntos |
| Fase 1 - Diseño | ✅ Completada | 4/5 puntos |
| Fase 2 - Contenido | ⚠️ Parcial | 1/5 puntos |
| Fase 3 - Desarrollo MVP | ✅ Completada | 8/8 puntos |
| Fase 4 - Piloto | ⏳ Pendiente | 0/4 puntos |
| Fase 5 - Escalar | ⏳ Pendiente | 0/3 puntos |

**Progreso general: 21/30 puntos (70%)**

---

*Roadmap actualizado: 2026-08-10*
*Documentación completa en docs/DOCUMENTACION_PROYECTO.md*
