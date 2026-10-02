import '../data/datos_simulados.dart';
import '../models/evento.dart';
import '../models/filtros_evento.dart';
import '../preferences/preferencias_usuario.dart';

/// Las pantallas piden los eventos aquí. Hoy salen de datos simulados;
/// mañana pueden salir de un backend cambiando solo esta clase.
class EventoRepository {
  List<Evento> obtenerEventosTop() {
    return datosEventosTop;
  }

  List<Evento> obtenerEventosExplorar() {
    return datosEventosExplorar;
  }

  List<Evento> obtenerEventosDeOrganizador() {
    return datosEventosOrganizador;
  }

  Evento? obtenerEventoPorId(String id) {
    final todos = [
      ...datosEventosTop,
      ...datosEventosExplorar,
      ...datosEventosOrganizador,
    ];
    for (final e in todos) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Busca por texto y aplica los filtros de categoría, fecha (solo "Hoy") y precio.
  List<Evento> buscarEventos(String texto, {FiltrosEvento? filtros}) {
    final t = texto.toLowerCase().trim();
    return datosEventosExplorar.where((e) {
      if (t.isNotEmpty && !e.titulo.toLowerCase().contains(t)) return false;
      if (filtros != null) {
        if (filtros.categorias.isNotEmpty &&
            !filtros.categorias.contains(e.categoria)) {
          return false;
        }
        // Fecha: por ahora solo "Hoy" filtra (usa el dato simulado esHoy).
        // "Esta semana" y "Este mes" se aplicarán cuando existan fechas reales.
        if (filtros.fecha == 'Hoy' && !e.esHoy) return false;
        if (filtros.precio == 'Gratis' && !e.esGratis) return false;
        if (filtros.precio == 'De pago' && e.esGratis) return false;
      }
      return true;
    }).toList();
  }

  /// Eventos con el corazón activado (sin repetir).
  List<Evento> obtenerFavoritos() {
    final vistos = <String>{};
    final resultado = <Evento>[];
    final todos = [
      ...datosEventosTop,
      ...datosEventosExplorar,
      ...datosEventosOrganizador,
    ];
    for (final e in todos) {
      if (vistos.contains(e.id)) continue;
      vistos.add(e.id);
      if (PreferenciasUsuario.esFavorito(e.id)) resultado.add(e);
    }
    return resultado;
  }

  List<String> obtenerCategoriasFiltro() {
    return datosCategoriasFiltro;
  }

  List<String> obtenerOpcionesFecha() {
    return datosOpcionesFecha;
  }

  bool esFavorito(String idEvento) {
    return PreferenciasUsuario.esFavorito(idEvento);
  }

  Future<void> alternarFavorito(String idEvento) {
    return PreferenciasUsuario.alternarFavorito(idEvento);
  }
}
