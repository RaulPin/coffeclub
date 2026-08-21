import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../menu/domain/product.dart';
import '../domain/cart_item.dart';

/// Maneja el carrito de compra en memoria.
class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super([]);

  void add(Product product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      final updated = [...state];
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = updated;
    }
  }

  void remove(Product product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index == -1) return;
    final item = state[index];
    if (item.quantity <= 1) {
      state = [...state]..removeAt(index);
    } else {
      final updated = [...state];
      updated[index] = item.copyWith(quantity: item.quantity - 1);
      state = updated;
    }
  }

  /// Quita por completo una línea del carrito (sin importar la cantidad).
  void removeLine(Product product) {
    state = state.where((i) => i.product.id != product.id).toList();
  }

  void clear() => state = [];

  int get totalCents =>
      state.fold(0, (sum, item) => sum + item.subtotalCents);

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartControllerProvider =
    StateNotifierProvider<CartController, List<CartItem>>((ref) {
  return CartController();
});

/// Total del carrito en centavos (reactivo).
final cartTotalProvider = Provider<int>((ref) {
  final items = ref.watch(cartControllerProvider);
  return items.fold(0, (sum, item) => sum + item.subtotalCents);
});
