import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/banner_premium.dart';
import '../widgets/dialogo_cancelar_evento.dart';
import '../widgets/dialogo_reprogramar_evento.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/grafico_area.dart';
import '../widgets/grafico_barras.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/tarjeta_estadistica.dart';
import '../widgets/tarjeta_evento_horizontal.dart';

/// "Detalles del evento" (vista del organizador).
/// Se abre desde el Panel de Organizador con el botón verde "Ver":
///   Navigator.pushNamed(context, '/detalle-evento-organizador', arguments: evento);
///
/// Se ve distinta según evento.estado:
///   'Activo'     -> estadísticas, gráfico de barras y botones Reprogramar / Cancelar
///   'Cancelado'  -> inscripciones cerradas, "En devolución" y sin botones
///   'Finalizado' -> asistencia, valoración y gráfico de flujo de check-in
class DetalleEventoOrganizadorScreen extends StatefulWidget {
  const DetalleEventoOrganizadorScreen({super.key});

  @override
  State<DetalleEventoOrganizadorScreen> createState() =>
      _DetalleEventoOrganizadorScreenState();
}

class _DetalleEventoOrganizadorScreenState
    extends State<DetalleEventoOrganizadorScreen> {
  // Solo es una demostración: el "cancelado" vive en esta pantalla y se
  // pierde al salir (el evento real no se modifica). Cuando haya backend,
  // aquí se llamaría a la API para cancelar de verdad.
  bool _cancelado = false;

  Future<void> _cancelarEvento(Evento evento) async {
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (_) => const DialogoCancelarEvento(),
    );
    if (confirmo == true && mounted) {
      setState(() => _cancelado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Evento evento = args is Evento
        ? args
        : EventoRepository().obtenerEventosCreados().first;

    final estado = _cancelado ? 'Cancelado' : evento.estado;
    final cancelado = estado == 'Cancelado';
    final finalizado = estado == 'Finalizado';
    final activo = !cancelado && !finalizado;

    // Datos simulados de las 4 tarjetas: (valor, etiqueta)
    final List<(String, String)> stats = cancelado
        ? [
            ('32', 'Inscripciones\ncerradas'),
            ('0', 'Sistemáticamente\nbloqueadas'),
            ('142', 'Visualizaciones'),
            ('0', 'Días restantes'),
          ]
        : finalizado
            ? [
                ('192', 'Asistieron'),
                ('24', 'No asistieron'),
                ('216', 'Total inscritos'),
                ('4.2 ★', 'Valoración'),
              ]
            : [
                ('32', 'Total inscritos'),
                ('18', 'Entradas\nrestantes'),
                ('142', 'Visualizaciones'),
                ('53', 'Días restantes'),
              ];

    final textoRecaudo = cancelado
        ? 'En devolución: \$ 1.920.000'
        : evento.esGratis
            ? 'Recaudo: \$ Evento Gratuito'
            : 'Recaudo: \$ 1.920.000';

    return PantallaConBarra(
      indiceActual: 2, // Mis eventos
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoUsuario(
                  usuario: UsuarioRepository().obtenerUsuarioActual()),
              const SizedBox(height: 18),

              // ----- Título con flecha -----
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colores.azulOscuro, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalles del evento',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ----- Tarjeta del evento (Activo / Cancelado / Finalizado) -----
              TarjetaEventoHorizontal(
                evento: evento,
                mostrarEstado: true,
                estadoMostrado: estado,
              ),
              const SizedBox(height: 16),

              // ----- Estadísticas -----
              Row(
                children: [
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: stats[0].$1,
                      etiqueta: stats[0].$2,
                      fondo: TarjetaEstadistica.verde.fondo,
                      borde: TarjetaEstadistica.verde.borde,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: stats[1].$1,
                      etiqueta: stats[1].$2,
                      fondo: TarjetaEstadistica.turquesa.fondo,
                      borde: TarjetaEstadistica.turquesa.borde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: stats[2].$1,
                      etiqueta: stats[2].$2,
                      fondo: TarjetaEstadistica.durazno.fondo,
                      borde: TarjetaEstadistica.durazno.borde,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: stats[3].$1,
                      etiqueta: stats[3].$2,
                      fondo: TarjetaEstadistica.violeta.fondo,
                      borde: TarjetaEstadistica.violeta.borde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ----- Recaudo -----
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black26),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    textoRecaudo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ----- Gráfico -----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finalizado
                          ? 'Flujo de asistencia\n(Check-in QR)'
                          : 'Inscripciones por día',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (finalizado)
                      const GraficoArea(
                        valores: [2, 3, 30, 37, 10, 5],
                        etiquetas: ['9', '10', '11', '12', '1', '2'],
                      )
                    else
                      const GraficoBarras(
                        valores: [3, 7, 5, 9, 4, 2, 2],
                        etiquetas: [
                          'Lun',
                          'Mar',
                          'Mié',
                          'Jue',
                          'Vie',
                          'Sáb',
                          'Dom'
                        ],
                      ),
                  ],
                ),
              ),

              // ----- Botones (solo si el evento sigue activo) -----
              if (activo) ...[
                const SizedBox(height: 26),
                _BotonAccion(
                  texto: 'Reprogramar evento',
                  fondo: const Color(0xFFE8DDA6),
                  colorTexto: Colors.black,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const DialogoReprogramarEvento(),
                  ),
                ),
                const SizedBox(height: 18),
                _BotonAccion(
                  texto: 'Cancelar evento',
                  fondo: const Color(0xFF8E0B12),
                  colorTexto: Colors.white,
                  onTap: () => _cancelarEvento(evento),
                ),
              ],
              const SizedBox(height: 24),
              const BannerPremium(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color colorTexto;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.texto,
    required this.fondo,
    required this.colorTexto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: colorTexto,
          elevation: 3,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
