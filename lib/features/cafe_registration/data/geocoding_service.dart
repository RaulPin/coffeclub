import 'dart:convert';

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

/// Autocompletado y geocodificación de direcciones con Photon (OpenStreetMap).
/// Es gratuito y no requiere API key. Para producción con mucho tráfico,
/// conviene alojar la propia instancia de Photon.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'photon.komoot.io';

  /// Busca direcciones que coincidan con [query]. Devuelve lista vacía si la
  /// consulta es muy corta o si hay un error de red.
  Future<List<GeoResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 4) return const [];

    final uri = Uri.https(_host, '/api/', {
      'q': q,
      'limit': '6',
      'lang': 'es',
    });

    try {
      final res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const [];

      final body = json.decode(res.body) as Map<String, dynamic>;
      final features = (body['features'] as List?) ?? const [];

      final results = <GeoResult>[];
      for (final f in features) {
        final feature = f as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>?;
        final coords = geometry?['coordinates'] as List?;
        if (coords == null || coords.length < 2) continue;

        final props =
            (feature['properties'] as Map<String, dynamic>?) ?? const {};
        results.add(GeoResult(
          label: _labelFrom(props),
          lng: (coords[0] as num).toDouble(),
          lat: (coords[1] as num).toDouble(),
        ));
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// Construye una dirección legible a partir de las propiedades de Photon.
  String _labelFrom(Map<String, dynamic> p) {
    String? s(String k) {
      final v = p[k];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    // Primera línea: calle + número, o el nombre del lugar.
    final street = s('street');
    final house = s('housenumber');
    final name = s('name');
    final line1 = street != null
        ? (house != null ? '$street $house' : street)
        : name;

    final parts = <String>[
      if (line1 != null) line1,
      if (s('postcode') != null) s('postcode')!,
      if (s('city') != null) s('city')!,
      if (s('district') != null && s('city') == null) s('district')!,
      if (s('state') != null) s('state')!,
    ];
    final label = parts.join(', ');
    return label.isEmpty ? (name ?? 'Ubicación') : label;
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final service = GeocodingService();
  ref.onDispose(() => service._client.close());
  return service;
});
