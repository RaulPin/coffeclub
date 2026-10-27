import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Un resultado de búsqueda de dirección: etiqueta legible + coordenadas.
class GeoResult {
  const GeoResult({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;
}

/// Autocompletado y geocodificación de direcciones con Nominatim
/// (OpenStreetMap). Gratuito, sin API key y con CORS habilitado (funciona en
/// web). Para producción con mucho tráfico conviene alojar la propia instancia
/// o usar un servicio de pago, respetando la política de uso (máx. 1 req/seg).
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'nominatim.openstreetmap.org';

  /// Busca direcciones que coincidan con [query]. Devuelve lista vacía si la
  /// consulta es muy corta o si hay un error de red.
  Future<List<GeoResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 4) return const [];

    final uri = Uri.https(_host, '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '6',
      'countrycodes': 'mx', // prioriza resultados en México
      'accept-language': 'es',
    });

    try {
      // En web el navegador pone su propio User-Agent (y rechaza fijarlo);
      // en móvil lo enviamos para cumplir la política de uso de Nominatim.
      final headers = kIsWeb
          ? const <String, String>{}
          : const {'User-Agent': 'BarraApp/0.1 (soporte@barra.mx)'};

      final res = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];

      final data = json.decode(res.body);
      if (data is! List) return const [];

      final results = <GeoResult>[];
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat == null || lon == null) continue;
        results.add(GeoResult(
          label: _shorten(item['display_name']?.toString() ?? 'Ubicación'),
          lat: lat,
          lng: lon,
        ));
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// Acorta el `display_name` (que puede ser muy largo) a sus primeras partes.
  String _shorten(String full) {
    final parts = full.split(',').map((e) => e.trim()).toList();
    if (parts.length <= 4) return full;
    return parts.take(4).join(', ');
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final service = GeocodingService();
  ref.onDispose(() => service._client.close());
  return service;
});
