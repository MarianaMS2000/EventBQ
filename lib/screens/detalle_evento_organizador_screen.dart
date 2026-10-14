import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../utils/formato.dart';
import '../widgets/banner_premium.dart';
import '../widgets/dialogo_cancelar_evento.dart';
import '../widgets/dialogo_reprogramar_evento.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/grafico_barras.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/tarjeta_estadistica.dart';
import '../widgets/tarjeta_evento_horizontal.dart';

/// "Detalles del evento" (vista del organizador).
/// Se abre desde el Panel de Organizador con el botón verde "Ver":
///   Navigator.pushNamed(context, '/detalle-evento-organizador', arguments: evento);
///
/// Las cifras salen del evento guardado (inscritos, cupos, visualizaciones...).
/// Se ve distinta según evento.estado:
///   'Activo'     -> botones Reprogramar / Cancelar
///   'Cancelado'  -> inscripciones cerradas, "En devolución" y sin botones
///   'Finalizado' -> el evento ya pasó
/// Reprogramar, cancelar y eliminar se guardan de verdad (SharedPreferences).
class DetalleEventoOrganizadorScreen extends StatefulWidget {
  const DetalleEventoOrganizadorScreen({super.key});

  @override
  State<DetalleEventoOrganizadorScreen> createState() =>
      _DetalleEventoOrganizadorScreenState();
}

class _DetalleEventoOrganizadorScreenState
    extends State<DetalleEventoOrganizadorScreen> {
  final _repo = EventoRepository();

  Evento? _evento() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Evento) return args;
    final creados = _repo.obtenerEventosCreados();
    return creados.isEmpty ? null : creados.first;
  }

  bool _esEventoPropio(Evento e) => e.creadorId.isNotEmpty;

  /// "$ 1.920.000": precio por inscritos.
  String _recaudo(Evento e) =>
      '\$ ${formatoMiles((e.precioValor * e.inscritos).round())}';

  Future<void> _cancelarEvento(Evento evento) async {
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (_) => DialogoCancelarEvento(
        inscritos: '${evento.inscritos}',
        monto: _recaudo(evento),
      ),
    );
    if (confirmo == true && mounted) {
      _repo.cancelarEvento(evento.id);
    }
  }

  Future<void> _reprogramar(Evento evento) async {
    final f = evento.fecha ?? DateTime.now();
    final r = await showDialog<NuevaProgramacion>(
      context: context,
      builder: (_) => DialogoReprogramarEvento(
        fechaInicial: f,
        inicioInicial: const TimeOfDay(hour: 14, minute: 0),
        cierreInicial: const TimeOfDay(hour: 19, minute: 0),
      ),
    );
    if (r == null || !mounted) return;
    _repo.reprogramarEvento(evento.id, r.fecha, r.inicio, r.cierre);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento reprogramado')),
    );
  }

  Future<void> _eliminar(Evento evento) async {
    if (evento.estado == 'Activo' && evento.inscritos > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancela el evento antes de eliminarlo (hay inscritos)'),
        ),
      );
      return;
    }
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colores.fondo,
        title: const Text('¿Eliminar este evento?'),
        content: const Text('Se borrará de tu lista y no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFF8E0B12))),
          ),
        ],
      ),
    );
    if (confirmo != true || !mounted) return;
    _repo.eliminarEvento(evento.id);
    Navigator.pop(context);
  }

  /// Inscripciones de los últimos 7 días (para el gráfico de barras).
  (List<int>, List<String>) _inscripcionesPorDia(Evento e) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final hoy = soloFecha(DateTime.now());
    final valores = <int>[];
    final etiquetas = <String>[];
    for (int i = 6; i >= 0; i--) {
      final dia = hoy.subtract(Duration(days: i));
      final n = e.inscripciones.where((iso) {
        final d = DateTime.tryParse(iso);
        return d != null && soloFecha(d) == dia;
      }).length;
      valores.add(n);
      etiquetas.add(dias[dia.weekday - 1]);
    }
    return (valores, etiquetas);
  }

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final evento = _evento();
    if (evento == null) {
      return PantallaConBarra(
        indiceActual: 2,
        child: SafeArea(
          child: Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Este evento ya no existe. Volver'),
            ),
          ),
        ),
      );
    }

    final estado = evento.estado;
    final cancelado = estado == 'Cancelado';
    final finalizado = estado == 'Finalizado';
    final activo = !cancelado && !finalizado;
    final propio = _esEventoPropio(evento);

    final hoy = soloFecha(DateTime.now());
    final f = evento.fecha;
    final diasRestantes =
        f == null ? 0 : (f.difference(hoy).inDays).clamp(0, 99999);
    final rating = _repo.ratingDeEvento(evento.id);

    // Tarjetas con datos reales: (valor, etiqueta)
    final List<(String, String)> stats = cancelado
        ? [
            ('${evento.inscritos}', 'Inscripciones\ncerradas'),
            ('${evento.cuposDisponibles}', 'Entradas\nrestantes'),
            ('${evento.visualizaciones}', 'Visualizaciones'),
            ('0', 'Días restantes'),
          ]
        : finalizado
            ? [
                ('${evento.inscritos}', 'Total inscritos'),
                ('${evento.cuposDisponibles}', 'Cupos sin usar'),
                ('${evento.visualizaciones}', 'Visualizaciones'),
                (rating == 0 ? '-' : '${rating.toStringAsFixed(1)} ★', 'Valoración'),
              ]
            : [
                ('${evento.inscritos}', 'Total inscritos'),
                ('${evento.cuposDisponibles}', 'Entradas\nrestantes'),
                ('${evento.visualizaciones}', 'Visualizaciones'),
                ('$diasRestantes', 'Días restantes'),
              ];

    final textoRecaudo = cancelado
        ? 'En devolución: ${_recaudo(evento)}'
        : evento.esGratis
            ? 'Recaudo: \$ Evento Gratuito'
            : 'Recaudo: ${_recaudo(evento)}';

    final (valoresGrafico, etiquetasGrafico) = _inscripcionesPorDia(evento);
    final mayor = valoresGrafico.reduce((a, b) => a > b ? a : b);
    final maximoGrafico = ((mayor < 3 ? 3 : mayor) / 3).ceil() * 3;

    return PantallaConBarra(
      indiceActual: 2, // Mis eventos
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoUsuario(),
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
                    const Text(
                      'Inscripciones por día\n(últimos 7 días)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GraficoBarras(
                      valores: valoresGrafico,
                      etiquetas: etiquetasGrafico,
                      maximo: maximoGrafico,
                      paso: maximoGrafico ~/ 3,
                    ),
                  ],
                ),
              ),

              // ----- Botones (solo si el evento sigue activo) -----
              if (activo && propio) ...[
                const SizedBox(height: 26),
                _BotonAccion(
                  texto: 'Reprogramar evento',
                  fondo: const Color(0xFFE8DDA6),
                  colorTexto: Colors.black,
                  onTap: () => _reprogramar(evento),
                ),
                const SizedBox(height: 18),
                _BotonAccion(
                  texto: 'Cancelar evento',
                  fondo: const Color(0xFF8E0B12),
                  colorTexto: Colors.white,
                  onTap: () => _cancelarEvento(evento),
                ),
              ],
              if (propio) ...[
                const SizedBox(height: 18),
                _BotonAccion(
                  texto: 'Eliminar evento',
                  fondo: Colors.white,
                  colorTexto: const Color(0xFF8E0B12),
                  onTap: () => _eliminar(evento),
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
