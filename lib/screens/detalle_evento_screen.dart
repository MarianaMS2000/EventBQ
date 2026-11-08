import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/evento.dart';
import '../models/organizador.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../repositories/organizador_repository.dart';
import '../theme/colores.dart';
import '../widgets/agenda_timeline.dart';
import '../widgets/dialogo_confirmar_asistencia.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/mapa_evento.dart';
import '../widgets/pantalla_con_barra.dart';
import '../utils/manejo_errores.dart';

/// Recibe el Evento como argumento:
/// Navigator.pushNamed(context, '/detalle-evento', arguments: evento);
class DetalleEventoScreen extends StatefulWidget {
  const DetalleEventoScreen({super.key});

  @override
  State<DetalleEventoScreen> createState() => _DetalleEventoScreenState();
}

class _DetalleEventoScreenState extends State<DetalleEventoScreen> {
  final _eventoRepo = EventoRepository();
  bool _visitaContada = false;
  bool _reservando = false;
  bool _imagenesCargadas = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ev = _obtenerEvento();
    if (!_visitaContada) {
      _visitaContada = true;
      _eventoRepo.registrarVisualizacion(ev);
    }
    if (!_imagenesCargadas) {
      _imagenesCargadas = true;
      _cargarImagenesGrandes(ev);
    }
  }

  Future<void> _cargarImagenesGrandes(Evento e) async {
    if (e.imagen.startsWith('base64:') || e.imagenDetalle == 'subcoleccion:detalle') {
      final p = await _eventoRepo.obtenerImagenGrande(e.id, 'portada');
      final d = await _eventoRepo.obtenerImagenGrande(e.id, 'detalle');
      if (!mounted) return;
      if (p != null || d != null) {
        setState(() {
          if (p != null) e.imagenPortadaCompleta = p;
          if (d != null) e.imagenDetalleCompleta = d;
        });
      }
    }
  }

  Evento _obtenerEvento() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Evento) return args;
    return _eventoRepo.obtenerEventosExplorar()[2]; // respaldo
  }

  Future<void> _inscribirse(Evento evento) async {
    if (_reservando) return;

    if (evento.haFinalizado) {
      mostrarDialogoError(
        context,
        titulo: 'Evento finalizado',
        error: 'Este evento ya finalizó.',
      );
      return;
    }

    final confirmado = await mostrarDialogoConfirmarAsistencia(context, evento);
    if (!confirmado || !mounted) return;

    setState(() => _reservando = true);
    try {
      final error = await _eventoRepo.agregarEntrada(evento);
      if (!mounted) return;
      if (error != null) {
        mostrarDialogoError(context, error: error);
        return;
      }

      final ultimaInscripcion = _eventoRepo.obtenerUltimaInscripcion(evento.id);
      Navigator.pushReplacementNamed(
        context,
        '/registro-exitoso',
        arguments: {
          'evento': evento,
          'inscripcion': ultimaInscripcion,
        },
      );
    } catch (e) {
      if (!mounted) return;
      mostrarDialogoError(context, error: e);
    } finally {
      if (mounted) setState(() => _reservando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final inicial = _obtenerEvento();
    final e = _eventoRepo.obtenerEventoPorId(inicial.id) ?? inicial;
    final favorito = _eventoRepo.esFavorito(e.id);
    final organizador = OrganizadorRepository().obtenerParaEvento(e);

    return PantallaConBarra(
      indiceActual: 1,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: EncabezadoUsuario(),
              ),
              // ----- Imagen hero -----
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ImagenAsset(
                        ruta: e.imagenParaDetalle,
                        rutaRespaldo: e.imagen, // si falta la 2.ª, usa la portada
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colores.azulBrillante,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colores.azulBrillante,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e.categoria,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // ----- Título + corazón -----
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.titulo,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulOscuro,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await _eventoRepo.alternarFavorito(e.id);
                            setState(() {});
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colores.azulBrillante,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              favorito ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ----- Fecha y ubicación -----
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _infoBasica(
                            Icons.calendar_today_outlined,
                            'Fecha',
                            e.fechaParaDetalle,
                            e.horarioParaDetalle,
                          ),
                        ),
                        Expanded(
                          child: _infoBasica(
                            Icons.location_on_outlined,
                            'Ubicación',
                            e.lugar,
                            null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _tarjetaOrganizador(organizador),
                    if (e.cuposTotales > 0) ...[
                      const SizedBox(height: 22),
                      _cupos(e),
                    ],
                    const SizedBox(height: 22),
                    _subtitulo('Sobre el evento'),
                    Text(
                      e.descripcion.isEmpty
                          ? 'Pronto tendremos más información sobre este evento.'
                          : e.descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colores.azulOscuro,
                        height: 1.4,
                      ),
                    ),
                    if (e.incluye.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _subtitulo('¿Qué incluye?'),
                      ...e.incluye.map(_itemIncluye),
                    ],
                    const SizedBox(height: 20),
                    _subtitulo('Ubicacion'),
                    if (e.ubicacion != null)
                      MapaDetalleEvento(
                        punto: LatLng(e.ubicacion!.latitude, e.ubicacion!.longitude),
                        lugar: e.lugar,
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colores.azulBrillante, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colores.azulBrillante, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.lugar,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colores.azulOscuro,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (e.agenda.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _subtitulo('Agenda'),
                      AgendaTimeline(items: e.agenda),
                    ],
                    const SizedBox(height: 26),
                    Center(child: _botonEntrada(e)),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.lock_outline, size: 15, color: Colores.grisTexto),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pago protegido · Tu lugar queda\nreservado al instante',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colores.grisTexto),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subtitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colores.azulOscuro,
        ),
      ),
    );
  }

  Widget _infoBasica(IconData icono, String etiqueta, String valor, String? extra) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 22, color: Colores.azulOscuro),
        const SizedBox(height: 6),
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colores.azulOscuro)),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colores.azulOscuro,
          ),
        ),
        if (extra != null)
          Text(extra, style: const TextStyle(fontSize: 11, color: Colores.grisTexto)),
      ],
    );
  }

  Widget _tarjetaOrganizador(Organizador org) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 46,
              height: 46,
              child: org.foto.isNotEmpty
                  ? ImagenAsset(
                      ruta: org.foto,
                      iconoPlaceholder: Icons.person,
                    )
                  : Container(
                      color: const Color(0xFFE8EEF8),
                      child: const Icon(
                        Icons.person,
                        color: Colores.azulOscuro,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
                Text(
                  org.rol,
                  style: const TextStyle(fontSize: 11, color: Colores.azulOscuro),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/perfil-organizador',
              arguments: org,
            ),
            child: const Text(
              'Ver perfil',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colores.azulBrillante,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cupos(Evento e) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cupos disponibles',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
            Text(
              '${e.cuposDisponibles}/${e.cuposTotales}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: e.cuposDisponibles / e.cuposTotales,
            minHeight: 14,
            backgroundColor: Colores.azulMuyClaro,
            valueColor: const AlwaysStoppedAnimation<Color>(Colores.azulBrillante),
          ),
        ),
      ],
    );
  }

  Widget _itemIncluye(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colores.azulBrillante, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 12, color: Colores.azulOscuro, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEntrada(Evento e) {
    final finalizado = e.haFinalizado || e.estado == 'Finalizado';
    final cancelado = e.estado == 'Cancelado';
    final sinCupos = e.cuposTotales > 0 && e.cuposDisponibles <= 0;
    final conteoEntradas = _eventoRepo.contarEntradasDeEvento(e.id);

    final texto = finalizado
        ? 'Este evento ya finalizó'
        : cancelado
            ? 'Evento cancelado'
            : sinCupos
                ? 'Sin cupos'
                : e.esGratis
                    ? 'Entrada gratis Aquí'
                    : 'Reservar entrada';

    final habilitado = !finalizado && !cancelado && !sinCupos && !_reservando;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conteoEntradas > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              conteoEntradas == 1
                  ? 'Ya tienes 1 entrada para este evento'
                  : 'Ya tienes $conteoEntradas entradas para este evento',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colores.azulOscuro,
              ),
            ),
          ),
        Container(
          width: 250,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: habilitado
                ? const LinearGradient(
                    colors: [Colores.azulOscuro, Color(0xFF1F2E8C)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF8A93AD), Color(0xFF6B7280)],
                  ),
          ),
          child: TextButton(
            onPressed: habilitado ? () => _inscribirse(e) : null,
            child: _reservando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
