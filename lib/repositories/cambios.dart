import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Se suma 1 cada vez que se guarda algo (evento nuevo, inscripción, perfil...).
/// Las pantallas que muestran datos escuchan este número y se redibujan solas,
/// así nunca muestran información vieja.
final ValueNotifier<int> cambiosDatos = ValueNotifier<int>(0);

void notificarCambios() => cambiosDatos.value++;

/// Envuelve una parte de la pantalla para que se redibuje cuando cambian los datos.
class EscuchaDatos extends StatelessWidget {
  final WidgetBuilder builder;

  const EscuchaDatos({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: cambiosDatos,
      builder: (context, _, __) => builder(context),
    );
  }
}
