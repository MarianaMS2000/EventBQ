import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colores.dart';

// Los tiles de OpenStreetMap son para uso ligero; si la app crece,
// se recomienda contratar o configurar un servidor de tiles propio (como Mapbox o Stadia Maps).
const String _urlTilesOsm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _osmUserAgent = 'com.eventbq.app';

/// Widget de mapa para el selector de ubicación en Crear Evento.
/// Permite al organizador tocar cualquier punto del mapa para fijar o reajustar el pin exacto.
class MapaSelectorUbicacion extends StatelessWidget {
  final MapController controller;
  final LatLng punto;
  final ValueChanged<LatLng> onPuntoSeleccionado;
  final bool buscando;

  const MapaSelectorUbicacion({
    super.key,
    required this.controller,
    required this.punto,
    required this.onPuntoSeleccionado,
    this.buscando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A4570), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 15.0,
                onTap: (tapPosition, point) => onPuntoSeleccionado(point),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _urlTilesOsm,
                  userAgentPackageName: _osmUserAgent,
                  errorTileCallback: (tile, error, stackTrace) {},
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFD32F2F),
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Controles de zoom
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  _botonZoom(Icons.add, () {
                    final z = controller.camera.zoom;
                    controller.move(controller.camera.center, (z + 1).clamp(3.0, 18.0));
                  }),
                  const SizedBox(height: 6),
                  _botonZoom(Icons.remove, () {
                    final z = controller.camera.zoom;
                    controller.move(controller.camera.center, (z - 1).clamp(3.0, 18.0));
                  }),
                ],
              ),
            ),
            // Indicador de búsqueda
            if (buscando)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colores.azulOscuro),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Buscando en mapa...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colores.azulOscuro),
                      ),
                    ],
                  ),
                ),
              ),
            // Píldora de ayuda inferior
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Text(
                  'Toca o arrastra en el mapa para ajustar el pin en el punto exacto',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colores.azulOscuro),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonZoom(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: Colores.azulOscuro),
      ),
    );
  }
}

/// Widget de mapa estático de solo lectura para el Detalle del evento.
/// Deshabilita gestos interactivos para permitir el scroll natural de la pantalla.
class MapaDetalleEvento extends StatelessWidget {
  final LatLng punto;
  final String lugar;

  const MapaDetalleEvento({
    super.key,
    required this.punto,
    required this.lugar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colores.azulBrillante, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _urlTilesOsm,
                  userAgentPackageName: _osmUserAgent,
                  errorTileCallback: (tile, error, stackTrace) {},
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 38,
                      height: 38,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFD32F2F),
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Franja inferior con el nombre del lugar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.white.withValues(alpha: 0.92),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colores.azulBrillante, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lugar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colores.azulOscuro,
                        ),
                      ),
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
}
