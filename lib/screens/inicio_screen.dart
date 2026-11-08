import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/filtros_evento.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/banner_premium.dart';
import '../widgets/barra_busqueda.dart';
import '../widgets/categoria_item.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/seccion_titulo.dart';
import '../widgets/tarjeta_evento_vertical.dart';

class InicioScreen extends StatefulWidget {
  /// "Ver todo" de Categorías: abre Explorar con el modal de filtros.
  final VoidCallback? onVerCategorias;

  /// "Ver todo" de Eventos Top: abre Explorar.
  final VoidCallback? onVerEventos;

  const InicioScreen({
    super.key,
    this.onVerCategorias,
    this.onVerEventos,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _categoriaRepo = CategoriaRepository();
  final _eventoRepo = EventoRepository();

  final TextEditingController _busquedaCtrl = TextEditingController();
  String _textoBusqueda = '';
  String? _categoriaSeleccionada;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _limpiarFiltros() {
    setState(() {
      _busquedaCtrl.clear();
      _textoBusqueda = '';
      _categoriaSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _categoriaRepo.obtenerCategorias();

    final bool hayFiltroActivo =
        _textoBusqueda.trim().isNotEmpty || _categoriaSeleccionada != null;

    final List<Evento> eventosMostrados;
    final String tituloSeccion;

    if (hayFiltroActivo) {
      final filtros = _categoriaSeleccionada != null
          ? FiltrosEvento(categorias: [_categoriaSeleccionada!])
          : null;
      eventosMostrados =
          _eventoRepo.buscarEventos(_textoBusqueda, filtros: filtros);

      if (_categoriaSeleccionada != null && _textoBusqueda.trim().isNotEmpty) {
        tituloSeccion = 'Resultados en "$_categoriaSeleccionada"';
      } else if (_categoriaSeleccionada != null) {
        tituloSeccion = 'Eventos de $_categoriaSeleccionada';
      } else {
        tituloSeccion = 'Resultados de búsqueda';
      }
    } else {
      eventosMostrados = _eventoRepo.obtenerEventosTop();
      tituloSeccion = 'Eventos Top';
    }

    return SafeArea(
      child: SingleChildScrollView(
        // padding inferior grande para que la barra flotante no tape el contenido
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoUsuario(),
            const SizedBox(height: 16),
            BarraBusqueda(
              controller: _busquedaCtrl,
              hint: 'Un evento de salchipapa?',
              onChanged: (t) => setState(() => _textoBusqueda = t),
              onSubmitted: (t) => setState(() => _textoBusqueda = t),
              onLimpiar: () => setState(() {
                _busquedaCtrl.clear();
                _textoBusqueda = '';
              }),
            ),
            const SizedBox(height: 20),
            SeccionTitulo(
              titulo: 'Categorías',
              onVerTodo: widget.onVerCategorias,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categorias.map((c) {
                  final seleccionada = _categoriaSeleccionada == c.nombre;
                  return Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: CategoriaItem(
                      categoria: c,
                      seleccionada: seleccionada,
                      onTap: () {
                        setState(() {
                          if (_categoriaSeleccionada == c.nombre) {
                            _categoriaSeleccionada = null; // deselecciona
                          } else {
                            _categoriaSeleccionada = c.nombre; // selecciona
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SeccionTitulo(
                    titulo: tituloSeccion,
                    onVerTodo: hayFiltroActivo ? null : widget.onVerEventos,
                  ),
                ),
                if (hayFiltroActivo)
                  TextButton(
                    onPressed: _limpiarFiltros,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Restablecer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colores.azulOscuro,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (eventosMostrados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colores.grisTexto.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _textoBusqueda.isNotEmpty
                            ? 'No se encontraron eventos para "$_textoBusqueda"'
                            : 'No hay eventos disponibles en esta categoría',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colores.grisTexto,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...eventosMostrados.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TarjetaEventoVertical(
                    evento: e,
                    onReservar: () => Navigator.pushNamed(
                      context,
                      '/detalle-evento',
                      arguments: e,
                    ),
                  ),
                ),
              ),
            const BannerPremium(),
          ],
        ),
      ),
    );
  }
}
