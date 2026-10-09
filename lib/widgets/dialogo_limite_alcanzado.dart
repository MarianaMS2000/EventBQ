import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Ventana "¡Límite alcanzado!".
/// Devuelve:
///   'panel'  -> la X de arriba (ir al Panel de Organizador)
///   'planes' -> el botón "Pásate a EventBQ Premium" (ir a los planes)
///   null     -> si la cierran tocando fuera
///
/// Uso:
///   final destino = await showDialog<String>(
///     context: context,
///     barrierColor: Colors.black,
///     builder: (_) => DialogoLimiteAlcanzado(fechaDisponible: fecha),
///   );
class DialogoLimiteAlcanzado extends StatelessWidget {
  final DateTime fechaDisponible;
  final int publicados;
  final int limite;

  const DialogoLimiteAlcanzado({
    super.key,
    required this.fechaDisponible,
    this.publicados = 2,
    this.limite = 2,
  });

  String get _fecha {
    final d = fechaDisponible;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // X de arriba a la derecha -> Panel de Organizador
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, 'panel'),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colores.azulOscuro, width: 2),
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colores.azulOscuro),
                ),
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFC8372D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 14),
            const Text(
              '¡Límite alcanzado!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Has publicado $publicados/$limite\neventos permitidos\nen este periodo de\n6 meses.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                height: 1.3,
                color: Colores.azulOscuro,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Podrás publicar un nuevo evento\na partir del $_fecha.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                color: Colores.grisTexto,
              ),
            ),
            const SizedBox(height: 18),
            // Botón -> Planes
            GestureDetector(
              onTap: () => Navigator.pop(context, 'planes'),
              child: Container(
                width: double.infinity,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14105E), Color(0xFF5B2A55)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: const Text(
                  'Pásate a EventBQ\nPremium',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Color(0xFFE4B8FF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
