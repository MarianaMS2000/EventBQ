import 'package:flutter/material.dart';
import '../models/filtros_evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import 'barra_navegacion.dart';

/// Abre el modal de filtros. Devuelve los filtros elegidos, o null si se cerró con la X.
/// Uso:  final f = await mostrarFiltros(context, filtrosActuales);
Future<FiltrosEvento?> mostrarFiltros(BuildContext context, FiltrosEvento actuales) {
  return showModalBottomSheet<FiltrosEvento>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FiltrosSheet(inicial: actuales),
  );
}

class FiltrosSheet extends StatefulWidget {
  final FiltrosEvento inicial;

  const FiltrosSheet({super.key, required this.inicial});

  @override
  State<FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<FiltrosSheet> {
  late FiltrosEvento _filtros;
  final _repo = EventoRepository();

  @override
  void initState() {
    super.initState();
    _filtros = widget.inicial.copia();
  }

  @override
  Widget build(BuildContext context) {
    final altoMax = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: altoMax),
      child: Container(
        decoration: const BoxDecoration(
          color: Colores.fondo,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezado(),
                    const SizedBox(height: 16),
                    _titulo('CATEGORÍA'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _repo.obtenerCategoriasFiltro().map(_chipCategoria).toList(),
                    ),
                    const SizedBox(height: 18),
                    _titulo('FECHA'),
                    ..._repo.obtenerOpcionesFecha().map(_opcionFecha),
                    const SizedBox(height: 14),
                    _titulo('PRECIO'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Gratis', 'De pago'].map(_chipPrecio).toList(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _filtros),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colores.azulOscuro,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Aplica filtros',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Barra de navegación que asoma abajo (como en el diseño)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: SafeArea(
                top: false,
                child: BarraNavegacion(
                  indiceActual: 1,
                  alSeleccionar: (i) {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.pushNamedAndRemoveUntil('/home', (r) => false, arguments: i);
                  },
                  alPresionarMas: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Row(
      children: [
        const SizedBox(width: 36),
        const Expanded(
          child: Text(
            'Filtros',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE3E6EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colores.azulOscuro, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colores.azulOscuro,
        ),
      ),
    );
  }

  Widget _chip(String texto, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? Colores.azulOscuro : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colores.azulOscuro, width: 1.5),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: activo ? Colors.white : Colores.azulOscuro,
          ),
        ),
      ),
    );
  }

  Widget _chipCategoria(String nombre) {
    final activo = _filtros.categorias.contains(nombre);
    return _chip(nombre, activo, () {
      setState(() {
        if (activo) {
          _filtros.categorias.remove(nombre);
        } else {
          _filtros.categorias.add(nombre);
        }
      });
    });
  }

  Widget _chipPrecio(String nombre) {
    final activo = _filtros.precio == nombre;
    return _chip(nombre, activo, () {
      setState(() => _filtros.precio = activo ? '' : nombre);
    });
  }

  Widget _opcionFecha(String texto) {
    final activo = _filtros.fecha == texto;
    return GestureDetector(
      onTap: () => setState(() => _filtros.fecha = texto),
      child: Container(
        width: double.infinity,
        height: 34,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFE3E6F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colores.azulOscuro, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              activo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: Colores.azulOscuro,
            ),
            const SizedBox(width: 8),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colores.azulOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
