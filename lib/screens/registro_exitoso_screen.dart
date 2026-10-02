import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../navegacion.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/logo_flor.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/ticket_entrada.dart';

/// Recibe el Evento como argumento (ver DetalleEventoScreen).
class RegistroExitosoScreen extends StatelessWidget {
  const RegistroExitosoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Evento e =
        args is Evento ? args : EventoRepository().obtenerEventosExplorar()[2];

    return PantallaConBarra(
      indiceActual: 1,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A33D6), Color(0xFFAA8BE6)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            child: Column(
              children: [
                const LogoFlor(tamano: 40),
                const SizedBox(height: 6),
                const Text(
                  '¡Registro Exitoso!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TicketEntrada(
                  alturaSuperior: 225,
                  parteSuperior: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: ImagenAsset(ruta: e.imagen),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.titulo,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4A4A55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  parteInferior: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      children: [
                        const Text(
                          'TU PASE DE ENTRADA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colores.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 12),
                        QrPlaceholder(semilla: e.id),
                        const SizedBox(height: 12),
                        const Text(
                          'Válido para 1 persona',
                          style: TextStyle(fontSize: 13, color: Color(0xFF4A4A55)),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dato(Icons.calendar_today_outlined, 'Fecha', e.fechaCorta),
                            _dato(Icons.location_on_outlined, 'Ubicación', e.lugar),
                            _dato(Icons.access_time, 'Hora', e.hora),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Botón "Descargar PDF"
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Descargar PDF: pendiente')),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: Colores.azulOscuro),
                    label: const Text(
                      'Descargar PDF',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4A55),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.fondo,
                      elevation: 0,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Botón con degradado "Ver todos mis eventos"
                Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC04CB5), Color(0xFF8E0F8E)],
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => irAPestana(context, 2),
                    child: const Text(
                      'Ver todos mis eventos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String etiqueta, String valor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 16, color: Colores.azulOscuro),
          const SizedBox(height: 2),
          Text(etiqueta, style: const TextStyle(fontSize: 9, color: Colores.grisTexto)),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
