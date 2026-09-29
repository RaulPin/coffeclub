import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
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

