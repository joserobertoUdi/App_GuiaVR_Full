# Assets para Panoramas 360°

## Instrucciones para Fase 0

Para probar la aplicación, necesitas agregar imágenes panorámicas 360° en esta carpeta.

### Opciones para obtener imágenes 360°:

1. **Google Street View**: Usa la app de Google Street View para crear fotos esféricas gratis
2. **Cámaras 360°**: Insta360, Ricoh Theta, o similar
3. **Apps móviles**: Panorama Photo, 360° Camera, etc.

### Formato requerido:

- **Nombre**: `panorama_001.jpg`, `panorama_002.jpg`, etc.
- **Resolución recomendada**: 4096x2048 pixels (2:1)
- **Formato**: JPEG o PNG
- **Peso máximo**: 5MB por imagen (para testing)

### Imágenes de prueba:

Si no tienes imágenes 360° reales, puedes usar imágenes de prueba de:

1. **Unsplash** (gratis): Busca "360 panorama" o "virtual tour"
2. **Pexels** (gratis): Busca "panoramic view"
3. **Placeholder**: La app muestra un placeholder automático cuando no encuentra la imagen

### Mapeo de nodos:

| Archivo | Nodo | Descripción |
|---------|------|-------------|
| panorama_001.jpg | Entrada Principal | Vestíbulo del edificio |
| panorama_002.jpg | Cruce de Pasillo | Intersección pasillo principal |
| panorama_003.jpg | Escaleras | Escaleras principales |
| panorama_004.jpg | Sala de Estudios | Destino final |

### Testing rápido:

Si solo quieres probar la navegación, puedes usar una sola imagen 360° y copiarla como `panorama_001.jpg` hasta `panorama_004.jpg`.
