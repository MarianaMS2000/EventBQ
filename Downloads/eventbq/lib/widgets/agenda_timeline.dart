import 'package:flutter/material.dart';
import '../models/item_agenda.dart';
import '../theme/colores.dart';

/// Agenda con línea vertical azul y puntos.
class AgendaTimeline extends StatelessWidget {
  final List<ItemAgenda> items;

  const AgendaTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (i) {
        final ultimo = i == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                        color: Colores.azulBrillante,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!ultimo)
                      Expanded(
                        child: Container(width: 2, color: Colores.azulBrillante),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].hora,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colores.azulOscuro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].descripcion,
                        style: const TextStyle(fontSize: 12, color: Colores.azulOscuro),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
