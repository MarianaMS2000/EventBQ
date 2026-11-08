import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Excepción de validación de negocio pensada para mostrarse amablemente al usuario.
class ValidacionException implements Exception {
  final String mensaje;
  final String? titulo;
  const ValidacionException(this.mensaje, {this.titulo});

  @override
  String toString() => mensaje;
}

/// Convierte cualquier excepción técnica o de Firebase en un mensaje amigable en español.
/// Registra el detalle técnico con [debugPrint] para que nunca llegue texto crudo al usuario.
String traducirError(dynamic error) {
  if (error == null) return 'Ocurrió un error inesperado';

  // Si ya es un mensaje limpio de validación de la app
  if (error is ValidacionException) {
    return error.mensaje;
  }

  final textoOriginal = error.toString();
  debugPrint('[DIAGNÓSTICO TÉCNICO]: $textoOriginal');

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return 'No existe una cuenta con esos datos. Regístrate primero.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Usuario o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado en otra cuenta.';
      case 'invalid-email':
        return 'Escribe un correo electrónico válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada. Contacta al soporte.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta nuevamente en unos minutos.';
      case 'network-request-failed':
        return 'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión antes de realizar esta acción.';
      default:
        return 'No se pudo completar la autenticación. Inténtalo de nuevo.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta acción o tu sesión expiró.';
      case 'unavailable':
        return 'El servicio no está disponible en este momento. Revisa tu conexión a internet.';
      case 'deadline-exceeded':
        return 'La operación tardó demasiado. Comprueba tu conexión a internet.';
      case 'not-found':
        return 'El recurso solicitado ya no existe o fue eliminado.';
      case 'already-exists':
        return 'Este registro ya existe en el sistema.';
      case 'resource-exhausted':
        return 'Se alcanzó el límite de operaciones. Intenta más tarde.';
      case 'invalid-argument':
        if (textoOriginal.contains('exceeds the maximum allowed size') ||
            textoOriginal.contains('cannot be written because its size')) {
          return 'El contenido o las imágenes son demasiado pesados. Elige imágenes más livianas.';
        }
        return 'Los datos enviados no son válidos.';
      default:
        return 'Algo salió mal. Inténtalo de nuevo en un momento.';
    }
  }

  if (error is SocketException) {
    return 'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.';
  }

  // Errores comunes de texto
  if (textoOriginal.contains('exceeds the maximum allowed size') ||
      textoOriginal.contains('cannot be written because its size') ||
      textoOriginal.contains('too large') ||
      textoOriginal.contains('pesada')) {
    return 'Esa imagen es demasiado pesada. Elige una más liviana.';
  }

  if (textoOriginal.contains('permission-denied') ||
      textoOriginal.contains('insufficient permissions')) {
    return 'No tienes permisos para realizar esta acción o tu sesión expiró.';
  }

  if (textoOriginal.contains('SocketException') ||
      textoOriginal.contains('NetworkError') ||
      textoOriginal.contains('Failed to fetch') ||
      textoOriginal.contains('network-request-failed')) {
    return 'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.';
  }

  // Mensaje por defecto genérico y amable
  return 'Algo salió mal. Inténtalo de nuevo en un momento.';
}

/// Muestra una ventana flotante (diálogo) moderna y consistente con el estilo de EventBQ.
///
/// Tiene esquinas redondeadas (24), ícono de advertencia/error sutil en azul oscuro,
/// título claro, mensaje en español y un único botón "Entendido".
Future<void> mostrarDialogoError(
  BuildContext context, {
  String? titulo,
  required dynamic error,
}) async {
  if (!context.mounted) return;

  final mensaje = error is String ? error : traducirError(error);
  final tituloFinal = titulo ??
      (error is ValidacionException && error.titulo != null
          ? error.titulo!
          : 'Aviso');

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colores.azulOscuro,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tituloFinal,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colores.grisTexto,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colores.azulOscuro,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Estima el tamaño en bytes de un mapa que se guardará en Firestore.
/// Firestore calcula el tamaño como la suma de nombres de campos, valores y sobrecarga.
int estimarTamanoDocumentoFirestore(Map<String, dynamic> data) {
  int bytes = 32; // sobrecarga básica de documento
  data.forEach((k, v) {
    bytes += k.length + 1;
    if (v == null) {
      bytes += 1;
    } else if (v is String) {
      bytes += v.length + 1;
    } else if (v is num) {
      bytes += 8;
    } else if (v is bool) {
      bytes += 1;
    } else if (v is Timestamp) {
      bytes += 8;
    } else if (v is GeoPoint) {
      bytes += 16;
    } else if (v is List) {
      bytes += 8;
      for (final item in v) {
        if (item is String) bytes += item.length + 1;
        if (item is Map<String, dynamic>) {
          bytes += estimarTamanoDocumentoFirestore(item);
        }
      }
    } else if (v is Map<String, dynamic>) {
      bytes += estimarTamanoDocumentoFirestore(v);
    }
  });
  return bytes;
}
