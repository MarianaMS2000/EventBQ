import 'package:flutter/material.dart';
import '../repositories/evento_repository.dart';
import '../repositories/organizador_repository.dart';
import '../theme/colores.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/pantalla_con_barra.dart';
import '../widgets/tarjeta_evento_horizontal.dart';

class PerfilOrganizadorScreen extends StatelessWidget {
  const PerfilOrganizadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final org = OrganizadorRepository().obtenerOrganizador();
    final eventos = EventoRepository().obtenerEventosDeOrganizador();

    return PantallaConBarra(
      indiceActual: 1,
      colorFondo: Colores.azulOscuro,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ----- Parte azul oscura -----
            Container(
              width: double.infinity,
              color: Colores.azulOscuro,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: ImagenAsset(
                            ruta: org.foto,
                            iconoPlaceholder: Icons.person,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        org.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        org.rol,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFC8CDE0), fontSize: 11),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _estadistica('${org.eventos}', 'Eventos'),
                          _estadistica('${org.asistentes}', 'Asistentes'),
                          _estadistica('${org.rating}', 'Rating'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ----- Parte clara con esquinas superiores redondeadas -----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
              decoration: const BoxDecoration(
                color: Colores.fondo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tarjetaInformacion(org.correo, org.telefono, org.miembroDesde),
                  const SizedBox(height: 22),
                  const Text(
                    'Colección de Eventos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colores.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...eventos.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TarjetaEventoHorizontal(evento: e, mostrarEstado: true),
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

  Widget _estadistica(String numero, String texto) {
    return Column(
      children: [
        Text(
          numero,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaInformacion(String correo, String telefono, String miembroDesde) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colores.azulOscuro, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          _dato('Email', correo),
          _dato('Teléfono', telefono),
          _dato('Miembro desde', miembroDesde),
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colores.grisTexto)),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colores.azulOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
