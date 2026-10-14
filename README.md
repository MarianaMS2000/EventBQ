# eventbq

A new Flutter project created with FlutLab - https://flutlab.io

## Getting Started

A few resources to get you started if this is your first Flutter project:

- https://flutter.dev/docs/get-started/codelab
- https://flutter.dev/docs/cookbook

For help getting started with Flutter, view our
https://flutter.dev/docs, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started: FlutLab - Flutter Online IDE

- How to use FlutLab? Please, view our https://flutlab.io/docs
- Join the discussion and conversation on https://flutlab.io/residents

## Persistencia local (segundo corte)

Sin base de datos externa: los datos viven en `List` (memoria) y se guardan como JSON en `SharedPreferences`.

| Dato | Dónde | Clave |
|---|---|---|
| Cuentas (registro/login) | `UsuarioRepository` | `cuentas` |
| Sesión activa | `PreferenciasUsuario` | `usuario_activo` |
| Eventos creados | `EventoRepository` | `eventos_publicados` |
| Entradas compradas, publicaciones, plan | `EventoRepository` (por usuario) | `entradas_compradas__<usuario>`, ... |
| Favoritos, onboarding | `PreferenciasUsuario` (por usuario) | `eventos_favoritos__<usuario>`, ... |
| Notificaciones | `NotificacionRepository` (por usuario) | `notificaciones__<usuario>` |

`lib/repositories/cambios.dart` avisa a las pantallas cuando algo se guarda para que se redibujen.
