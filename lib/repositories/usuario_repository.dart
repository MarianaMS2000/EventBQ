import '../data/datos_simulados.dart';
import '../models/usuario.dart';
import '../preferences/preferencias_usuario.dart';

/// Sin backend: el login acepta cualquier usuario/contraseña NO vacíos.
/// Cuando exista backend, aquí se cambia la validación por una llamada a la API.
class UsuarioRepository {
  /// Lo guardado en SharedPreferences tiene prioridad; lo que falte sale de los datos simulados.
  Usuario obtenerUsuarioActual() {
    final base = datosUsuarioPorDefecto;
    return Usuario(
      nombre: _o(PreferenciasUsuario.nombre, base.nombre),
      usuario: _o(PreferenciasUsuario.usuario, base.usuario),
      correo: _o(PreferenciasUsuario.correo, base.correo),
      foto: base.foto,
      telefono: _o(PreferenciasUsuario.telefono, base.telefono),
      rol: _o(PreferenciasUsuario.rol, base.rol),
      miembroDesde: base.miembroDesde,
      eventosAsistidos: base.eventosAsistidos,
      eventosCreados: base.eventosCreados,
      rating: base.rating,
    );
  }

  String _o(String guardado, String porDefecto) {
    return guardado.isEmpty ? porDefecto : guardado;
  }

  bool iniciarSesion(String usuarioOCorreo, String clave) {
    if (usuarioOCorreo.trim().isEmpty || clave.isEmpty) return false;
    if (PreferenciasUsuario.usuario.isEmpty) {
      PreferenciasUsuario.usuario = usuarioOCorreo.trim();
    }
    PreferenciasUsuario.sesionIniciada = true;
    return true;
  }

  void registrar({
    required String nombre,
    required String usuario,
    required String correo,
    required String clave,
  }) {
    PreferenciasUsuario.nombre = nombre.trim();
    PreferenciasUsuario.usuario = usuario.trim();
    PreferenciasUsuario.correo = correo.trim();
    PreferenciasUsuario.sesionIniciada = true;
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
