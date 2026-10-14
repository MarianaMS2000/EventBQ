import 'package:flutter/material.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/banner_premium.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/tarjeta_estadistica.dart';
import '../widgets/tarjeta_evento_horizontal.dart';

/// "Panel de Organizador": resumen + eventos creados.
/// Se abre desde Mis eventos > Mis Eventos Creados.
class PanelOrganizadorScreen extends StatelessWidget {
  const PanelOrganizadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final repo = EventoRepository();
    final eventos = repo.obtenerEventosCreados();
    final activos = eventos.where((e) => e.estado == 'Activo').length;
    // Estadísticas calculadas con los eventos reales del usuario.
    final inscritos = eventos.fold<int>(0, (s, e) => s + e.inscritos);
    final aforo = eventos.fold<int>(0, (s, e) => s + e.cuposTotales);
    final ocupacion = aforo == 0 ? 0 : (inscritos * 100 / aforo).round();
    final rating = repo.ratingDeCreador(UsuarioRepository().obtenerUsuarioActual().id);

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
                    'Panel de Organizador',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ----- Estadísticas (calculadas con tus eventos) -----
              Row(
                children: [
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: '$activos',
                      etiqueta: 'Eventos\nactivos',
                      fondo: TarjetaEstadistica.verde.fondo,
                      borde: TarjetaEstadistica.verde.borde,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: '$inscritos',
                      etiqueta: 'Total\ninscritos',
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
                      valor: '$ocupacion%',
                      etiqueta: 'Ocupación\ntotal',
                      fondo: TarjetaEstadistica.durazno.fondo,
                      borde: TarjetaEstadistica.durazno.borde,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TarjetaEstadistica(
                      valor: rating == 0 ? '-' : '${rating.toStringAsFixed(1)} ★',
                      etiqueta: 'Valoración',
                      fondo: TarjetaEstadistica.violeta.fondo,
                      borde: TarjetaEstadistica.violeta.borde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // ----- Mis eventos creados -----
              const Text(
                'Mis eventos creados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colores.azulOscuro,
                ),
              ),
              const SizedBox(height: 12),
              if (eventos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aún no has creado eventos.\nToca el botón + para publicar el primero.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colores.grisTexto, height: 1.4),
                    ),
                  ),
                ),
              ...eventos.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TarjetaEventoHorizontal(
                    evento: e,
                    colorBotonVer: Colores.verdeActivo,
                    onVer: () => Navigator.pushNamed(
                      context,
                      '/detalle-evento-organizador',
                      arguments: e,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ----- Escanear QR -----
              _TarjetaEscanearQr(
                onAbrirLector: () {
                  // TODO: abrir el lector de QR cuando exista
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Lector de QR: pantalla pendiente')),
                  );
                },
              ),
              const SizedBox(height: 20),
              const BannerPremium(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaEscanearQr extends StatelessWidget {
  final VoidCallback onAbrirLector;

  const _TarjetaEscanearQr({required this.onAbrirLector});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.azulOscuro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: Image.asset(
              'assets/images/qr_escanear.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 66),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escanear QR de\nentrada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Abre el lector\npara validar',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onAbrirLector,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF09A00),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Abrir lector',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
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
