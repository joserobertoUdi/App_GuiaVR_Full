# Protocolo de Captura de Imágenes 360° para Campus Universitario

## 1. Objetivo
Establecer estándares uniformes para la captura de imágenes panorámicas 360° que garanticen calidad consistente y navegabilidad efectiva en la aplicación.

---

## 2. Equipo Requerido

### Opción A: Cámara 360° dedicada
- **Ricoh Theta SC2** o superior
- **Insta360 ONE X2** o similar
- Resolución mínima: 5MP por lente (10MP total)
- Estabilización interna

### Opción B: Smartphone con app panorámica
- **Google Street View** (Android/iOS) - genera fotoesferas automáticamente
- **360° Photo Sphere** (Android nativo)
- **Panorama Photo** (iOS)
- Resolución mínima: 12MP

### Opción C: Smartphones convencionales
- Capturar múltiples fotos superpuestas
- Usar app de stitching: **Microsoft ICE**, **PTGui**, o **Hugin**

### Equipo de soporte
- **Trípode compacto** o **monopode** (altura mínima: 1.2m)
- **Espejo deselfie** si se usa smartphone frontal
- **Power bank** para sesiones largas

---

## 3. Especificaciones Técnicas

### 3.1 Resolución y Formato
| Parámetro | Valor mínimo | Valor recomendado |
|-----------|--------------|-------------------|
| Resolución total | 4096 x 2048 px | 8192 x 4096 px |
| Formato de salida | JPEG | JPEG (calidad 90%) o PNG |
| Tamaño máximo por imagen | 5 MB | 10 MB |
| Campo de vista | 360° x 180° | 360° x 180° |

### 3.2 Condiciones de Iluminación
| Condición | Recomendación |
|-----------|---------------|
| **Hora ideal** | 9:00 - 11:00 AM o 3:00 - 5:00 PM |
| **Luz solar** | Evitar contraluz directo |
| **Interior** | Encender todas las luces artificiales |
| **Exterior nublado** | Perfecto - luz difusa uniforme |
| **Evitar** | Mediodía (sombras cortas), atardecer (tonos anaranjados) |

### 3.3 Altura y Posición de Cámara
| Ubicación | Altura de cámara | Notas |
|-----------|------------------|-------|
| **Pasillos** | 1.5 - 1.6 metros | Altura de ojos promedio |
| **Escaleras** | 1.3 metros | Mirando hacia arriba/abajo |
| **Entradas** | 1.5 metros | Centrado en el vano |
| **Aulas** | 1.4 metros | Centro del espacio |
| **Exteriores** | 1.6 metros | Sobre multitudes |

### 3.4 Distancia a Objetos
- **Mínimo 1 metro** a paredes u obstrucciones
- **Centrar** el punto de interés en el encuadre
- **Evitar** que el trípode aparezca en la imagen (usar modo nadir o editar después)

---

## 4. Procedimiento de Captura por Nodo

### Paso 1: Pre-captura
1. Verificar ubicación en el mapa (coordenadas GPS)
2. Confirmar conexiones con nodos vecinos
3. Verificar iluminación y condições
4. Limpiar lentes de la cámara

### Paso 2: Captura
1. Posicionar trípode/cámara a la altura especificada
2. Orientar cámara hacia el nodo más cercano (referencia)
3. Capturar imagen panorámica completa
4. Verificar preview: revisar que no haya zonas oscuras o sobreexpuestas

### Paso 3: Post-captura
1. Verificar resolución y calidad
2. Renombrar archivo con nomenclatura estándar
3. Anotar metadata:
   - ID del nodo
   - Fecha/hora
   - Condiciones de luz
   - Notas especiales

---

## 5. Nomenclatura de Archivos

```
[EDIFICIO]_[PISO]_[NODO]_[FECHA]_[VERSION].[ext]
```

**Ejemplo:**
```
A_P1_P01_20260810_v1.jpg
A_P2_P_AULA_204_20260810_v1.jpg
```

