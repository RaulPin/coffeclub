/// Producto del menú (café, comida, etc.).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.category,
    this.imageUrl,
    this.eligibleForDailyPerk = false,
  });

  final String id;
  final String name;
  final String description;

  /// Precio en centavos de MXN.
  final int priceCents;
  final String category;
  final String? imageUrl;

  /// Si este producto es el que cubre el beneficio de socio
  /// ("1 café al día por $1"). Hoy: solo el Americano.
  final bool eligibleForDailyPerk;

  double get price => priceCents / 100;
}
