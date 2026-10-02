import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Barra de búsqueda tipo pastilla.
/// conFiltro = false -> estilo Inicio (fondo blanco).
/// conFiltro = true  -> estilo Explorar (fondo celeste + botón de filtros).
/// filtrosActivos > 0 -> muestra el número rojo sobre el botón de filtros.
class BarraBusqueda extends StatelessWidget {
  final String hint;
  final bool conFiltro;
  final int filtrosActivos;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFiltro;

  const BarraBusqueda({
    super.key,
    required this.hint,
    this.conFiltro = false,
    this.filtrosActivos = 0,
    this.onChanged,
    this.onFiltro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: EdgeInsets.only(left: 14, right: conFiltro ? 4 : 14),
      decoration: BoxDecoration(
        color: conFiltro ? Colores.buscador : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colores.azulMedio, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colores.azulOscuro, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: Colores.azulOscuro),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Colores.grisTexto,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (conFiltro)
            GestureDetector(
              onTap: onFiltro,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colores.azulOscuro,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: Colors.white, size: 22),
                  ),
                  if (filtrosActivos > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colores.rojoNotificacion,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$filtrosActivos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
