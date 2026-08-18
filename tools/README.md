# Backend de Push Local (Dart puro)

Backend HTTP mínimo en **Dart puro** (`dart:io`, sin dependencias externas) que
transporta el contenido publicado por la web de administración hasta la app móvil.

La **web** publica el bundle y las imágenes (PUT), y la **app móvil** los consulta
al arrancar y se actualiza automáticamente.

## Ejecutar

```sh
dart run backend_server.dart       # puerto por defecto 8082
dart run backend_server.dart 9000  # puerto custom
```

Persiste los datos en `backend_data/` (se crea automáticamente).

## Endpoints

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/health` | GET | estado del servicio |
| `/api/bundle` | GET / PUT | leer / publicar el bundle JSON |
| `/api/bundle/version` | GET | versión y resumen del bundle |
| `/api/images` | GET | lista de `nodeId` con imagen |
| `/api/images/<nodeId>` | GET / PUT | leer / publicar imagen de un nodo |

Respuesta CORS habilitada para que la web publicue desde otro origen.

## Probar (E2E)

```sh
dart run backend_server.dart 8082
dart run push_simulator.dart http://127.0.0.1:8082
```

`push_simulator.dart` publica un campus de prueba usando el **mismo** contrato
(`CampusBundle.buildJson`) y los **mismos** endpoints que la web.