import 'package:flutter/material.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/evento_repository.dart';
import '../repositories/usuario_repository.dart';
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

  const InicioScreen({super.key, this.onVerCategorias, this.onVerEventos});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _usuarioRepo = UsuarioRepository();
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
            EncabezadoUsuario(usuario: _usuarioRepo.obtenerUsuarioActual()),
            const SizedBox(height: 16),
            const BarraBusqueda(hint: 'Un evento de salchipapa?'),
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
                          child: CategoriaItem(categoria: c),
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
                  esFavorito: _eventoRepo.esFavorito(e.id),
                  onFavorito: () async {
                    await _eventoRepo.alternarFavorito(e.id);
                    setState(() {});
                  },
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
