import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../application/cafe_menu_controller.dart';
import '../domain/product.dart';
import 'demo_menu.dart';
import 'firestore_menu_repository.dart';

/// Fuente de datos del menú. En producción, lee de Firestore.
abstract interface class MenuRepository {
  Future<List<Product>> fetchMenu();
}

/// Menú de demo (lee la semilla `kDemoMenu`).
class MockMenuRepository implements MenuRepository {
  @override
  Future<List<Product>> fetchMenu() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return kDemoMenu;
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  if (AppConfig.useMockBackend) return MockMenuRepository();
  return FirestoreMenuRepository();
});

/// Menú que ve el CLIENTE. En modo demo se lee del store editable de la
/// cafetería (`cafeMenuProvider`), filtrando solo los productos disponibles,
/// para que los cambios que hace el café se reflejen al instante.
final menuProvider = FutureProvider<List<Product>>((ref) async {
  if (AppConfig.useMockBackend) {
    return ref
        .watch(cafeMenuProvider)
        .where((p) => p.available)
        .toList();
  }
  return ref.watch(menuRepositoryProvider).fetchMenu();
});

/// Menú agrupado por categoría, en orden: Café → Pizza → Postre.
final menuByCategoryProvider =
    FutureProvider<Map<String, List<Product>>>((ref) async {
  final products = await ref.watch(menuProvider.future);
  const order = ['Café', 'Pizza', 'Postre'];
  final grouped = <String, List<Product>>{};
  for (final category in order) {
    final items = products.where((p) => p.category == category).toList();
    if (items.isNotEmpty) grouped[category] = items;
  }
  return grouped;
});
