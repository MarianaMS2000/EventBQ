import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../theme/colores.dart';
import 'badge_estado.dart';
import 'imagen_asset.dart';
import 'insignia_fecha.dart';

/// Tarjeta de lista: imagen con insignia de fecha a la izquierda, datos a la derecha.
/// Abajo a la derecha muestra UNA de estas cosas (en este orden de prioridad):
///  - mostrarEstado  -> "Activo" / "Finalizado"   (perfil del organizador)
///  - mostrarCorazon -> corazón rosado            (eventos guardados)
///  - por defecto    -> botón "Ver"
class TarjetaEventoHorizontal extends StatelessWidget {
  final Evento evento;
  final VoidCallback? onVer;
  final bool mostrarEstado;
  final bool mostrarCorazon;
  final VoidCallback? onCorazon;
  final String? etiquetaFecha; // si se pasa (ej. "HOY") reemplaza al día/mes

  const TarjetaEventoHorizontal({
    super.key,
    required this.evento,
    this.onVer,
    this.mostrarEstado = false,
    this.mostrarCorazon = false,
    this.onCorazon,
    this.etiquetaFecha,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVer,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colores.azulOscuro, width: 0.8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // ----- Imagen cuadrada + insignia -----
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ImagenAsset(ruta: evento.imagen),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: etiquetaFecha != null
                        ? InsigniaFecha(principal: etiquetaFecha!, ancho: 36)
                        : InsigniaFecha(principal: evento.dia, secundario: evento.mes),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ----- Datos -----
            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: Colores.azulMedio),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            evento.lugar,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colores.azulMedio),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          evento.precio,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colores.azulOscuro,
                          ),
                        ),
                        _accionDerecha(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionDerecha() {
    if (mostrarEstado) {
      return BadgeEstado(estado: evento.estado);
    }
    if (mostrarCorazon) {
      return GestureDetector(
        onTap: onCorazon,
        child: Container(
          width: 70,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF2D5EA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.favorite, color: Color(0xFFE84393), size: 22),
        ),
      );
    }
    return SizedBox(
      width: 78,
      height: 32,
      child: ElevatedButton(
        onPressed: onVer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colores.celesteClaro,
          foregroundColor: Colores.azulOscuro,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          'Ver',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
