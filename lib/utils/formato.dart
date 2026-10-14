import 'package:flutter/material.dart';
import '../models/evento.dart';

const List<String> mesesCortos = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const List<String> mesesLargos = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String _dos(int n) => n.toString().padLeft(2, '0');

/// "24/12/2026"
String formatoFecha(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

/// "02:00 PM"
String formatoHora(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  return '${_dos(h)}:${_dos(t.minute)} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

/// "Octubre 2026"
String mesYAnio(DateTime d) => '${mesesLargos[d.month - 1]} ${d.year}';

/// Solo la fecha (sin hora) para comparar días.
DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// "$ 60.000" (con puntos de miles). 0 = "$ Gratis".
String formatoPrecio(double valor) {
  if (valor <= 0) return '\$ Gratis';
  return '\$ ${formatoMiles(valor.round())}';
}

/// 1920000 -> "1.920.000"
String formatoMiles(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

/// Escribe en el evento todos los textos de fecha y hora a partir de valores reales.
void aplicarFechaAEvento(
  Evento e,
  DateTime fecha,
  TimeOfDay inicio,
  TimeOfDay cierre,
) {
  final mes = mesesCortos[fecha.month - 1];
  e.fechaIso = soloFecha(fecha).toIso8601String();
  e.dia = _dos(fecha.day);
  e.mes = mes;
  e.fechaCompleta = '$mes ${_dos(fecha.day)} • ${formatoHora(inicio)} • ${fecha.year}';
  e.fechaLarga = '${fecha.day} de ${mesesLargos[fecha.month - 1]} ${fecha.year}';
  e.horario = '${formatoHora(inicio)} - ${formatoHora(cierre)}';
}

/// Valida un correo de forma sencilla.
bool correoValido(String correo) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo.trim());

/// Convierte lo que escribió el usuario en un número: "25000", "25.000", "25,50".
/// Devuelve null si no es un número.
double? parsearPrecio(String texto) {
  var t = texto.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    t = t.replaceAll('.', '');
  }
  return double.tryParse(t);
}
