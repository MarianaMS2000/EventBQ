import '../data/datos_simulados.dart';
import '../models/evento.dart';
import '../models/organizador.dart';
import 'evento_repository.dart';
import 'usuario_repository.dart';

class OrganizadorRepository {
  /// Organizador de ejemplo (el de los eventos de muestra).
  Organizador obtenerOrganizador() => datosOrganizador;

  /// Organizador de un evento: si lo creó un usuario de la app, sus datos
  /// salen de su cuenta; si es un evento de muestra, el organizador de ejemplo.
  Organizador obtenerParaEvento(Evento e) {
    if (e.creadorId.isEmpty) return datosOrganizador;
    final u = UsuarioRepository().obtenerPorId(e.creadorId);
    if (u == null) return datosOrganizador;
    final repo = EventoRepository();
    final suyos = repo.obtenerEventosDeCreador(u.id);
    return Organizador(
      id: u.id,
      nombre: u.nombre,
      rol: u.rol.isEmpty ? 'Organizador de eventos' : u.rol,
      foto: u.foto,
      correo: u.correo,
      telefono: u.telefono,
      miembroDesde: u.miembroDesde,
      eventos: suyos.length,
      asistentes: suyos.fold(0, (s, ev) => s + ev.inscritos),
      rating: repo.ratingDeCreador(u.id),
    );
  }
}
