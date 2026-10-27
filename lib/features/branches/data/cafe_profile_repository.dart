import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/branch.dart';

/// Lectura y edición de la ficha de una cafetería (para su dueño).
abstract interface class CafeProfileRepository {
  Future<Branch?> fetch(String cafeId);
  Future<void> update(
    String cafeId, {
    required String name,
    required String address,
    required String tagline,
    String? imageUrl,
    int? etaMinutes,
    double? lat,
    double? lng,
  });
}

class FirestoreCafeProfileRepository implements CafeProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _db.collection('cafes').doc(id);

  @override
  Future<Branch?> fetch(String cafeId) async {
    final snap = await _doc(cafeId).get();
    final data = snap.data();
    if (data == null) return null;
    return Branch(
      id: snap.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      etaMinutes: (data['etaMinutes'] as num?)?.toInt() ?? 5,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> update(
    String cafeId, {
    required String name,
    required String address,
    required String tagline,
    String? imageUrl,
    int? etaMinutes,
    double? lat,
    double? lng,
  }) async {
    await _doc(cafeId).set({
      'name': name.trim(),
      'address': address.trim(),
      'tagline': tagline.trim(),
      'imageUrl': (imageUrl == null || imageUrl.trim().isEmpty)
          ? null
          : imageUrl.trim(),
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
      'lat': lat,
      'lng': lng,
    }, SetOptions(merge: true));
  }
}

/// Implementación de demo (no persiste).
class MockCafeProfileRepository implements CafeProfileRepository {
  @override
  Future<Branch?> fetch(String cafeId) async => const Branch(
        id: 'demo_cafe',
        name: 'Mi Cafetería',
        address: 'Dirección demo',
        tagline: '',
      );

  @override
  Future<void> update(
    String cafeId, {
    required String name,
    required String address,
    required String tagline,
    String? imageUrl,
    int? etaMinutes,
    double? lat,
    double? lng,
  }) async {}
}

final cafeProfileRepositoryProvider = Provider<CafeProfileRepository>((ref) {
  if (AppConfig.dataFromFirestore) return FirestoreCafeProfileRepository();
  return MockCafeProfileRepository();
});

/// Carga la ficha de una cafetería por id (para la pantalla de edición).
final cafeProfileProvider =
    FutureProvider.family<Branch?, String>((ref, cafeId) {
  return ref.watch(cafeProfileRepositoryProvider).fetch(cafeId);
});
