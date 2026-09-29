import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_menu.dart';
import '../domain/product.dart';

/// Menú administrable **por cafetería** (store en memoria para el demo).
///
/// Guarda un mapa `cafeId -> productos`. Cada cafetería empieza con el menú
/// semilla (`kDemoMenu`) y lo edita de forma independiente. En producción
/// cada café tendría su menú en Firestore.
class CafeMenuController extends StateNotifier<Map<String, List<Product>>> {
  CafeMenuController() : super({});

  /// Menú actual de una cafetería (la semilla si aún no la ha editado).
  List<Product> menuOf(String cafeId) => state[cafeId] ?? kDemoMenu;

  void _set(String cafeId, List<Product> list) {
    state = {...state, cafeId: list};
  }

  void add(String cafeId, Product product) {
    _set(cafeId, [...menuOf(cafeId), product]);
  }

  void update(String cafeId, Product product) {
    _set(cafeId, [
      for (final p in menuOf(cafeId))
        if (p.id == product.id) product else p,
    ]);
  }

  void remove(String cafeId, String productId) {
    _set(cafeId, menuOf(cafeId).where((p) => p.id != productId).toList());
  }

  void toggleAvailable(String cafeId, String productId) {
    _set(cafeId, [
      for (final p in menuOf(cafeId))
        if (p.id == productId) p.copyWith(available: !p.available) else p,
    ]);
  }
}

final cafeMenuControllerProvider =
    StateNotifierProvider<CafeMenuController, Map<String, List<Product>>>(
        (ref) => CafeMenuController());

/// Menú (todos los productos) de una cafetería, reactivo a sus ediciones.
final cafeMenuProvider = Provider.family<List<Product>, String>((ref, cafeId) {
  final all = ref.watch(cafeMenuControllerProvider);
  return all[cafeId] ?? kDemoMenu;
});

/// Menú que ve el CLIENTE de una cafetería: solo productos disponibles.
final cafeClientMenuProvider =
    Provider.family<List<Product>, String>((ref, cafeId) {
  return ref.watch(cafeMenuProvider(cafeId)).where((p) => p.available).toList();
});
