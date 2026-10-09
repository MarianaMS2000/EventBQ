import '../data/datos_simulados.dart';
import '../models/usuario.dart';
import '../preferences/preferencias_usuario.dart';

/// Sin backend: el login acepta cualquier usuario/contraseña NO vacíos.
/// Cuando exista backend, aquí se cambia la validación por una llamada a la API.
class UsuarioRepository {
  /// Solo frontend: todos los datos salen de los datos simulados (Connor Storrie).
  /// Nada de lo que se escriba (registro, login o editar perfil) se guarda ni se
  /// refleja. Cuando haya backend, aquí se pedirá el usuario a la API.
  Usuario obtenerUsuarioActual() => datosUsuarioPorDefecto;

  bool iniciarSesion(String usuarioOCorreo, String clave) {
    if (usuarioOCorreo.trim().isEmpty || clave.isEmpty) return false;
    PreferenciasUsuario.sesionIniciada = true;
    return true;
  }

  void registrar({
    required String nombre,
    required String usuario,
    required String correo,
    required String clave,
  }) {
    // Solo frontend: no se guardan los datos escritos. El perfil vuelve a los
    // datos por defecto (Connor Storrie). Con backend, aquí se crearía la cuenta.
    PreferenciasUsuario.nombre = '';
    PreferenciasUsuario.usuario = '';
    PreferenciasUsuario.correo = '';
    PreferenciasUsuario.telefono = '';
    PreferenciasUsuario.rol = '';
    PreferenciasUsuario.sesionIniciada = true;
    // Cuenta nueva: debe ver el tutorial (onboarding) la primera vez,
    // aunque en este dispositivo ya lo haya visto otra persona/cuenta.
    PreferenciasUsuario.onboardingCompletado = false;
  }

  /// Guarda los campos editables del perfil.
  void actualizarPerfil({
    required String correo,
    required String telefono,
    required String rol,
  }) {
    PreferenciasUsuario.correo = correo.trim();
    PreferenciasUsuario.telefono = telefono.trim();
    PreferenciasUsuario.rol = rol.trim();
  }

  void cerrarSesion() {
    PreferenciasUsuario.sesionIniciada = false;
  }
}
