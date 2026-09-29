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
    this.available = true,
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

  /// Si el producto está disponible para pedir. La cafetería lo puede
  /// activar/desactivar sin borrarlo.
  final bool available;

  double get price => priceCents / 100;

  Product copyWith({
    String? name,
    String? description,
    int? priceCents,
    String? category,
    String? imageUrl,
    bool? eligibleForDailyPerk,
    bool? available,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        priceCents: priceCents ?? this.priceCents,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        eligibleForDailyPerk: eligibleForDailyPerk ?? this.eligibleForDailyPerk,
        available: available ?? this.available,
      );
}
