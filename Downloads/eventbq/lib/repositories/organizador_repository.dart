import '../data/datos_simulados.dart';
import '../models/organizador.dart';

class OrganizadorRepository {
  // Por ahora solo hay un organizador de ejemplo.
  Organizador obtenerOrganizador() {
    return datosOrganizador;
  }
}
