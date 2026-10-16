import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/demo_menu.dart';
import '../domain/product.dart';

/// Acceso al menú de cada cafetería: observar (stream) y editar.
abstract interface class CafeMenuRepository {
  Stream<List<Product>> watchMenu(String cafeId);
  Future<void> upsert(String cafeId, Product product);
  Future<void> remove(String cafeId, String productId);
  Future<void> setAvailable(String cafeId, String productId, bool available);
}

/// Implementación sobre Firestore: `cafes/{cafeId}/products/{productId}`.
class FirestoreCafeMenuRepository implements CafeMenuRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String cafeId) =>
      _db.collection('cafes').doc(cafeId).collection('products');

  @override
  Stream<List<Product>> watchMenu(String cafeId) =>
      _col(cafeId).snapshots().map(
            (snap) => snap.docs.map(_fromDoc).toList(),
          );

  @override
  Future<void> upsert(String cafeId, Product product) =>
      _col(cafeId).doc(product.id).set(_toMap(product));

  @override
  Future<void> remove(String cafeId, String productId) =>
      _col(cafeId).doc(productId).delete();

  @override
  Future<void> setAvailable(String cafeId, String productId, bool available) =>
      _col(cafeId).doc(productId).update({'available': available});

  Product _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Product(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      priceCents: (d['priceCents'] as num?)?.toInt() ?? 0,
      category: d['category'] as String? ?? 'Otros',
      imageUrl: d['imageUrl'] as String?,
      available: d['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toMap(Product p) => {
        'name': p.name,
        'description': p.description,
        'priceCents': p.priceCents,
        'category': p.category,
        'imageUrl': p.imageUrl,
        'available': p.available,
      };
}

/// Implementación en memoria (modo demo sin Firestore). Cada café arranca con
/// la semilla y sus cambios viven mientras corre la app.
class InMemoryCafeMenuRepository implements CafeMenuRepository {
  final Map<String, List<Product>> _menus = {};
  final Map<String, StreamController<List<Product>>> _ctrls = {};

  List<Product> _menuOf(String cafeId) =>
      _menus[cafeId] ??= List.of(kDemoMenu);

  StreamController<List<Product>> _ctrl(String cafeId) =>
      _ctrls[cafeId] ??= StreamController<List<Product>>.broadcast();

  void _emit(String cafeId) =>
      _ctrl(cafeId).add(List.of(_menuOf(cafeId)));

  @override
  Stream<List<Product>> watchMenu(String cafeId) async* {
    yield List.of(_menuOf(cafeId));
    yield* _ctrl(cafeId).stream;
  }

  @override
  Future<void> upsert(String cafeId, Product product) async {
    final list = _menuOf(cafeId);
    final i = list.indexWhere((p) => p.id == product.id);
    if (i == -1) {
      list.add(product);
    } else {
      list[i] = product;
    }
    _emit(cafeId);
  }

  @override
  Future<void> remove(String cafeId, String productId) async {
    _menuOf(cafeId).removeWhere((p) => p.id == productId);
    _emit(cafeId);
  }

  @override
  Future<void> setAvailable(
      String cafeId, String productId, bool available) async {
    final list = _menuOf(cafeId);
    final i = list.indexWhere((p) => p.id == productId);
    if (i != -1) list[i] = list[i].copyWith(available: available);
    _emit(cafeId);
  }
}

final cafeMenuRepositoryProvider = Provider<CafeMenuRepository>((ref) {
  if (AppConfig.dataFromFirestore) return FirestoreCafeMenuRepository();
  return InMemoryCafeMenuRepository();
});

/// Menú completo de una cafetería (para el panel de gestión).
final cafeMenuStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, cafeId) {
  return ref.watch(cafeMenuRepositoryProvider).watchMenu(cafeId);
});

/// Menú que ve el CLIENTE: solo productos disponibles.
final cafeClientMenuProvider =
    Provider.family<AsyncValue<List<Product>>, String>((ref, cafeId) {
  return ref.watch(cafeMenuStreamProvider(cafeId)).whenData(
        (products) => products.where((p) => p.available).toList(),
      );
});
