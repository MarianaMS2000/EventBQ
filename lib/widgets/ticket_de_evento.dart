import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../utils/formato.dart';
import 'imagen_asset.dart';
import 'ticket_entrada.dart';

/// Entrada completa de un evento: foto + título arriba, y abajo
/// "TU PASE DE ENTRADA", el QR y los datos (fecha, ubicación, hora).
/// La usan "¡Registro Exitoso!" y "¡Tu ticket aquí!".
class TicketDeEvento extends StatelessWidget {
  final Evento evento;
  final Inscripcion? inscripcion;

  const TicketDeEvento({
    super.key,
    required this.evento,
    this.inscripcion,
  });

  @override
  Widget build(BuildContext context) {
    final e = evento;
    final insc = inscripcion ?? EventoRepository().obtenerInscripcion(e.id);
    final codigo = insc?.codigo.isNotEmpty == true ? insc!.codigo : e.id;

    final hoy = soloFecha(DateTime.now());
    final fechaEv = e.fecha != null ? soloFecha(e.fecha!) : null;
    final esDiaDelEvento = fechaEv == null || !hoy.isBefore(fechaEv);

    return TicketEntrada(
      alturaSuperior: 225,
      parteSuperior: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ImagenAsset(
                  ruta: e.imagenParaDetalle,
                  rutaRespaldo: e.imagen,
                ),
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
            if (esDiaDelEvento)
              SizedBox(
                width: 170,
                height: 170,
                child: QrImageView(
                  data: '${e.id}|${insc?.uid ?? ""}|$codigo',
                  version: QrVersions.auto,
                  size: 170.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colores.azulOscuro,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colores.azulOscuro,
                  ),
                ),
              )
            else
              Container(
                width: 170,
                height: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colores.azulOscuro.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colores.azulOscuro.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colores.azulOscuro,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'QR PROTEGIDO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colores.azulOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se activará el\n${e.fechaCorta}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4A55),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            if (esDiaDelEvento) ...[
              if (insc != null && insc.codigo.isNotEmpty)
                Text(
                  'CÓDIGO: ${insc.codigo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F9EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00B074)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 13, color: Color(0xFF00875A)),
                    SizedBox(width: 4),
                    Text(
                      '¡Listo para ingresar al evento!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00875A),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB400)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 13, color: Color(0xFFB47500)),
                    SizedBox(width: 4),
                    Text(
                      'Pase protegido hasta el día del evento',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB47500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
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
    );
  }

  Widget _dato(IconData icono, String etiqueta, String valor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 16, color: Colores.azulOscuro),
          const SizedBox(height: 2),
          Text(etiqueta,
              style: const TextStyle(fontSize: 9, color: Colores.grisTexto)),
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
