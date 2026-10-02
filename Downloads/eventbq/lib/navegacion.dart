import 'package:flutter/material.dart';

/// Va a una pestaña de la pantalla principal.
/// 0 Inicio, 1 Explorar, 2 Mis eventos, 3 Perfil.
void irAPestana(BuildContext context, int indice) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/home',
    (route) => false,
    arguments: indice,
  );
}
