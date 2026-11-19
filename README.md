# EventBQ
> **Plataforma móvil para el descubrimiento, compra y gestión de eventos culturales, deportivos y gastronómicos en Barranquilla.**

Desarrollada en **Flutter y Dart**, con backend en la nube mediante **Google Firebase (Cloud Firestore, Authentication y Cloud Messaging)**, persistencia local con **SharedPreferences** y arquitectura limpia con gestión reactiva mediante **GetX**.

---

## 1. Objetivo y Descripción de la Aplicación

### 1.1 Objetivo General
Desarrollar una solución móvil integral que conecte a los ciudadanos y turistas de Barranquilla con la oferta de eventos de la ciudad, facilitando a los **Asistentes** el descubrimiento, reserva y compra simulada de entradas con tickets digitales protegidos por QR, y a los **Organizadores** la creación, administración, métricas y validación de acceso en puerta mediante cámara en tiempo real.

### 1.2 Problemática Planteada
En Barranquilla, la oferta de eventos culturales, recreativos y gastronómicos suele estar dispersa en redes sociales, sin un sistema centralizado y accesible que garantice la autenticidad de las entradas, la prevención de reventas o fraudes y el control en tiempo real del aforo y las validaciones de acceso.

---

## 2. Especificación de Requerimientos del Sistema

### 2.1 Requerimientos Funcionales (Lo que la aplicación hace)

#### 2.1.1 Gestión de Cuentas y Perfiles
* **RF01 - Registro e Inicio de Sesión:** El sistema permite a los usuarios registrarse ingresando nombre completo, nombre de usuario, correo electrónico y contraseña, e iniciar sesión mediante correo o usuario junto con su contraseña.
* **RF02 - Edición de Perfil:** La aplicación permite a cada usuario consultar y editar su información personal básica (correo electrónico, teléfono y ocupación/rol).

#### 2.1.2 Gestión y Publicación de Eventos (Rol Organizador)
* **RF03 - Creación Completa de Eventos:** El sistema permite al organizador publicar eventos ingresando información detallada: título, categoría temática, fecha, hora de inicio y cierre, lugar con geolocalización, descripción, costo (o marcar como gratuito) e imágenes ilustrativas.
* **RF04 - Control de Aforo Inicial:** El organizador puede definir un límite máximo de cupos disponibles para cada evento publicado.
* **RF05 - Ciclo de Vida del Evento:** El sistema permite al organizador reprogramar fecha y hora, cancelar o eliminar eventos, disparando notificaciones automáticas inmediatas a todos los usuarios inscritos ante cambios o cancelaciones.
* **RF06 - Estadísticas y Métricas en Tiempo Real:** El organizador cuenta con un panel analítico por evento que muestra: total de inscritos, cupos restantes, visualizaciones acumuladas, recaudo total generado, gráfica de inscripciones por día y calificación promedio.

#### 2.1.3 Búsqueda y Registro a Eventos (Rol Asistente)
* **RF07 - Catálogo, Búsqueda y Filtros:** La aplicación presenta el listado de eventos disponibles y permite buscarlos en tiempo real por nombre o ubicación, además de filtrarlos por categoría temática, fecha y rango de precio.
* **RF08 - Gestión de Favoritos:** El asistente puede marcar eventos de su interés con una estrella para consultarlos rápidamente desde su perfil.
* **RF09 - Registro Rápido con Validación de Cupos:** El sistema permite al asistente inscribirse a un evento en un flujo ágil con confirmación de un solo toque, verificando atómicamente la disponibilidad de cupos para evitar sobreventa.
* **RF10 - Generación de Ticket Digital con QR:** Tras confirmar la reserva o compra, la aplicación emite un ticket digital oficial accesible desde la sección "Mis entradas", equipado con código QR dinámico y candado de seguridad que se desbloquea el día del evento.
* **RF11 - Anulación de Reserva:** El asistente puede cancelar su inscripción previa si no puede asistir, liberando inmediatamente el cupo para otro usuario en la base de datos.
* **RF12 - Calificación y Reseña:** El asistente puede calificar con estrellas (1 a 5) los eventos a los que asistió una vez finalizados.

