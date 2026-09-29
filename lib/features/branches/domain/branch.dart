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
  });

  final String id;
  final String name;
  final String address;

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
