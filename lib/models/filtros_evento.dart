/// Lo que el usuario eligió en el modal de filtros.
class FiltrosEvento {
  List<String> categorias;
  String fecha; // "Cualquier fecha", "Hoy", "Esta semana", "Este mes"
  String precio; // "", "Gratis" o "De pago"

  FiltrosEvento({
    List<String>? categorias,
    this.fecha = 'Cualquier fecha',
    this.precio = '',
  }) : categorias = categorias ?? [];

  /// Cuántos filtros hay activos (el número rojo del botón).
  int get cantidad {
    int total = categorias.length;
    if (fecha != 'Cualquier fecha') total++;
    if (precio.isNotEmpty) total++;
    return total;
  }

  bool get hayFiltros => cantidad > 0;

  FiltrosEvento copia() {
    return FiltrosEvento(
      categorias: List<String>.from(categorias),
      fecha: fecha,
      precio: precio,
    );
  }
}