#### 2.1.4 Control de Cupos y Aforo
* **RF13 - Balance de Cupos en Vivo:** La aplicación calcula y actualiza en tiempo real la cantidad de asistentes registrados frente al aforo total configurado.
* **RF14 - Resumen Global del Organizador:** Panel general que consolida los eventos activos del organizador, el total global de asistentes, el porcentaje de ocupación promedio y la valoración global de su perfil.

#### 2.1.5 Comunicación y Notificaciones
* **RF15 - Notificaciones al Asistente:** Alertas internas y push al celular cuando su inscripción es confirmada, cuando un evento cambia de horario o se cancela, y recordatorios para calificar tras el evento.
* **RF16 - Notificaciones al Organizador:** Alertas automáticas cada vez que un nuevo asistente adquiere una entrada para sus eventos.

---

### 2.2 Requerimientos No Funcionales

| Criterio | Requerimiento No Funcional | Implementación en EventBQ |
| :--- | :--- | :--- |
| **Usabilidad** | La interfaz debe ser altamente intuitiva, con menús claros y botones visibles, permitiendo completar el registro a un evento en un máximo de 3 pasos. | Flujo optimizado: Explorar -> Detalle -> Confirmar inscripción. Interfaz diseñada con Material 3, navegación por pestañas inferiores y avisos claros de confirmación. |
| **Accesibilidad y Compatibilidad** | Solución multiplataforma compatible con los sistemas operativos móviles más utilizados (Android e iOS) y web. | Desarrollada con el framework Flutter, permitiendo compilación nativa en Android (APK / App Bundle), iOS y entornos Web responsivos. |
| **Rendimiento** | El sistema de escaneo y validación de entradas en puerta debe procesar el acceso en máximo 3 segundos. | Integración de mobile_scanner con transacción atómica en Firestore optimizada que valida el ticket y registra el check-in en menos de 1.5 segundos. |
| **Seguridad** | Protección de datos personales mediante contraseñas seguras y garantía de que los códigos de tickets no puedan duplicarse ni falsificarse. | Cifrado de contraseñas mediante Firebase Authentication, reglas de seguridad estrictas en firestore.rules y generación de tickets con códigos criptográficos aleatorios de 24 caracteres (Random.secure()). |
| **Escalabilidad** | Arquitectura estructurada para soportar crecimiento masivo de usuarios y futura integración de pasarelas de pago externas. | Base de datos distribuida en Cloud Firestore, arquitectura por capas desacoplada con GetX Controllers y Repositories, facilitando la conexión a pasarelas como Wompi o PSE. |

---

## 3. Tecnologías Utilizadas

