import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../theme/colores.dart';
import 'imagen_asset.dart';

/// Tarjeta grande de "Eventos Top" (pantalla Inicio).
class TarjetaEventoVertical extends StatelessWidget {
  final Evento evento;
  final bool esFavorito;
  final VoidCallback onFavorito;
  final VoidCallback onReservar;

  const TarjetaEventoVertical({
    super.key,
    required this.evento,
    required this.esFavorito,
    required this.onFavorito,
    required this.onReservar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ----- Mitad superior: imagen + badge + corazón -----
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: ImagenAsset(ruta: evento.imagen),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colores.azulOscuro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      evento.categoria,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavorito,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: esFavorito ? Colores.azulOscuro : Colores.azulMedio,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ----- Mitad inferior: datos -----
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colores.azulMedio),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        evento.fechaCompleta,
                        style: const TextStyle(fontSize: 12, color: Colores.azulMedio),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colores.azulMedio),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        evento.lugar,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colores.azulMedio),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      evento.precio,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colores.azulOscuro,
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onReservar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colores.azulOscuro,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Reserva',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
