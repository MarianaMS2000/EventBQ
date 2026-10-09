import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/evento.dart';
import '../navegacion.dart';
import '../repositories/evento_repository.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/aviso_exito.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/tarjeta_evento_horizontal.dart';

/// Perfil del usuario. Tiene dos modos:
///  - lectura (lápiz arriba a la derecha de la tarjeta)
///  - edición (ícono de guardar): Email, Teléfono y Rol se pueden editar,
///    pero por ahora (solo frontend) NO se guarda nada: al guardar solo
///    sale un aviso verde de "cambio exitoso".
///
/// La cámara de la foto abre la galería, pero tampoco guarda ni muestra la
/// foto elegida (solo el aviso verde).
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _usuarioRepo = UsuarioRepository();
  final _eventoRepo = EventoRepository();

  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _rol = TextEditingController();
  bool _editando = false;

  @override
  void dispose() {
    _correo.dispose();
    _telefono.dispose();
    _rol.dispose();
    super.dispose();
  }

  void _empezarEdicion() {
    final u = _usuarioRepo.obtenerUsuarioActual();
    _correo.text = u.correo;
    _telefono.text = u.telefono;
    _rol.text = u.rol;
    setState(() => _editando = true);
  }

  void _guardar() {
    if (!_correo.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un email válido')),
      );
      return;
    }
    // Solo frontend: NO se guarda nada. Cuando haya backend, aquí se llama
    // a la API (o a _usuarioRepo.actualizarPerfil).
    setState(() => _editando = false);
    mostrarAvisoExito(context, '¡Datos actualizados con éxito!');
  }

  /// Abre la galería. La foto elegida no se guarda ni se muestra (demo).
  Future<void> _elegirFoto() async {
    try {
      final foto = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (foto == null || !mounted) return; // canceló la galería
      mostrarAvisoExito(context, '¡Foto de perfil actualizada!');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la galería')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuarioRepo.obtenerUsuarioActual();
    final guardados = _eventoRepo.obtenerFavoritos();

    return SingleChildScrollView(
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
                        onPressed: () => irAPestana(context, 0),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    _avatar(u.foto),
                    const SizedBox(height: 12),
                    Text(
                      u.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _estadistica(
                            '${u.eventosAsistidos}', 'Eventos asistidos'),
                        _estadistica('${u.eventosCreados}', 'Eventos creados'),
                        _estadistica('${u.rating}', 'Rating'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ----- Parte clara -----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 18, bottom: 130),
            decoration: const BoxDecoration(
              color: Colores.fondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _tarjetaInformacion(
                          u.correo, u.telefono, u.rol, u.miembroDesde),
                      const SizedBox(height: 16),
                      // Botón de Cerrar Sesión (Ubicado debajo de Información Personal)
                      OutlinedButton(
                        onPressed: () {
                          _usuarioRepo.cerrarSesion();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/bienvenida', (r) => false);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(
                            color: Color(0xFF8B2626),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFF8B2626),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: Color(0xFF8B2626),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Encabezado rosado "Eventos guardados"
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFA8FDB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: const Text(
                    'Eventos guardados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (guardados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Aún no tienes eventos guardados. Toca el corazón de un evento para guardarlo.',
                      style: TextStyle(color: Colores.grisTexto),
                    ),
                  ),
                ...guardados.map(_tarjetaGuardado),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String ruta) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: ImagenAsset(ruta: ruta, iconoPlaceholder: Icons.person),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: _elegirFoto,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera_outlined,
                    size: 18, color: Colores.azulOscuro),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadistica(String numero, String texto) {
    return Expanded(
      child: Column(
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaInformacion(
      String correo, String telefono, String rol, String miembro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colores.azulOscuro, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colores.azulOscuro,
                ),
              ),
              GestureDetector(
                onTap: _editando ? _guardar : _empezarEdicion,
                child: Icon(
                  _editando ? Icons.save_outlined : Icons.edit_outlined,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campo('Email', correo, _correo, TextInputType.emailAddress),
          _campo('Teléfono', telefono, _telefono, TextInputType.phone),
          _campo('Rol actual', rol, _rol, TextInputType.text),
          _dato('Miembro desde', miembro), // este campo nunca se edita
        ],
      ),
    );
  }

  /// En lectura muestra texto; en edición muestra una caja de texto.
  Widget _campo(String etiqueta, String valor, TextEditingController c,
      TextInputType tipo) {
    if (!_editando) return _dato(etiqueta, valor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta,
              style: const TextStyle(fontSize: 11, color: Colores.grisTexto)),
          const SizedBox(height: 2),
          TextField(
            controller: c,
            keyboardType: tipo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colores.azulOscuro,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFE9EAEC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Colores.azulOscuro, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Colores.azulOscuro, width: 0.8),
              ),
            ),
          ),
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
          Text(etiqueta,
              style: const TextStyle(fontSize: 11, color: Colores.grisTexto)),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaGuardado(Evento e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TarjetaEventoHorizontal(
        evento: e,
        mostrarCorazon: true,
        onCorazon: () async {
          await _eventoRepo.alternarFavorito(e.id);
          setState(() {});
        },
        onVer: () =>
            Navigator.pushNamed(context, '/detalle-evento', arguments: e),
      ),
    );
  }
}
