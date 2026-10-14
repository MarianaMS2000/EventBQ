import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/banner_premium.dart';
import '../widgets/dialogo_anular_inscripcion.dart';
import '../widgets/dialogo_politica_reembolso.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/pantalla_con_barra.dart';

/// "Panel de Asistente": las entradas que compró el usuario.
/// Se abre desde Mis eventos > Mis Entradas Compradas.
class PanelAsistenteScreen extends StatefulWidget {
  const PanelAsistenteScreen({super.key});

  @override
  State<PanelAsistenteScreen> createState() => _PanelAsistenteScreenState();
}

class _PanelAsistenteScreenState extends State<PanelAsistenteScreen> {
  final _eventoRepo = EventoRepository();

  /// Anular reserva: confirmación -> nota de reembolso -> panel actualizado.
  Future<void> _anularReserva(Evento evento) async {
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

    // Se quita de la lista y se guarda: la entrada ya no vuelve a aparecer.
    _eventoRepo.anularEntrada(evento.id);
  }

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final entradas = _eventoRepo.obtenerEntradasCompradas();

    return PantallaConBarra(
      indiceActual: 2, // Mis eventos
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            // El banner baja hasta el fondo cuando hay poco contenido.
            final minAlto = c.maxHeight > 138 ? c.maxHeight - 138 : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minAlto),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EncabezadoUsuario(),
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
                      if (entradas.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Sin eventos a los que asistir',
                              style: TextStyle(
                                  fontSize: 13, color: Colores.grisTexto),
                            ),
                          ),
                        )
                      else ...[
                        ...entradas.map(
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
                        const SizedBox(height: 14),
                      ],
                      const BannerPremium(),
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
  final VoidCallback onVerTicket;
  final VoidCallback onAnular;

  const _TarjetaEntrada({
    required this.evento,
    required this.onVerTicket,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
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
