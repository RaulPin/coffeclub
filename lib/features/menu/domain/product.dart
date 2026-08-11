/// Producto del menú (café, comida, etc.).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;

  /// Precio en centavos de MXN.
  final int priceCents;
  final String category;
  final String? imageUrl;

  double get price => priceCents / 100;
}