* **Framework:** [Flutter](https://flutter.dev) (v3.x / Dart v3.x)
* **Gestión de Estado y Controladores:** [GetX](https://pub.dev/packages/get) (GetxController, reactividad con .obs)
* **Backend y Base de Datos:**
  * **Firebase Authentication:** Gestión de cuentas y sesiones seguras.
  * **Cloud Firestore:** Base de datos NoSQL reactiva en tiempo real con transacciones atómicas (runTransaction).
  * **Firebase Cloud Messaging (FCM HTTP v1):** Envío y recepción de Push Notifications.
* **Persistencia Local:** [SharedPreferences](https://pub.dev/packages/shared_preferences) bajo el patrón Singleton para almacenar la sesión activa (usuario_activo), estado de onboarding y caché sin conexión.
* **Hardware e Interoperabilidad Móvil:**
  * **Mobile Scanner:** Acceso al lente de la cámara física para escaneo de códigos QR.
  * **QR Flutter:** Renderizado vectorial y matricial de códigos QR.
  * **Flutter Map & LatLong2:** Mapas interactivos basados en OpenStreetMap.
  * **Printing & PDF:** Generación y exportación de tickets en formato PDF.

---

## 4. Arquitectura Implementada

El proyecto implementa una **Arquitectura en Capas Limpia (Separation of Concerns)** que garantiza desacoplamiento, alta cohesión y testeabilidad:

```
lib/
├── config/            # Credenciales seguras (FCM Service Account)
├── controllers/       # Capa de Gestión de Estado (GetX Controllers)
│   ├── auth_controller.dart     # Estado reactivo de usuario y sesión
│   └── evento_controller.dart   # Estado reactivo de eventos, filtros y CRUD
├── models/            # Modelos POO (Clases, constructores, toJson / fromFirestore)
│   ├── evento.dart
│   ├── usuario.dart
│   └── notificacion.dart
├── preferences/       # Persistencia local (SharedPreferences + Singleton)
│   └── preferencias_usuario.dart
├── repositories/      # Capa de Acceso a Datos (Firebase + Caché en Memoria)
│   ├── evento_repository.dart
│   ├── usuario_repository.dart
│   └── notificacion_repository.dart
├── screens/           # Capa de Presentación (Vistas y Pantallas UI)
├── services/          # Servicios externos (Push Notifications, Generador PDF)
├── theme/             # Guía de estilos, tipografías y paleta corporativa
└── widgets/           # Componentes visuales reutilizables
```

### Flujo de Datos entre Capas:
1. **Vista (View):** Captura las interacciones del usuario y escucha variables reactivas.
2. **Controlador (GetxController):** Administra el estado de la UI (isLoading.obs, eventos.obs) y coordina las acciones.
3. **Repositorio (Repository):** Implementado con el patrón Singleton, centraliza la comunicación con Cloud Firestore, Firebase Auth y SharedPreferences.

---

## 5. Persistencia Local – SharedPreferences (Patrón Singleton)

La persistencia en el dispositivo se encuentra encapsulada en [`lib/preferences/preferencias_usuario.dart`](file:///c:/proyectos/eventbq/lib/preferences/preferencias_usuario.dart):
* **Inicialización única:** Se ejecuta en `main()` mediante `await PreferenciasUsuario.init()`.
* **Gestión de Sesión:** Guarda y recupera la clave `'usuario_activo'`. Al cerrar sesión, ejecuta `_prefs.remove()`.
* **Onboarding y Tutorial:** Almacena el flag booleano `'onboarding_completado'`.
* **Caché Fuera de Línea:** Métodos `guardarTexto()`, `leerTexto()`, `guardarLista()` y `eliminar()`.

---

## 6. Configuración de Firebase y Reglas de Seguridad

### 6.1 Servicios Configurados
* **Archivo de Inicialización:** [`lib/firebase_options.dart`](file:///c:/proyectos/eventbq/lib/firebase_options.dart) inicializado en `main.dart` con `Firebase.initializeApp()`.
* **FCM Background Handler:** Función `@pragma('vm:entry-point')` para procesar notificaciones con la app cerrada.
* **Canal Android:** `AndroidNotificationChannel` configurado con `Importance.max` y sonido activo.

### 6.2 Reglas de Seguridad (`firestore.rules`)
Las reglas del servidor protegen los datos contra accesos no autorizados:
* **`users/{uid}`:** Lectura para usuarios autenticados; edición restringida exclusivamente al dueño del perfil (`request.auth.uid == uid`).
* **`events/{eventoId}`:** Lectura pública para usuarios autenticados; creación para usuarios registrados; borrado y reprogramación exclusivo del creador del evento (`resource.data.creadorId == request.auth.uid`).
* **`inscripciones/{id}`:** Transacciones atómicas de check-in exclusivas del organizador y creación restringida al asistente legítimo.

---

## 7. Instrucciones de Instalación y Ejecución

### 7.1 Prerrequisitos
* **Flutter SDK:** versión `>= 3.0.0`
* **Dart SDK:** versión `>= 3.0.0`
* **Dispositivo Android / Emulador:** con Android 6.0 o superior (API level >= 23).
* **Navegador Web:** Chrome (para ejecución en Flutter Web).

### 7.2 Pasos para Ejecutar el Proyecto

1. **Clonar o descomprimir el repositorio:**
   ```bash
   cd c:/proyectos/eventbq
   ```

2. **Instalar las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar en modo Desarrollo:**
   * En el navegador Chrome:
     ```bash
     flutter run -d chrome
     ```
   * En un celular o emulador Android:
     ```bash
     flutter run
     ```

4. **Compilar el archivo APK de Producción:**
   ```bash
   flutter build apk --release --android-skip-build-dependency-validation
   ```
   *El archivo instalable se genera en: `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 8. Datos del Proyecto
* **Asignatura:** Desarrollo de Aplicaciones Móviles
* **Institución:** Universidad Libre
* **Versión:** 1.0.0+1
