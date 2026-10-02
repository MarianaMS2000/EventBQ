import 'package:flutter/material.dart';
import '../theme/colores.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/pantalla_vacia.dart';
import 'explorar_screen.dart';
import 'inicio_screen.dart';
import 'perfil_screen.dart';

/// Contenedor de las pantallas principales + barra de navegación inferior.
/// Se puede abrir en otra pestaña con:  irAPestana(context, 1);
class MainScreen extends StatefulWidget {
  final int indiceInicial;

  const MainScreen({super.key, this.indiceInicial = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _indice;

  // Inicio y Perfil se reconstruyen cada vez que se entra a la pestaña,
  // para que muestren los favoritos actualizados.
  int _versionInicio = 0;
  int _versionPerfil = 0;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  void _seleccionar(int i) {
    setState(() {
      if (i == 0 && _indice != 0) _versionInicio++;
      if (i == 3 && _indice != 3) _versionPerfil++;
      _indice = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      InicioScreen(key: ValueKey('inicio$_versionInicio')),
      const ExplorarScreen(),
      const PantallaVacia(titulo: 'Mis eventos'),
      PerfilScreen(key: ValueKey('perfil$_versionPerfil')),
    ];

    return Scaffold(
      backgroundColor: Colores.fondo,
      body: Stack(
        children: [
          IndexedStack(index: _indice, children: paginas),
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: BarraNavegacion(
                indiceActual: _indice,
                alSeleccionar: _seleccionar,
                alPresionarMas: () {
                  // TODO: abrir la pantalla "Crear evento" cuando exista
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crear evento: pantalla pendiente')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
