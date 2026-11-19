import 'package:flutter/material.dart' show TimeOfDay;
import 'package:get/get.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';

/// Controlador de eventos e inscripciones usando GetX.
///
/// Implementa la gestión de estado reactiva de la lista de eventos,
/// filtros por categoría, búsqueda y operaciones CRUD mediante [EventoRepository].
class EventoController extends GetxController {
  final EventoRepository _eventoRepo = EventoRepository();

  // ----- Variables reactivas (.obs) -----
  final RxList<Evento> eventos = <Evento>[].obs;
  final RxList<Inscripcion> misInscripciones = <Inscripcion>[].obs;
  final RxString categoriaFiltro = 'Todos'.obs;
  final RxString textoBusqueda = ''.obs;
  final RxBool cargando = false.obs;
  final RxString errorMensaje = ''.obs;

  @override
  void onInit() {
    super.onInit();
    cargarDatos();
  }

  /// Carga inicial de eventos y entradas sincronizada con el Repositorio
  void cargarDatos() {
    cargando.value = true;
    try {
      eventos.value = _eventoRepo.obtenerEventosExplorar();
      misInscripciones.value = _eventoRepo.obtenerTodasMisInscripciones();
    } finally {
      cargando.value = false;
    }
  }

  /// Filtra la lista de eventos en memoria según búsqueda y categoría
  List<Evento> get eventosFiltrados {
    return eventos.where((e) {
      final coincideCategoria = categoriaFiltro.value == 'Todos' ||
          e.categoria.toLowerCase() == categoriaFiltro.value.toLowerCase();
      final coincideTexto = textoBusqueda.value.isEmpty ||
          e.titulo.toLowerCase().contains(textoBusqueda.value.toLowerCase()) ||
          e.lugar.toLowerCase().contains(textoBusqueda.value.toLowerCase());
      return coincideCategoria && coincideTexto;
    }).toList();
  }

  /// Actualiza el filtro de categoría reactivo
  void cambiarCategoria(String nuevaCategoria) {
    categoriaFiltro.value = nuevaCategoria;
  }

  /// Actualiza el texto de búsqueda reactivo
  void actualizarBusqueda(String query) {
    textoBusqueda.value = query.trim();
  }

  /// Inscripción atómica a un evento (CRUD - Create)
  Future<bool> inscribirse({
    required Evento evento,
    String? metodoPago,
    String? referenciaPago,
  }) async {
    cargando.value = true;
    errorMensaje.value = '';
    try {
      final error = await _eventoRepo.agregarEntrada(
        evento,
        metodoPago: metodoPago,
        referenciaPago: referenciaPago,
      );
      if (error != null) {
        errorMensaje.value = error;
        return false;
      }
      cargarDatos();
      return true;
    } catch (e) {
      errorMensaje.value = 'Error al inscribirse: $e';
      return false;
    } finally {
      cargando.value = false;
    }
  }

  /// Anula una entrada o reserva (CRUD - Delete)
  Future<bool> anularEntrada(String idEvento, [String? idInscripcion]) async {
    cargando.value = true;
    try {
      final error = await _eventoRepo.anularEntrada(idEvento, idInscripcion);
      if (error != null) {
        errorMensaje.value = error;
        return false;
      }
      cargarDatos();
      return true;
    } catch (e) {
      errorMensaje.value = 'Error al anular: $e';
      return false;
    } finally {
      cargando.value = false;
    }
  }

  /// Reprograma la fecha u hora de un evento (CRUD - Update)
  Future<bool> reprogramar({
    required String idEvento,
    required DateTime nuevaFecha,
    required TimeOfDay inicio,
    required TimeOfDay cierre,
  }) async {
    cargando.value = true;
    try {
      await _eventoRepo.reprogramarEvento(idEvento, nuevaFecha, inicio, cierre);
      cargarDatos();
      return true;
    } catch (e) {
      errorMensaje.value = 'Error al reprogramar: $e';
      return false;
    } finally {
      cargando.value = false;
    }
  }

  /// Cancela un evento de forma definitiva (CRUD - Update/Delete)
  Future<bool> cancelar(String idEvento) async {
    cargando.value = true;
    try {
      await _eventoRepo.cancelarEvento(idEvento);
      cargarDatos();
      return true;
    } catch (e) {
      errorMensaje.value = 'Error al cancelar: $e';
      return false;
    } finally {
      cargando.value = false;
    }
  }
}
