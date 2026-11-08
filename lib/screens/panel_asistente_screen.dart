import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/dialogo_anular_inscripcion.dart';
import '../widgets/dialogo_politica_reembolso.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/pantalla_con_barra.dart';
import '../utils/manejo_errores.dart';

/// "Panel de Asistente": las entradas que compró el usuario.
/// Se abre desde Mis eventos > Mis Entradas Compradas.
class PanelAsistenteScreen extends StatefulWidget {
  const PanelAsistenteScreen({super.key});

  @override
  State<PanelAsistenteScreen> createState() => _PanelAsistenteScreenState();
}

class _PanelAsistenteScreenState extends State<PanelAsistenteScreen> {
  final _eventoRepo = EventoRepository();

  /// Anular una entrada concreta: confirmación -> nota de reembolso -> panel actualizado.
  Future<void> _anularReserva(Evento evento, [String? idInscripcion]) async {
    final confirmo = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => DialogoAnularInscripcion(evento: evento),
    );
    if (confirmo != true || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (_) => const DialogoPoliticaReembolso(),
    );
    if (!mounted) return;

    // Se anula únicamente la entrada específica seleccionada y se libera el cupo en Firestore
    final error = await _eventoRepo.anularEntrada(evento.id, idInscripcion);
    if (!mounted) return;
    if (error != null) {
      mostrarDialogoError(context, error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final misInscripciones = _eventoRepo.obtenerTodasMisInscripciones();
    final eventosComprados = _eventoRepo.obtenerEntradasCompradas();

    return PantallaConBarra(
      indiceActual: 2, // Mis eventos
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            // Con poco contenido, el mensaje "sin eventos" queda centrado.
            final minAlto = c.maxHeight > 138 ? c.maxHeight - 138 : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minAlto),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EncabezadoUsuario(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back,
                                color: Colores.azulOscuro, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Panel de Asistente',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulOscuro,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mis entradas',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colores.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (misInscripciones.isEmpty && eventosComprados.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Sin eventos a los que asistir',
                              style: TextStyle(
                                  fontSize: 13, color: Colores.grisTexto),
                            ),
                          ),
                        )
                      else if (misInscripciones.isNotEmpty) ...[
                        ...misInscripciones.map((insc) {
                          final e = _eventoRepo.obtenerEventoPorId(insc.eventoId) ??
                              Evento(
                                id: insc.eventoId,
                                titulo: 'Evento',
                                categoria: 'General',
                                fechaCompleta: '',
                                dia: '',
                                mes: '',
                                lugar: '',
                                precio: insc.precioPagado,
                                imagen: '',
                              );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _TarjetaEntrada(
                              evento: e,
                              inscripcion: insc,
                              onVerTicket: () => Navigator.pushNamed(
                                context,
                                '/ticket',
                                arguments: {
                                  'evento': e,
                                  'inscripcion': insc,
                                },
                              ),
                              onAnular: () => _anularReserva(e, insc.id),
                            ),
                          );
                        }),
                      ] else ...[
                        ...eventosComprados.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _TarjetaEntrada(
                              evento: e,
                              onVerTicket: () => Navigator.pushNamed(
                                context,
                                '/ticket',
                                arguments: e,
                              ),
                              onAnular: () => _anularReserva(e),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaEntrada extends StatelessWidget {
  final Evento evento;
  final Inscripcion? inscripcion;
  final VoidCallback onVerTicket;
  final VoidCallback onAnular;

  const _TarjetaEntrada({
    required this.evento,
    this.inscripcion,
    required this.onVerTicket,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final codigoCorto = inscripcion != null && inscripcion!.codigo.isNotEmpty
        ? (inscripcion!.codigo.length > 8
            ? inscripcion!.codigo.substring(0, 8)
            : inscripcion!.codigo)
        : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ImagenAsset(
                      ruta: evento.imagenParaDetalle,
                      rutaRespaldo: evento.imagen,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  evento.titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF55555F),
                    height: 1.25,
                  ),
                ),
                if (codigoCorto.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ticket #$codigoCorto • ${inscripcion?.estado ?? "Activa"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.black38),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            child: Column(
              children: [
                _boton(
                  texto: 'Ver ticket',
                  fondo: const Color(0xFFB4C3A9),
                  colorTexto: Colores.azulOscuro,
                  onTap: onVerTicket,
                ),
                const SizedBox(height: 8),
                _boton(
                  texto: 'Anular reserva',
                  fondo: const Color(0xFFE04A3A),
                  colorTexto: Colors.white,
                  onTap: onAnular,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boton({
    required String texto,
    required Color fondo,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: colorTexto,
          elevation: 2,
          shadowColor: Colors.black38,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
