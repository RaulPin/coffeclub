import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/product.dart';
import 'menu_repository.dart';

/// Lee el menú de la colección `products/` de Firestore.
class FirestoreMenuRepository implements MenuRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<Product>> fetchMenu() async {
    final snap = await _db
        .collection('products')
        .where('available', isEqualTo: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return Product(
        id: doc.id,
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        priceCents: (data['priceCents'] as num?)?.toInt() ?? 0,
        category: data['category'] as String? ?? 'Otros',
        imageUrl: data['imageUrl'] as String?,
        eligibleForDailyPerk:
            (data['eligibleForDailyPerk'] as bool?) ?? false,
      );
    }).toList();
  }
}
