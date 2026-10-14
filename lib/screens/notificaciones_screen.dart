import 'package:flutter/material.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../repositories/notificacion_repository.dart';
import '../theme/colores.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/item_notificacion.dart';
import '../widgets/pantalla_con_barra.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _repo = NotificacionRepository();

  @override
  void initState() {
    super.initState();
    // Si hay eventos terminados sin calificar, crea el aviso "¡Califícalo!".
    _repo.generarPendientesCalificacion();
  }

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final sinLeer = _repo.contarNoLeidas();

    return PantallaConBarra(
      indiceActual: 1,
      child: SafeArea(
        bottom: false,
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: EncabezadoUsuario(),
              ),
              const Divider(height: 1),
              // ----- Título + X para cerrar -----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notificaciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colores.azulOscuro,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colores.azulOscuro, size: 26),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sinLeer == 0
                          ? 'No tienes notificaciones sin leer'
                          : 'Tienes $sinLeer notificaciones sin leer',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                    ),
                    GestureDetector(
                      onTap: _repo.marcarTodasLeidas,
                      child: const Text(
                        'Marcar como leídas',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5560B5),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ----- Pestañas -----
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFBBBBBB)),
                    bottom: BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                ),
                child: const TabBar(
                  labelColor: Colores.azulOscuro,
                  unselectedLabelColor: Colores.grisTexto,
                  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 14),
                  indicatorColor: Colores.azulOscuro,
                  tabs: [
                    Tab(text: 'Eventos'),
                    Tab(text: 'Organizador'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _lista('Eventos'),
                    _lista('Organizador'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lista(String tipo) {
    final lista = _repo.obtenerPorTipo(tipo);
    if (lista.isEmpty) {
      return const Center(
        child: Text('No hay notificaciones', style: TextStyle(color: Colores.grisTexto)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      itemCount: lista.length,
      separatorBuilder: (context, i) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        return ItemNotificacion(
          notificacion: lista[i],
          onCalificar: () {
            final evento = EventoRepository().obtenerEventoPorId(lista[i].idEvento);
            if (evento == null) return; // el evento ya no existe
            Navigator.pushNamed(context, '/calificar', arguments: evento);
          },
        );
      },
    );
  }
}
