import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/insignia_fecha.dart';

/// Recibe el Evento como argumento:
/// Navigator.pushNamed(context, '/calificar', arguments: evento);
class CalificarScreen extends StatefulWidget {
  const CalificarScreen({super.key});

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  int _estrellas = 0;

  Evento _evento() {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Evento ? args : EventoRepository().obtenerEventosTop()[0]; // respaldo
  }

  void _enviar() {
    if (_estrellas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige cuántas estrellas le das al evento')),
      );
      return;
    }
    // Se guarda la calificación (SharedPreferences) para el rating del organizador.
    EventoRepository().calificar(_evento().id, _estrellas);
    Navigator.pushReplacementNamed(context, '/gracias-opinion');
  }

  @override
  Widget build(BuildContext context) {
    final Evento e = _evento();

    return Scaffold(
      backgroundColor: Colores.azulOscuro,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Califica tu\nexperiencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              // ----- Tarjeta principal -----
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colores.fondo,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _resumenEvento(e),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Column(
                        children: [
                          const Text(
                            '¿Cómo calificarías este\nevento?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colores.azulOscuro,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final activa = i < _estrellas;
                              return GestureDetector(
                                onTap: () => setState(() => _estrellas = i + 1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    activa ? Icons.star : Icons.star_border,
                                    size: 44,
                                    color: activa
                                        ? const Color(0xFFFFB400)
                                        : const Color(0xFF1B1B1B),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _enviar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colores.azulOscuro,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: const Text(
                                'Enviar mi calificación',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumenEvento(Evento e) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 84,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ImagenAsset(ruta: e.imagen),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: InsigniaFecha(principal: e.dia, secundario: e.mes),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Colores.azulMedio),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        e.lugar,
                        style: const TextStyle(fontSize: 11, color: Colores.azulOscuro),
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
