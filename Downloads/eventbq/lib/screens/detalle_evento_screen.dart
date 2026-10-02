import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../repositories/organizador_repository.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/agenda_timeline.dart';
import '../widgets/banner_premium.dart';
import '../widgets/dialogo_confirmar_asistencia.dart';
import '../widgets/encabezado_usuario.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/pantalla_con_barra.dart';

/// Recibe el Evento como argumento:
/// Navigator.pushNamed(context, '/detalle-evento', arguments: evento);
class DetalleEventoScreen extends StatefulWidget {
  const DetalleEventoScreen({super.key});

  @override
  State<DetalleEventoScreen> createState() => _DetalleEventoScreenState();
}

class _DetalleEventoScreenState extends State<DetalleEventoScreen> {
  final _eventoRepo = EventoRepository();
  final _usuarioRepo = UsuarioRepository();
  final _organizador = OrganizadorRepository().obtenerOrganizador();

  Evento _obtenerEvento() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Evento) return args;
    return _eventoRepo.obtenerEventosExplorar()[2]; // respaldo
  }

  Future<void> _inscribirse(Evento evento) async {
    final confirmado = await mostrarDialogoConfirmarAsistencia(context, evento);
    if (confirmado && mounted) {
      Navigator.pushReplacementNamed(context, '/registro-exitoso', arguments: evento);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _obtenerEvento();
    final favorito = _eventoRepo.esFavorito(e.id);

    return PantallaConBarra(
      indiceActual: 1,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: EncabezadoUsuario(usuario: _usuarioRepo.obtenerUsuarioActual()),
              ),
              // ----- Imagen hero -----
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(child: ImagenAsset(ruta: e.imagen)),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colores.azulBrillante,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colores.azulBrillante,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e.categoria,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // ----- Título + corazón -----
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.titulo,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulOscuro,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await _eventoRepo.alternarFavorito(e.id);
                            setState(() {});
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colores.azulBrillante,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              favorito ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ----- Fecha y ubicación -----
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _infoBasica(
                            Icons.calendar_today_outlined,
                            'Fecha',
                            e.fechaParaDetalle,
                            e.horarioParaDetalle,
                          ),
                        ),
                        Expanded(
                          child: _infoBasica(
                            Icons.location_on_outlined,
                            'Ubicación',
                            e.lugar,
                            null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _tarjetaOrganizador(),
                    if (e.cuposTotales > 0) ...[
                      const SizedBox(height: 22),
                      _cupos(e),
                    ],
                    const SizedBox(height: 22),
                    _subtitulo('Sobre el evento'),
                    Text(
                      e.descripcion.isEmpty
                          ? 'Pronto tendremos más información sobre este evento.'
                          : e.descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colores.azulOscuro,
                        height: 1.4,
                      ),
                    ),
                    if (e.incluye.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _subtitulo('¿Qué incluye?'),
                      ...e.incluye.map(_itemIncluye),
                    ],
                    const SizedBox(height: 20),
                    _subtitulo('Ubicacion'),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colores.azulBrillante, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // Reemplaza por assets/images/mapa.png cuando lo tengas
                        child: const ImagenAsset(
                          ruta: 'assets/images/mapa.png',
                          colorPlaceholder: Color(0xFFCFE0EA),
                          iconoPlaceholder: Icons.map_outlined,
                        ),
                      ),
                    ),
                    if (e.agenda.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _subtitulo('Agenda'),
                      AgendaTimeline(items: e.agenda),
                    ],
                    const SizedBox(height: 26),
                    Center(child: _botonEntrada(e)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.lock_outline, size: 15, color: Colores.grisTexto),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pago protegido · Tu lugar queda\nreservado al instante',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colores.grisTexto),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const BannerPremium(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subtitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colores.azulOscuro,
        ),
      ),
    );
  }

  Widget _infoBasica(IconData icono, String etiqueta, String valor, String? extra) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 22, color: Colores.azulOscuro),
        const SizedBox(height: 6),
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colores.azulOscuro)),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colores.azulOscuro,
          ),
        ),
        if (extra != null)
          Text(extra, style: const TextStyle(fontSize: 11, color: Colores.grisTexto)),
      ],
    );
  }

  Widget _tarjetaOrganizador() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 46,
              height: 46,
              child: ImagenAsset(
                ruta: _organizador.foto,
                iconoPlaceholder: Icons.person,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _organizador.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
                Text(
                  _organizador.rol,
                  style: const TextStyle(fontSize: 11, color: Colores.azulOscuro),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/perfil-organizador'),
            child: const Text(
              'Ver perfil',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colores.azulBrillante,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cupos(Evento e) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cupos disponibles',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
            Text(
              '${e.cuposDisponibles}/${e.cuposTotales}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: e.cuposDisponibles / e.cuposTotales,
            minHeight: 14,
            backgroundColor: Colores.azulMuyClaro,
            valueColor: const AlwaysStoppedAnimation<Color>(Colores.azulBrillante),
          ),
        ),
      ],
    );
  }

  Widget _itemIncluye(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colores.azulBrillante, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 12, color: Colores.azulOscuro, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEntrada(Evento e) {
    return Container(
      width: 250,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Colores.azulOscuro, Color(0xFF1F2E8C)],
        ),
      ),
      child: TextButton(
        onPressed: () => _inscribirse(e),
        child: Text(
          e.esGratis ? 'Entrada gratis Aquí' : 'Reservar entrada',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
