# gestor_cafeteria

App Flutter para la gestión de cafetería (pedidos/productos). Cliente HTTP con errores tipados (`Failure`) y pruebas con `MockClient`.

Proyecto escolar — Desarrollo Móvil Integral, 10.º A, Septiembre–Diciembre 2026.

## Requisitos

- Flutter (canal stable, Dart ^3.13.3 — probado con Flutter 3.47.7)
- Node.js 22.13 o superior (para correr `mini_backend`)
- Un emulador Android / dispositivo o Chrome para correr la app

## mini_backend

- Repositorio: https://github.com/DMI-2026/mini_backend
- Versión probada: `0.1.0`, commit `118adde` (“refactor: migrate backend from Python to dependency-free Node.js”).
- `mini_backend` es otro repositorio: no se copia dentro de este proyecto Flutter, solo se referencia aquí.

### Levantar el servidor

```bash
# En la carpeta de mini_backend (repositorio aparte)
# Requiere Node.js 22.13 o superior. No necesita npm install.
node server.js   # http://127.0.0.1:8000
node --test      # pruebas del backend

# Variables opcionales: PORT (8000), HOST (0.0.0.0), DB_PATH (app.db)
# PORT=8001 node server.js
```

## Cómo ejecutar la app

La URL del backend se inyecta con `--dart-define=API_URL`:

```bash
flutter pub get

# Emulador Android (10.0.2.2 apunta al localhost de tu PC)
flutter run --dart-define=API_URL=http://10.0.2.2:8000

# Chrome / escritorio contra localhost
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

> `ApiClient(baseUrl: ...)` usa esa `API_URL`. Sin `API_URL` las rutas se resuelven como relativas.

## Cómo correr las pruebas

```bash
flutter test
# Solo cliente HTTP:
flutter test test/core/http_client_test.dart
```

16 pruebas: 404→`NotFoundFailure`, 409→`ConflictFailure`, 422→`ValidationFailure` (con/sin `fields`), 5xx→`ServerFailure`, timeout/`ClientException`→`NetworkFailure`, 400/403→`UnexpectedFailure`, 200/201 decodifican JSON, 204 vacío→`null`, cuerpo no-JSON→texto, POST envía JSON.

## Estructura de carpetas (resumen)

```text
lib/
  main.dart            # entrada mínima (Hello World)
  core/
    failure.dart       # Failure sellado: Network/Server/NotFound/Conflict/Validation/Unexpected
    http_client.dart   # ApiClient: get/post, timeout 10s, mapeo por status code
test/
  core/
    http_client_test.dart  # pruebas con MockClient
android/, web/        # plataformas estándar Flutter
```

## Versionamiento (Tarea 3)

- `main` protegido: todo entra por PR con autorrevisión.
- `feature/error-mapping` → PR #1: `Failure` + `ApiClient` (Práctica B).
- `feature/api-tests` → PR #2: pruebas + 3 correcciones (Tarea 1: 300 no exitoso, 204→null, no-JSON→texto).
- Etiqueta `v0.1.0`: “Cliente HTTP con errores tipados y pruebas”.
