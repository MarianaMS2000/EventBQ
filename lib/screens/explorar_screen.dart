import 'package:flutter/material.dart';
import '../models/filtros_evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/banner_premium.dart';
import '../widgets/barra_busqueda.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/filtros_sheet.dart';
import '../widgets/tarjeta_evento_horizontal.dart';

class ExplorarScreen extends StatefulWidget {
  /// Si este número cambia, la pantalla abre el modal de filtros
  /// (lo usa Inicio > Categorías > "Ver todo").
  final int senalAbrirFiltros;

  const ExplorarScreen({super.key, this.senalAbrirFiltros = 0});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final _eventoRepo = EventoRepository();
  String _texto = '';
  FiltrosEvento _filtros = FiltrosEvento();

  @override
  void didUpdateWidget(covariant ExplorarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.senalAbrirFiltros != oldWidget.senalAbrirFiltros) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrirFiltros();
      });
    }
  }

  Future<void> _abrirFiltros() async {
    final resultado = await mostrarFiltros(context, _filtros);
    if (resultado != null) {
      setState(() => _filtros = resultado);
    }
  }

  /// Textos de los chips: "Deportes", "Hoy", "Gratis"...
  List<String> _chipsActivos() {
    final chips = <String>[..._filtros.categorias];
    if (_filtros.fecha != 'Cualquier fecha') chips.add(_filtros.fecha);
    if (_filtros.precio.isNotEmpty) chips.add(_filtros.precio);
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final eventos = _eventoRepo.buscarEventos(_texto, filtros: _filtros);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EncabezadoUsuario(),
            const SizedBox(height: 16),
            BarraBusqueda(
              hint: 'Que te interesa',
              conFiltro: true,
              filtrosActivos: _filtros.cantidad,
              onChanged: (t) => setState(() => _texto = t),
              onFiltro: _abrirFiltros,
            ),
            if (_filtros.hayFiltros) ...[
              const SizedBox(height: 12),
              _barraFiltrosActivos(),
            ],
            const SizedBox(height: 16),
            if (eventos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('No encontramos eventos con esos filtros')),
              ),
            ...eventos.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TarjetaEventoHorizontal(
                  evento: e,
                  // Con el filtro "Hoy" la insignia dice HOY en vez del día
                  etiquetaFecha: _filtros.fecha == 'Hoy' ? 'HOY' : null,
                  onVer: () => Navigator.pushNamed(
                    context,
                    '/detalle-evento',
                    arguments: e,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const BannerPremium(),
          ],
        ),
      ),
    );
  }

  Widget _barraFiltrosActivos() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _chipsActivos()
                  .map(
                    (texto) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colores.azulOscuro, width: 1.3),
                      ),
                      child: Text(
                        texto,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colores.azulOscuro,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _filtros = FiltrosEvento()),
          child: Row(
            children: const [
              Text(
                'Limpiar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colores.azulOscuro,
                ),
              ),
              SizedBox(width: 3),
              Icon(Icons.close, size: 15, color: Colores.azulOscuro),
            ],
          ),
        ),
      ],
    );
  }
}
