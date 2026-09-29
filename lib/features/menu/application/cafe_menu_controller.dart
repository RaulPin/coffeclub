import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_menu.dart';
import '../domain/product.dart';

/// Menú administrable por la cafetería (store en memoria para el demo).
///
/// En producción cada cafetería tendría su propio menú en Firestore; aquí
/// vive en memoria y se pierde al reiniciar. El menú del cliente
/// (`menuProvider`) lee de aquí, así los cambios se reflejan al instante.
class CafeMenuController extends StateNotifier<List<Product>> {
  CafeMenuController() : super(List.of(kDemoMenu));

  void add(Product product) {
    state = [...state, product];
  }

  void update(Product product) {
    state = [
      for (final p in state)
        if (p.id == product.id) product else p,
    ];
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void toggleAvailable(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(available: !p.available) else p,
    ];
  }
}

final cafeMenuProvider =
    StateNotifierProvider<CafeMenuController, List<Product>>((ref) {
  return CafeMenuController();
});
