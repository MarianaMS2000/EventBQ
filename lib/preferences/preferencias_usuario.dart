import 'package:shared_preferences/shared_preferences.dart';

/// Clase central para SharedPreferences.
/// Se inicializa una sola vez en main() con: await PreferenciasUsuario.init();
///
/// Aquí vive TODO lo que se guarda en el celular:
///  - sesión activa (qué usuario está dentro)
///  - datos por usuario (onboarding, favoritos) -> la clave lleva el usuario
///  - lectura/escritura de texto y listas para los repositorios
///    (cuentas, eventos, notificaciones, entradas...)
class PreferenciasUsuario {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Claves ----
  static const _kUsuarioActivo = 'usuario_activo';
  static const _kOnboarding = 'onboarding_completado';
  static const _kFavoritos = 'eventos_favoritos';

  // ---- Sesión ----
  /// Id del usuario que tiene la sesión abierta ('' = nadie).
  static String get usuarioActual => _prefs.getString(_kUsuarioActivo) ?? '';

  static set usuarioActual(String id) {
    if (id.isEmpty) {
      _prefs.remove(_kUsuarioActivo);
    } else {
      _prefs.setString(_kUsuarioActivo, id);
    }
  }

  static bool get sesionIniciada => usuarioActual.isNotEmpty;

  /// Clave que pertenece a un usuario concreto: "favoritos__connor".
  static String claveDe(String base, String idUsuario) => '${base}__$idUsuario';

  /// Clave del usuario con sesión abierta.
  static String clave(String base) => claveDe(base, usuarioActual);

  // ---- Onboarding (tutorial inicial, una vez por cuenta) ----
  static bool get onboardingCompletado =>
      _prefs.getBool(clave(_kOnboarding)) ?? false;
  static set onboardingCompletado(bool valor) =>
      _prefs.setBool(clave(_kOnboarding), valor);

  // ---- Favoritos (ids de eventos con el corazón activado) ----
  static List<String> get favoritos =>
      List<String>.from(_prefs.getStringList(clave(_kFavoritos)) ?? const []);

  static bool esFavorito(String idEvento) => favoritos.contains(idEvento);

  static Future<void> alternarFavorito(String idEvento) async {
    final lista = favoritos;
    if (lista.contains(idEvento)) {
      lista.remove(idEvento);
    } else {
      lista.add(idEvento);
    }
    await _prefs.setStringList(clave(_kFavoritos), lista);
  }

  // ---- Lectura / escritura genérica (la usan los repositorios) ----
  static String? leerTexto(String clave) => _prefs.getString(clave);

  static Future<bool> guardarTexto(String clave, String valor) =>
      _prefs.setString(clave, valor);

  static List<String> leerLista(String clave) =>
      List<String>.from(_prefs.getStringList(clave) ?? const []);

  static Future<bool> guardarLista(String clave, List<String> valor) =>
      _prefs.setStringList(clave, valor);

  static bool leerBool(String clave) => _prefs.getBool(clave) ?? false;

  static Future<bool> guardarBool(String clave, bool valor) =>
      _prefs.setBool(clave, valor);

  /// Borra todo lo guardado (por si lo necesitas para pruebas).
  static Future<void> borrarTodo() async {
    await _prefs.clear();
  }
}
