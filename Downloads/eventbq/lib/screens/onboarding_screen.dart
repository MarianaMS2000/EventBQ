import 'package:flutter/material.dart';
import '../preferences/preferencias_usuario.dart';
import '../repositories/onboarding_repository.dart';
import '../theme/colores.dart';
import '../widgets/imagen_asset.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _paginas = OnboardingRepository().obtenerPaginas();
  int _paginaActual = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_paginaActual < _paginas.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Guardamos que el tutorial ya se vio
      PreferenciasUsuario.onboardingCompletado = true;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _paginas.length,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemBuilder: (context, i) {
                  final p = _paginas[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            child: ImagenAsset(
                              ruta: p.imagen,
                              fit: BoxFit.contain,
                              colorPlaceholder: p.colorFondoImagen,
                              iconoPlaceholder: Icons.image_outlined,
                            ),
                          ),
                        ),
                        Text(
                          p.titulo,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.subtitulo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF333333),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ----- Controles: puntos a la izquierda, flecha a la derecha -----
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_paginas.length, (i) {
                      final activo = i == _paginaActual;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activo ? Colores.azulOscuro : const Color(0xFFD5D8E0),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  SizedBox(
                    width: 56,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _siguiente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colores.azulOscuro,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.arrow_forward, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
