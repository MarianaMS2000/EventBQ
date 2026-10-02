# EventBQ

App móvil de eventos hecha con Flutter (solo frontend, datos simulados).
Usa únicamente `shared_preferences` como dependencia extra (guardar sesión,
onboarding visto, datos básicos del usuario y eventos favoritos).

## 1. Instalar Flutter
Sigue la guía oficial: https://docs.flutter.dev/get-started/install
Comprueba con `flutter doctor`.

## 2. Preparar el proyecto (SOLO la primera vez)
Este proyecto trae `lib/`, `assets/` y `pubspec.yaml`. Las carpetas de plataforma
(`android/`, `ios/`, `web/`) las genera Flutter. Dentro de esta carpeta ejecuta:

```bash
flutter create --project-name eventbq --platforms=android,ios,web .
```
(No sobrescribe `lib/` ni `pubspec.yaml`.) Después borra `test/widget_test.dart`
si se creó, porque apunta a la app de ejemplo.

## 3. Instalar dependencias y ejecutar
```bash
flutter pub get
flutter run
```

## 4. Dónde está cada cosa
| Qué | Dónde |
|---|---|
| Pantallas | `lib/screens/` |
| Widgets reutilizables | `lib/widgets/` |
| Modelos | `lib/models/` |
| Datos simulados | `lib/data/datos_simulados.dart` |
| Repositories | `lib/repositories/` |
| SharedPreferences | `lib/preferences/preferencias_usuario.dart` |
| Colores | `lib/theme/colores.dart` |
| Rutas | `lib/app.dart` |
| Imágenes | `assets/images/` |

## 5. Imágenes
Mientras no existan, la app muestra placeholders de color. Copia tus imágenes
en `assets/images/` con estos nombres y aparecerán solas:
`avatar.png`, `bienvenida.png`, `onboarding_1.png`, `onboarding_2.png`,
`onboarding_3.png`, `evento_festival.jpg`, `evento_food_fest.jpg`,
`evento_yoga.jpg`, `evento_teatro.jpg`, `evento_exposicion.jpg`,
`evento_mixologia.jpg`. (Las rutas están en `datos_simulados.dart`.)

## 6. Tipografía
Las capturas usan una fuente tipo **Lexend**. Descarga los .ttf, ponlos en
`assets/fonts/`, descomenta el bloque `fonts:` de `pubspec.yaml` y la línea
`fontFamily: 'Lexend'` en `lib/app.dart`.

## 7. Flujo de la app
Splash → (según SharedPreferences) Bienvenida / Onboarding / Home.
Login o Registro → Onboarding (solo la primera vez) → Home (barra inferior).
El login simulado acepta cualquier usuario y contraseña no vacíos.

### Pantallas y rutas actuales
| Ruta | Pantalla |
|---|---|
| `/` | Splash |
| `/bienvenida`, `/login`, `/registro` | Autenticación |
| `/onboarding` | Tutorial (3 páginas) |
| `/home` | Inicio / Explorar / Mis eventos / Perfil (barra inferior) |
| `/detalle-evento` | Detalle del evento (recibe un `Evento` como argumento) |
| `/perfil-organizador` | Perfil del organizador |
| `/registro-exitoso` | Ticket con QR (recibe un `Evento`) |
| `/notificaciones` | Centro de notificaciones |
| `/calificar` | Calificar un evento (recibe un `Evento`) |
| `/gracias-opinion` | Agradecimiento tras calificar |

El perfil del usuario (modo lectura y edición) es la pestaña 3 de `/home`
(`screens/perfil_screen.dart`). Email, teléfono y rol se guardan en SharedPreferences.
Los eventos guardados salen de los corazones (también en SharedPreferences).

El modal de filtros y el diálogo de confirmación no son rutas:
`mostrarFiltros(context, filtros)` (`widgets/filtros_sheet.dart`) y
`mostrarDialogoConfirmarAsistencia(context, evento)` (`widgets/dialogo_confirmar_asistencia.dart`).

Para ir a una pestaña de la barra inferior desde cualquier pantalla:
`irAPestana(context, 1);` (0 Inicio, 1 Explorar, 2 Mis eventos, 3 Perfil).

Imágenes nuevas: `evento_carrera.jpg`, `evento_entrenamiento.jpg`, `evento_ciclovia.jpg`, `organizadora.png`, `evento_pigmentos.jpg`, `evento_luces.jpg`, `mapa.png`.

**Nota:** el QR del ticket es un dibujo (no se puede escanear). Cuando haya backend
se reemplaza `QrPlaceholder` por un QR real.

## 8. Agregar una pantalla nueva
1. Crea `lib/screens/detalle_evento_screen.dart` con un `StatelessWidget`/`StatefulWidget`.
2. Regístrala en `lib/app.dart`:
   ```dart
   '/detalle-evento': (context) => const DetalleEventoScreen(),
   ```
3. Navega: `Navigator.pushNamed(context, '/detalle-evento');`

## 9. Agregar una ruta
Es la línea del paso 2 dentro de `routes:` en `lib/app.dart`.

## 10. Cambiar los datos simulados por un backend
Las pantallas solo hablan con los repositories (`Pantalla → Repository → Data`).
Cuando haya backend, cambia SOLO el interior de los métodos del repository:
```dart
// Hoy
List<Evento> obtenerEventosTop() => datosEventosTop;
// Mañana
Future<List<Evento>> obtenerEventosTop() async { /* llamada a la API */ }
```
Al volverse `Future`, en la pantalla usa `FutureBuilder` o `await` en `initState`.
Después puedes borrar `lib/data/datos_simulados.dart`.

## 11. Ampliar SharedPreferences
En `preferencias_usuario.dart` añade una clave `static const _kAlgo = 'algo';`
y su getter/setter siguiendo el patrón de los existentes.
