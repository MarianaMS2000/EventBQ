import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ResultadoGeocodificacion {
  final LatLng punto;
  final String direccion;

  const ResultadoGeocodificacion({
    required this.punto,
    required this.direccion,
  });
}

/// Servicio de geocodificación mediante OpenStreetMap Nominatim.
/// Compatible con todas las plataformas (Android, iOS y Flutter Web).
/// Cumple con la política de uso de Nominatim:
/// - Máximo 1 petición por segundo (throttled).
/// - User-Agent propio y descriptivo.
/// - Sesgado a Barranquilla, Colombia.
class GeocodificadorService {
  static const LatLng centroBarranquilla = LatLng(10.9685, -74.7813);
  static const String _userAgent = 'EventBQ-App/1.0 (contacto@eventbq.com)';

  static DateTime _ultimaPeticion = DateTime.fromMillisecondsSinceEpoch(0);

  /// Busca coordenadas para un texto descriptivo o dirección en Barranquilla.
  static Future<ResultadoGeocodificacion?> buscarLugar(String consulta) async {
    final texto = consulta.trim();
    if (texto.length < 3) return null;

    // Respetar política de máx 1 petición por segundo
    final ahora = DateTime.now();
    final transcurrido = ahora.difference(_ultimaPeticion).inMilliseconds;
    if (transcurrido < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - transcurrido));
    }
    _ultimaPeticion = DateTime.now();

    // Sesgar a Barranquilla si no se especifica la ciudad
    String query = texto;
    final lower = texto.toLowerCase();
    if (!lower.contains('barranquilla') && !lower.contains('colombia')) {
      query = '$texto, Barranquilla, Colombia';
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(query)}&format=json&limit=1&addressdetails=1'
        '&viewbox=-75.05,11.18,-74.65,10.82',
      );

      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'es',
        },
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final primer = list.first as Map<String, dynamic>;
          final lat = double.tryParse(primer['lat']?.toString() ?? '');
          final lon = double.tryParse(primer['lon']?.toString() ?? '');
          final display = primer['display_name']?.toString() ?? texto;

          if (lat != null && lon != null) {
            return ResultadoGeocodificacion(
              punto: LatLng(lat, lon),
              direccion: display,
            );
          }
        }
      }
    } catch (_) {
      // Si no hay internet o falla la red, retorna null de forma segura
    }
    return null;
  }
}
