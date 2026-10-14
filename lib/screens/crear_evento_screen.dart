import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/datos_simulados.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../utils/formato.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/dialogo_evento_publicado.dart';
import '../widgets/dialogo_limite_alcanzado.dart';
import '../widgets/pantalla_con_barra.dart';

/// "Crear nuevo evento": formulario que se abre con el botón + del centro
/// de la barra de navegación.
///
/// "Publicar evento" valida el formulario, guarda el evento en la lista de
/// eventos (List<Evento>) y en SharedPreferences, y abre el Panel de Organizador.
/// El evento aparece en Explorar, Inicio y en "Mis eventos creados".
class CrearEventoScreen extends StatefulWidget {
  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  static const _borde = Color(0xFF3A4570); // borde de los campos
  static const _bordeSuave = Color(0xFF8A93AD); // chips sin seleccionar
  static const _maxImagenes = 2;

  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _sobreCtrl = TextEditingController();
  final _incluyeCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  String? _categoria;
  DateTime _fecha = soloFecha(DateTime.now().add(const Duration(days: 7)));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _horaCierre = const TimeOfDay(hour: 19, minute: 0);
  final List<Uint8List> _imagenes = []; // imágenes elegidas de la galería
  final _picker = ImagePicker();
  int _aforo = 120;
  bool _gratis = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _sobreCtrl.dispose();
    _incluyeCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  // ---------- formatos ----------
  String _formatoFecha(DateTime d) => formatoFecha(d);

  String _formatoHora(TimeOfDay t) => formatoHora(t);

  // ---------- selectores ----------
  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: soloFecha(DateTime.now()),
      lastDate: DateTime(2035),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final h = await showTimePicker(
      context: context,
      initialTime: inicio ? _horaInicio : _horaCierre,
      // Solo se escribe la hora y se elige AM/PM (sin el reloj circular).
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (h == null) return;
    setState(() => inicio ? _horaInicio = h : _horaCierre = h);
  }