### Convención de IDs de nodo
| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Pasillo/Transición | P[XX] | P01, P02, P05 |
| Aula | P_AULA_[XXX] | P_AULA_101, P_AULA_204 |
| Destino especial | P_[NOMBRE] | P_BIBLIO, P_LAB |

---

## 6. checklist de Calidad

### Al capturar
- [ ] Resolución mínima alcanzada
- [ ] Campo de vista completo (360° x 180°)
- [ ] Sin partes oscuras (underexposed)
- [ ] Sin partes quemadas (overexposed)
- [ ] trípode no visible (o mínimo)
- [ ] Horizonte nivelado

### Al procesar
- [ ] Recorte correcto (eliminación de bordes negros)
- [ ] Exposición corregida si necesario
- [ ] Thumbnail generado (512x256 mínimo)
- [ ] Archivo comprimido sin perder calidad visible
- [ ] Metadata incrusta (EXIF)

### Al integrar
- [ ] Archivo nombrado correctamente
- [ ] Almacenado en carpeta correcta
- [ ] Referenciado en mock_panoramas_data.dart
- [ ] Hotspots configurados con yaw/pitch correctos

---

## 7. Errores Comunes y Soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| Imagen oscura | Poca luz interior | Aumentar ISO o usar flash |
| Imagen quemada | Contraluz directo | Capturar en otro momento |
| Horizonte torcido | Trípode desnivelado | Nivelar o corregir en post |
| Stitching visible | Movimiento durante captura | Usar trípode, evitar viento |
| Tripode visible | Ángulo muy bajo | Usar modo nadir o editar |
| Zonas negras | Campo de vista incompleto | Capturar ángulos adicionales |

---

## 8. Herramientas de Procesamiento Recomendadas

### Gratuitas
| Herramienta | Plataforma | Uso |
|-------------|------------|-----|
| GIMP | Windows/Mac/Linux | Edición general |
| IrfanView | Windows | Redimensionar, renombrar |
| XnView | Multiplataforma | Catalogar, convertir |
| ImageMagick | Multiplataforma | Lotes de procesamiento |

### Específicas 360°
| Herramienta | Uso |
|-------------|-----|
| Pano2VR | Editor de hotspot interactivo |
| KrPano | Visualizador web 360° |
| Street View Publish API | Subir a Google Maps (futuro) |

---

## 9. Plantilla de Metadata por Nodo

```json
{
  "nodeId": "P01",
  "name": "Entrada Principal",
  "floorLevel": "1",
  "buildingId": "edificio_A",
  "latitude": -16.5001,
  "longitude": -68.1501,
  "heading": 0,
  "captureDate": "2026-08-10",
  "captureTime": "10:30",
  "cameraHeight": 1.5,
  "lightConditions": "Interior artificial",
  "imageFile": "A_P1_P01_20260810_v1.jpg",
  "thumbnailFile": "A_P1_P01_20260810_v1_thumb.jpg",
  "resolution": "8192x4096",
  "fileSizeKB": 2450,
  "hotspots": [
    {
      "targetNodeId": "P02",
      "yaw": 90,
      "pitch": 0,
      "label": "Entrar al pasillo"
    }
  ],
  "notes": "Puerta principal, buena iluminación natural"
}
```

---

## 10. Flujo de Trabajo Resumido

```
1. Planificar ruta de captura
       ↓
2. Capturar imágenes en campo
       ↓
3. Transferir a computadora
       ↓
4. Procesar (recortar, ajustar, thumbnail)
       ↓
5. Renombrar según convención
       ↓
6. Actualizar metadata en JSON
       ↓
7. Copiar a assets/panoramas/
       ↓
8. Actualizar mock_panoramas_data.dart
       ↓
9. Verificar en app
       ↓
10. Documentar en CHANGELOG
```

---

*Protocolo versión: 1.0*
*Fecha: 2026-08-10*
*Proyecto: Guía AR Campus*
