import 'package:cloud_firestore/cloud_firestore.dart';

class Inscripcion {
  final String uid;
  final String eventoId;
  final String nombre;
  final DateTime creadaEn;
  final String precioPagado;
  final String estado; // "Activa", "Anulada", "Asistio"
  final String codigo; // código criptográfico único para validación
  final DateTime? checkInEn;

  Inscripcion({
    required this.uid,
    required this.eventoId,
    required this.nombre,
    required this.creadaEn,
    required this.precioPagado,
    this.estado = 'Activa',
    required this.codigo,
    this.checkInEn,
  });

  bool get esActiva => estado == 'Activa';
  bool get asistio => estado == 'Asistio';
  bool get anulada => estado == 'Anulada';

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'eventoId': eventoId,
        'nombre': nombre,
        'creadaEn': Timestamp.fromDate(creadaEn),
        'precioPagado': precioPagado,
        'estado': estado,
        'codigo': codigo,
        'checkInEn': checkInEn != null ? Timestamp.fromDate(checkInEn!) : null,
      };

  factory Inscripcion.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? eventoId,
  }) {
    final j = doc.data() ?? {};
    final idPadre = eventoId ??
        (doc.reference.parent.parent != null
            ? doc.reference.parent.parent!.id
            : (j['eventoId'] as String? ?? ''));

    return Inscripcion(
      uid: doc.id,
      eventoId: idPadre,
      nombre: j['nombre'] as String? ?? '',
      creadaEn: j['creadaEn'] is Timestamp
          ? (j['creadaEn'] as Timestamp).toDate()
          : DateTime.now(),
      precioPagado: j['precioPagado'] as String? ?? '',
      estado: j['estado'] as String? ?? 'Activa',
      codigo: j['codigo'] as String? ?? '',
      checkInEn: (j['checkInEn'] as Timestamp?)?.toDate(),
    );
  }
}
