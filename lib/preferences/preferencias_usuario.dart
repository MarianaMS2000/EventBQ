import 'package:shared_preferences/shared_preferences.dart';

/// Clase central para SharedPreferences.
/// Se inicializa una sola vez en main() con: await PreferenciasUsuario.init();
class PreferenciasUsuario {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Claves ----
  static const _kSesion = 'sesion_iniciada';
  static const _kOnboarding = 'onboarding_completado';
  static const _kNombre = 'nombre_completo';
  static const _kUsuario = 'usuario';
  static const _kCorreo = 'correo';
  static const _kTelefono = 'telefono';
  static const _kRol = 'rol';
  static const _kFavoritos = 'eventos_favoritos';

  // ---- Sesión ----
  static bool get sesionIniciada => _prefs.getBool(_kSesion) ?? false;
  static set sesionIniciada(bool valor) => _prefs.setBool(_kSesion, valor);

  // ---- Onboarding (tutorial inicial, solo se ve una vez) ----
  static bool get onboardingCompletado => _prefs.getBool(_kOnboarding) ?? false;
  static set onboardingCompletado(bool valor) =>
      _prefs.setBool(_kOnboarding, valor);

  // ---- Datos básicos del usuario ----
  static String get nombre => _prefs.getString(_kNombre) ?? '';
  static set nombre(String valor) => _prefs.setString(_kNombre, valor);

  static String get usuario => _prefs.getString(_kUsuario) ?? '';
  static set usuario(String valor) => _prefs.setString(_kUsuario, valor);

  static String get correo => _prefs.getString(_kCorreo) ?? '';
  static set correo(String valor) => _prefs.setString(_kCorreo, valor);

  static String get telefono => _prefs.getString(_kTelefono) ?? '';
  static set telefono(String valor) => _prefs.setString(_kTelefono, valor);

  static String get rol => _prefs.getString(_kRol) ?? '';
  static set rol(String valor) => _prefs.setString(_kRol, valor);

  // ---- Favoritos (ids de eventos con el corazón activado) ----
  static List<String> get favoritos => _prefs.getStringList(_kFavoritos) ?? [];

  static bool esFavorito(String idEvento) => favoritos.contains(idEvento);

  static Future<void> alternarFavorito(String idEvento) async {
    final lista = favoritos;
    if (lista.contains(idEvento)) {
      lista.remove(idEvento);
    } else {
      lista.add(idEvento);
    }
    await _prefs.setStringList(_kFavoritos, lista);
  }

  /// Borra todo lo guardado (por si lo necesitas para pruebas).
  static Future<void> borrarTodo() async {
    await _prefs.clear();
  }
}
