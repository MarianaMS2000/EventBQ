import 'package:flutter/material.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/evento_repository.dart';
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

  /// Búsqueda desde Inicio: transfiere la búsqueda a Explorar.
  final ValueChanged<String>? onBuscar;

  /// Tocar un ícono de categoría en Inicio: abre Explorar filtrado por esa categoría.
  final ValueChanged<String>? onSeleccionarCategoria;

  const InicioScreen({
    super.key,
    this.onVerCategorias,
    this.onVerEventos,
    this.onBuscar,
    this.onSeleccionarCategoria,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _categoriaRepo = CategoriaRepository();
  final _eventoRepo = EventoRepository();

  @override
  Widget build(BuildContext context) {
    final categorias = _categoriaRepo.obtenerCategorias();
    final eventos = _eventoRepo.obtenerEventosTop();

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
              hint: 'Un evento de salchipapa?',
              onTap: () => widget.onBuscar?.call(''),
              onSubmitted: (t) => widget.onBuscar?.call(t),
              onChanged: (t) => widget.onBuscar?.call(t),
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
                children: categorias
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: CategoriaItem(
                            categoria: c,
                            onTap: () => widget.onSeleccionarCategoria?.call(c.nombre),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            SeccionTitulo(
              titulo: 'Eventos Top',
              onVerTodo: widget.onVerEventos,
            ),
            const SizedBox(height: 12),
            ...eventos.map(
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
