import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventbq/models/usuario.dart';
import 'package:eventbq/models/evento.dart';
import 'package:eventbq/repositories/evento_repository.dart';
import 'package:eventbq/utils/formato.dart';
import 'package:eventbq/utils/manejo_errores.dart';

void main() {
  group('Usuario Model & Avatar Tests', () {
    test('Nuevo usuario se crea con foto vacia', () {
      final u = Usuario(
        nombre: 'Pedro Perez',
        usuario: 'pedro_10',
        correo: 'pedro@gmail.com',
      );
      expect(u.foto, isEmpty);
    });

    test('Usuario.fromJson limpia foto de avatar por defecto o assets', () {
      final jsonConAvatar = {
        'nombre': 'Pedro',
        'usuario': 'pedro_10',
        'correo': 'pedro@gmail.com',
        'foto': 'assets/images/avatar.png',
      };
      final u = Usuario.fromJson(jsonConAvatar, uid: 'uid123');
      expect(u.foto, isEmpty);
      expect(u.id, equals('uid123'));
    });

    test('Usuario.fromJson preserva fotos reales personalizadas', () {
      final jsonConFoto = {
        'nombre': 'Pedro',
        'usuario': 'pedro_10',
        'correo': 'pedro@gmail.com',
        'foto': 'base64:9j4AAQSkZJRg...',
      };
      final u = Usuario.fromJson(jsonConFoto, uid: 'uid123');
      expect(u.foto, equals('base64:9j4AAQSkZJRg...'));
    });
  });

  group('FechaFin y Cierre de Eventos en Colombia (UTC-5)', () {
    test('Calcula fechaFin sumando duracion con horario de cierre', () {
      final fecha = DateTime(2026, 11, 20);
      final fin = calcularFechaFinColombia(
        fecha: fecha,
        inicio: const TimeOfDay(hour: 18, minute: 0),
        cierre: const TimeOfDay(hour: 21, minute: 0),
      );
      expect(fin, isNotNull);
      // 21:00 Colombia (UTC-5) = 02:00 UTC dia siguiente
      expect(fin.toUtc().hour, equals(2));
    });

    test('haFinalizado retorna true cuando la fecha actual sobrepasa fechaFin', () {
      final pasado = DateTime.now().subtract(const Duration(hours: 2));
      final eventoPasado = Evento(
        id: 'ev_pasado',
        titulo: 'Evento Pasado',
        categoria: 'Música',
        fechaCompleta: 'Ayer',
        dia: '07',
        mes: 'Nov',
        lugar: 'Barranquilla',
        precio: 'Gratis',
        imagen: '',
        cuposTotales: 100,
        cuposDisponibles: 50,
      );
      eventoPasado.fechaFin = pasado;
      expect(eventoPasado.haFinalizado, isTrue);
    });
  });

  group('Manejo de Errores Amigables y Auditoria de Tamaño', () {
    test('Traduce errores tecnicos de Firestore a lenguaje amigable', () {
      const errorSize = 'Document ... exceeds the maximum allowed size of 1,048,576 bytes';
      final trad1 = traducirError(errorSize);
      expect(trad1, contains('demasiado pesada'));

      const errorPerm = '[cloud_firestore/permission-denied] Missing or insufficient permissions.';
      final trad2 = traducirError(errorPerm);
      expect(trad2, contains('permisos'));
    });

    test('estimarTamanoDocumentoFirestore estima correctamente bytes', () {
      final datos = {
        'titulo': 'Festival de Jazz',
        'precio': 25000,
        'activo': true,
      };
      final tamano = estimarTamanoDocumentoFirestore(datos);
      expect(tamano, greaterThan(30));
      expect(tamano, lessThan(200));
    });
  });

  group('Búsqueda Flexible y Normalización de Categorías', () {
    test('normalizarTexto remueve tildes y pasa a minusculas', () {
      expect(EventoRepository.normalizarTexto('Música'), equals('musica'));
      expect(EventoRepository.normalizarTexto('Gastronomía'), equals('gastronomia'));
      expect(EventoRepository.normalizarTexto('BOGOTÁ'), equals('bogota'));
      expect(EventoRepository.normalizarTexto('  Malecón  '), equals('malecon'));
    });

    test('coincidencia flexible entre categorias singular y plural', () {
      final eventoCat = EventoRepository.normalizarTexto('Deportes');
      final filtroCat = EventoRepository.normalizarTexto('Deporte');
      final coincide = eventoCat.startsWith('deport') && filtroCat.startsWith('deport');
      expect(coincide, isTrue);
    });
  });
}
