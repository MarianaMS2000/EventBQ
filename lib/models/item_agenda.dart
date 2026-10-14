class ItemAgenda {
  String hora; // "10:00 AM - 11:00 AM"
  String descripcion;

  ItemAgenda({required this.hora, required this.descripcion});

  Map<String, dynamic> toJson() => {'hora': hora, 'descripcion': descripcion};

  factory ItemAgenda.fromJson(Map<String, dynamic> j) => ItemAgenda(
        hora: j['hora'] as String? ?? '',
        descripcion: j['descripcion'] as String? ?? '',
      );
}
