import '../data/datos_simulados.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  List<Categoria> obtenerCategorias() {
    return datosCategorias;
  }
}
