/// Cafetería registrada en Barra (una tienda del marketplace).
class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    this.tagline = '',
    this.imageUrl,
    this.etaMinutes = 5,
    this.rating = 4.8,
    this.lockerCount = 12,
    this.lat,
    this.lng,
    this.mpConnected = false,
  });

  final String id;
  final String name;
  final String address;

  /// Coordenadas de la cafetería para mostrarla en el mapa.
  /// Si faltan, la cafetería no se dibuja como pin.
  final double? lat;
  final double? lng;

  /// true si la cafetería tiene coordenadas válidas para el mapa.
  bool get hasLocation => lat != null && lng != null;

  /// true si la cafetería ya conectó su cuenta de Mercado Pago (puede cobrar).
  final bool mpConnected;

  /// Frase corta de la cafetería (p. ej. "Café de especialidad · Condesa").
  final String tagline;

  /// Foto/logo de la cafetería.
  final String? imageUrl;

  /// Tiempo estimado de preparación (minutos), para mostrar en descubrimiento.
  final int etaMinutes;

  /// Calificación promedio (0–5).
  final double rating;

  /// Vestigial (recogida en barra, sin casilleros). Se conserva por compat.
  final int lockerCount;
}
