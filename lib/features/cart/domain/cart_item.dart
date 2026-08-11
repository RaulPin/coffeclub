import '../../menu/domain/product.dart';

/// Línea del carrito: un producto con su cantidad.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get subtotalCents => product.priceCents * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}