  /// Elige una imagen de la galería (máximo 2).
  Future<void> _elegirImagen() async {
    if (_imagenes.length >= _maxImagenes) return;
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 60,
      );
      if (foto == null) return; // canceló
      final bytes = await foto.readAsBytes();
      if (!mounted) return;
      setState(() => _imagenes.add(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la galería')),
      );
    }
  }

  /// Va al Panel de Organizador quitando de la pila "Crear evento" y
  /// cualquier panel anterior (para que "atrás" no repita pantallas).
  void _irAlPanel() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/panel-organizador',
      (ruta) =>
          ruta.settings.name != '/crear-evento' &&
          ruta.settings.name != '/panel-organizador',
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Revisa el formulario. Devuelve el mensaje del primer error, o null si todo está bien.
  String? _validar() {
    if (_nombreCtrl.text.trim().length < 3) {
      return 'Escribe el nombre del evento (mínimo 3 letras)';
    }
    if (_categoria == null) return 'Elige una categoría';
    if (_ubicacionCtrl.text.trim().length < 3) {
      return 'Escribe la ubicación del evento';
    }
    if (_sobreCtrl.text.trim().isEmpty) {
      return 'Cuéntanos de qué trata el evento';
    }
    final inicio = _horaInicio.hour * 60 + _horaInicio.minute;
    final cierre = _horaCierre.hour * 60 + _horaCierre.minute;
    if (cierre <= inicio) {
      return 'La hora de cierre debe ser después de la hora de inicio';
    }
    if (_fecha.isBefore(soloFecha(DateTime.now()))) {
      return 'La fecha del evento no puede ser anterior a hoy';
    }
    if (!_gratis) {
      final precio = parsearPrecio(_precioCtrl.text);
      if (precio == null || precio <= 0) {
        return 'Escribe el precio o elige "Gratis"';
      }
    }
    return null;
  }

  /// Arma el Evento con lo que escribió el organizador.
  Evento _construirEvento() {
    final valor = _gratis ? 0.0 : (parsearPrecio(_precioCtrl.text) ?? 0.0);
    final imagenes = _imagenes.map(ImagenAsset.bytesATexto).toList();
    final incluye = _incluyeCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final e = Evento(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      titulo: _nombreCtrl.text.trim(),
      categoria: _categoria!,
      fechaCompleta: '',
      dia: '',
      mes: '',
      lugar: _ubicacionCtrl.text.trim(),
      precio: formatoPrecio(valor),
      precioValor: valor,
      imagen: imagenes.isNotEmpty ? imagenes[0] : '',
      imagenDetalle: imagenes.length > 1 ? imagenes[1] : null,
      descripcion: _sobreCtrl.text.trim(),
      incluye: incluye,
      cuposDisponibles: _aforo,
      cuposTotales: _aforo,
    );
    aplicarFechaAEvento(e, _fecha, _horaInicio, _horaCierre);
    return e;
  }

  /// Publicar: si ya llegó al límite muestra "¡Límite alcanzado!";
  /// si no, valida, guarda el evento, muestra "¡Publicado!" y manda al Panel de Organizador.
  Future<void> _publicar() async {
    FocusScope.of(context).unfocus();
    final repo = EventoRepository();

    if (repo.limiteAlcanzado) {
      final destino = await showDialog<String>(
        context: context,
        barrierColor: Colors.black,
        builder: (_) => DialogoLimiteAlcanzado(
          fechaDisponible: repo.fechaProximoEvento,
          publicados: repo.eventosPublicados,
          limite: limiteEventosPeriodo,
        ),
      );
      if (!mounted) return;
      if (destino == 'panel') {
        _irAlPanel();
      } else if (destino == 'planes') {
        // Va directo al plan de Organizador (no al de Asistente).
        Navigator.pushReplacementNamed(
          context,
          '/planes',
          arguments: 'organizador',
        );
      }
      return;
    }

    final error = _validar();
    if (error != null) {
      _aviso(error);
      return;
    }

    repo.publicarEvento(_construirEvento());
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (_) => const DialogoEventoPublicado(),
    );
    if (!mounted) return;
    _irAlPanel();
  }

  // ---------- piezas de diseño ----------
  Widget _etiqueta(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: Colores.azulOscuro,
      ),
    );
  }

  BoxDecoration _caja({double radio = 22, Color? fondo, Color? borde}) {
    return BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(radio),
      border: Border.all(color: borde ?? _borde, width: 2),
    );
  }

  /// Campo de una línea en forma de pastilla.
  Widget _campoPildora({
    required TextEditingController controller,
    required String hint,
    IconData? icono,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _caja(),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, color: Colores.azulOscuro, size: 24),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 15, color: Colores.azulOscuro),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF9AA0AE)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pastilla que muestra un valor y abre un selector al tocarla.
  Widget _pildoraSeleccion(String texto, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: _caja(),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, color: Colores.azulOscuro),
        ),
      ),
    );
  }

  /// Cuadro de texto grande con contador (0/200).
  Widget _cajaTexto({
    required TextEditingController controller,
    required String hint,
    required int maximo,
    required int lineas,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: _caja(radio: 28),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLength: maximo,
            maxLines: lineas,
            minLines: lineas,
            buildCounter: (context,
                    {required currentLength,
                    required isFocused,
                    required maxLength}) =>
                null,
            style: const TextStyle(fontSize: 15, color: Colores.azulOscuro),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintMaxLines: lineas,
              hintStyle: const TextStyle(
                fontSize: 15,
                height: 1.3,
                color: Color(0xFF8A8FA3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, v, _) => Text(
                '${v.text.length}/$maximo',
                style: const TextStyle(fontSize: 14, color: Color(0xFF8A8FA3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipCategoria(String nombre) {
    final seleccionada = _categoria == nombre;
    return GestureDetector(
      onTap: () => setState(() => _categoria = nombre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: _caja(
          fondo: seleccionada ? Colores.azulOscuro : null,
          borde: seleccionada ? Colores.azulOscuro : _bordeSuave,
        ),
        child: Text(
          nombre,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: seleccionada ? Colors.white : _bordeSuave,
          ),
        ),
      ),
    );
  }

  Widget _botonAforo(IconData icono, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 54,
        decoration: _caja(radio: 18),
        child: Icon(icono, color: Colores.azulOscuro, size: 28),
      ),
    );
  }

  Widget _botonMasImagen() {
    return GestureDetector(
      onTap: _elegirImagen,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colores.azulOscuro, width: 4),
        ),
        child: const Icon(Icons.add, color: Colores.azulOscuro, size: 42),
      ),
    );
  }

  /// Imagen elegida de la galería, con una X para quitarla.
  Widget _miniaturaImagen(int indice) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(_imagenes[indice], fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _imagenes.removeAt(indice)),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colores.azulOscuro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaConBarra(
      indiceActual: -1, // ninguna pestaña seleccionada
      alPresionarMas: () {}, // ya estamos en "Crear evento"
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----- Título con flecha -----
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colores.azulOscuro, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Crear nuevo evento',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ----- Nombre -----
              _etiqueta('NOMBRE DEL EVENTO'),
              const SizedBox(height: 8),
              _campoPildora(
                controller: _nombreCtrl,
                hint: 'Ej: Feria de Videojuegos antiguos',
              ),
              const SizedBox(height: 24),

              // ----- Categoría -----
              _etiqueta('CATEGORÍA'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: datosCategoriasEvento.map(_chipCategoria).toList(),
              ),
              const SizedBox(height: 26),

              // ----- Fecha y horas -----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('FECHA'),
                        const SizedBox(height: 8),
                        _pildoraSeleccion(_formatoFecha(_fecha), _elegirFecha),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('HORA DE INICIO'),
                        const SizedBox(height: 8),
                        _pildoraSeleccion(_formatoHora(_horaInicio),
                            () => _elegirHora(inicio: true)),
                        const SizedBox(height: 16),
                        _etiqueta('HORA DE CIERRE'),
                        const SizedBox(height: 8),
                        _pildoraSeleccion(_formatoHora(_horaCierre),
                            () => _elegirHora(inicio: false)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ----- Ubicación -----
              _etiqueta('UBICACIÓN'),
              const SizedBox(height: 8),
              _campoPildora(
                controller: _ubicacionCtrl,
                hint: 'Dirección exacta del lugar',
                icono: Icons.location_on_outlined,
              ),
              const SizedBox(height: 24),

              // ----- Sobre el evento -----
              _etiqueta('SOBRE EL EVENTO'),
              const SizedBox(height: 8),
              _cajaTexto(
                controller: _sobreCtrl,
                hint: 'explicación general sobre de qué trata el evento..',
                maximo: 200,
                lineas: 5,
              ),
              const SizedBox(height: 24),

              // ----- Qué incluye -----
              _etiqueta('¿QUÉ INCLUYE EL EVENTO?'),
              const SizedBox(height: 8),
              _cajaTexto(
                controller: _incluyeCtrl,
                hint: 'Incluye 1: ej. Entrada al concierto / Certificado de asistencia\n'
                    'Incluye 2: ej. Kit de bienvenida / Bebida de cortesía\n'
                    'Incluye 3: ej. Acceso a zona VIP / Parqueadero gratuito',
                maximo: 100,
                lineas: 6,
              ),
              const SizedBox(height: 26),

              // ----- Imágenes -----
              _etiqueta('IMAGENES DEL EVENTO'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 190,
                decoration: _caja(radio: 28),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _imagenes.length; i++) ...[
                        _miniaturaImagen(i),
                        const SizedBox(width: 14),
                      ],
                      if (_imagenes.length < _maxImagenes) _botonMasImagen(),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 22),
                  child: Text(
                    '${_imagenes.length}/$_maxImagenes',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF8A8FA3)),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ----- Aforo -----
              _etiqueta('AFORO MÁXIMO'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _botonAforo(Icons.add, () => setState(() => _aforo += 10)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: _caja(radio: 18),
                      child: Text(
                        '$_aforo',
                        style: const TextStyle(
                            fontSize: 18, color: Colores.azulOscuro),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _botonAforo(Icons.remove, () {
                    if (_aforo > 10) setState(() => _aforo -= 10);
                  }),
                ],
              ),
              const SizedBox(height: 28),

              // ----- Precio -----
              _etiqueta('PRECIO'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _gratis = true;
                        _precioCtrl.clear();
                      }),
                      child: Container(
                        height: 86,
                        alignment: Alignment.center,
                        decoration: _caja(
                          fondo: _gratis ? Colores.azulOscuro : null,
                        ),
                        child: Text(
                          'Gratis',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: _gratis ? Colors.white : Colores.azulOscuro,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colores.azulOscuro)),
                  ),
                  Expanded(
                    child: Container(
                      height: 86,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: _caja(),
                      child: Row(
                        children: [
                          const Text('\$',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colores.azulOscuro)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _precioCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              onChanged: (v) {
                                if (v.isNotEmpty && _gratis) {
                                  setState(() => _gratis = false);
                                }
                              },
                              style: const TextStyle(
                                  fontSize: 20, color: Colores.azulOscuro),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Ej: 25000',
                                hintStyle: TextStyle(
                                    fontSize: 20, color: Color(0xFF9AA0AE)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ----- Publicar -----
              Center(
                child: SizedBox(
                  width: 310,
                  height: 66,
                  child: ElevatedButton(
                    onPressed: _publicar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.azulOscuro,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                    ),
                    child: const Text(
                      'Publicar evento',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
