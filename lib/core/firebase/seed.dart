import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/branches/data/branch_repository.dart';
import '../../features/menu/data/demo_menu.dart';

/// Siembra Firestore con las cafeterías demo y el menú de cada una, SOLO si la
/// colección `cafes/` está vacía. Pensado para arrancar la base en desarrollo.
///
/// Estructura:
///   cafes/{cafeId}                     → datos de la cafetería
///   cafes/{cafeId}/products/{prodId}   → menú de esa cafetería
Future<void> seedFirestoreIfEmpty() async {
  final db = FirebaseFirestore.instance;
  final cafes = db.collection('cafes');

  final existing = await cafes.limit(1).get();
  if (existing.docs.isNotEmpty) return; // ya sembrado

  final batch = db.batch();
  for (final cafe in kDemoBranches) {
    batch.set(cafes.doc(cafe.id), {
      'name': cafe.name,
      'address': cafe.address,
      'tagline': cafe.tagline,
      'imageUrl': cafe.imageUrl,
      'etaMinutes': cafe.etaMinutes,
      'rating': cafe.rating,
    });
    for (final p in kDemoMenu) {
      batch.set(cafes.doc(cafe.id).collection('products').doc(p.id), {
        'name': p.name,
        'description': p.description,
        'priceCents': p.priceCents,
        'category': p.category,
        'imageUrl': p.imageUrl,
        'available': p.available,
      });
    }
  }
  await batch.commit();
}
