import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../navegacion.dart';
import '../repositories/evento_repository.dart';
import '../services/ticket_pdf_service.dart';
import '../theme/colores.dart';
import '../widgets/logo_flor.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/ticket_de_evento.dart';

/// Recibe el Evento como argumento (ver DetalleEventoScreen).
class RegistroExitosoScreen extends StatefulWidget {
  const RegistroExitosoScreen({super.key});

  @override
  State<RegistroExitosoScreen> createState() => _RegistroExitosoScreenState();
}

class _RegistroExitosoScreenState extends State<RegistroExitosoScreen> {
  bool _generandoPdf = false;

  Future<void> _descargarPdf(Evento e) async {
    if (_generandoPdf) return;
    setState(() => _generandoPdf = true);
    try {
      await TicketPdfService.descargarTicketPdf(evento: e);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFF8E0B12),
        ),
      );
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

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
                TicketDeEvento(evento: e),
                const SizedBox(height: 14),

                // Botón "Descargar PDF"
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _generandoPdf ? null : () => _descargarPdf(e),
                    icon: _generandoPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colores.azulOscuro,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, color: Colores.azulOscuro),
                    label: Text(
                      _generandoPdf ? 'Generando PDF...' : 'Descargar PDF',
                      style: const TextStyle(
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
}
