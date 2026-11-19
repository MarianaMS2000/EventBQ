import 'package:get/get.dart';
import '../models/usuario.dart';
import '../preferences/preferencias_usuario.dart';
import '../repositories/usuario_repository.dart';

/// Controlador de autenticación y sesión de usuario usando GetX.
///
/// Gestiona el estado reactivo de la sesión (usuario autenticado, carga y errores)
/// conectándose con el repositorio [UsuarioRepository] y [PreferenciasUsuario].
class AuthController extends GetxController {
  final UsuarioRepository _usuarioRepo = UsuarioRepository();

  // ----- Variables reactivas (.obs) -----
  final Rx<Usuario?> usuario = Rx<Usuario?>(null);
  final RxBool estaAutenticado = false.obs;
  final RxBool cargando = false.obs;
  final RxString errorMensaje = ''.obs;

  @override
  void onInit() {
    super.onInit();
    sincronizarEstado();
  }

  /// Sincroniza el estado reactivo con SharedPreferences y el Repositorio
  void sincronizarEstado() {
    estaAutenticado.value = PreferenciasUsuario.sesionIniciada;
    if (estaAutenticado.value) {
      usuario.value = _usuarioRepo.obtenerUsuarioActual();
    } else {
      usuario.value = null;
    }
  }

  /// Inicia sesión con correo/username y contraseña
  Future<bool> iniciarSesion(String correoOUser, String password) async {
    cargando.value = true;
    errorMensaje.value = '';
    try {
      final error = await _usuarioRepo.iniciarSesion(correoOUser, password);
      if (error != null) {
        errorMensaje.value = error;
        return false;
      }
      sincronizarEstado();
      return true;
    } catch (e) {
      errorMensaje.value = 'Error al iniciar sesión: $e';
      return false;
    } finally {
      cargando.value = false;
    }
  }

  /// Registra una nueva cuenta de usuario
  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    String? username,
  }) async {
    cargando.value = true;
    errorMensaje.value = '';
    try {
      final error = await _usuarioRepo.registrar(
        nombre: nombre,
        usuario: username ?? correo.split('@').first,
        correo: correo,
        clave: password,
      );
      if (error != null) {
        errorMensaje.value = error;
        return false;
      }
      sincronizarEstado();
      return true;
    } catch (e) {
      errorMensaje.value = 'Error en el registro: $e';
      return false;
    } finally {
      cargando.value = false;
    }
  }

  /// Cierra la sesión activa y limpia SharedPreferences
  Future<void> cerrarSesion() async {
    cargando.value = true;
    try {
      await _usuarioRepo.cerrarSesion();
      usuario.value = null;
      estaAutenticado.value = false;
    } finally {
      cargando.value = false;
    }
  }
}
