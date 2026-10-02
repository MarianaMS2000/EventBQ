import 'package:flutter/material.dart';

class PaginaOnboarding {
  String titulo;
  String subtitulo;
  String imagen; // ruta del asset
  Color colorFondoImagen; // color del "blob" de la ilustración (placeholder)

  PaginaOnboarding({
    required this.titulo,
    required this.subtitulo,
    required this.imagen,
    required this.colorFondoImagen,
  });
}
