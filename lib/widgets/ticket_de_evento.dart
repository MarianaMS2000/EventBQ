import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
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
            ),
            const SizedBox(height: 8),
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
