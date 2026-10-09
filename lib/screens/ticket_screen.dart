import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/logo_flor.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/ticket_de_evento.dart';

/// "¡Tu ticket aquí!": la entrada con su QR.
/// Se abre desde el Panel de Asistente con el botón "Ver ticket":
///   Navigator.pushNamed(context, '/ticket', arguments: evento);
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Evento e =
        args is Evento ? args : EventoRepository().obtenerEventosExplorar()[2];

    return PantallaConBarra(
      indiceActual: 2, // Mis eventos
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
                  '¡Tu ticket aquí!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TicketDeEvento(evento: e),
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
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        color: Colores.azulOscuro),
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

                // Botón con degradado "Ver todos mis eventos" -> pantalla anterior
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
                    onPressed: () => Navigator.pop(context),
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
}
