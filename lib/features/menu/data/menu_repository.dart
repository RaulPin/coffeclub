import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/product.dart';

/// Fuente de datos del menú. En producción, lee de Firestore.
abstract interface class MenuRepository {
  Future<List<Product>> fetchMenu();
}

class MockMenuRepository implements MenuRepository {
  @override
  Future<List<Product>> fetchMenu() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      Product(
        id: 'espresso',
        name: 'Espresso',
        description: 'Shot doble de espresso de la casa.',
        priceCents: 100,
        category: 'Café',
      ),
      Product(
        id: 'americano',
        name: 'Americano',
        description: 'Espresso con agua caliente.',
        priceCents: 100,
        category: 'Café',
      ),
      Product(
        id: 'latte',
        name: 'Latte',
        description: 'Espresso con leche vaporizada.',
        priceCents: 100,
        category: 'Café',
      ),
      Product(
        id: 'capuccino',
        name: 'Capuccino',
        description: 'Espresso, leche y espuma.',
        priceCents: 100,
        category: 'Café',
      ),
      Product(
        id: 'pizza-slice',
        name: 'Rebanada de Pizza',
        description: 'Rebanada recién horneada.',
        priceCents: 3500,
        category: 'Comida',
      ),
    ];
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MockMenuRepository();
});

final menuProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(menuRepositoryProvider).fetchMenu();
});
