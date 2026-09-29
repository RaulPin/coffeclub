import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/branch.dart';

/// Fuente de datos de sucursales.
abstract interface class BranchRepository {
  Future<List<Branch>> fetchBranches();
}

class MockBranchRepository implements BranchRepository {
  @override
  Future<List<Branch>> fetchBranches() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      Branch(
        id: 'condesa',
        name: 'Barra Condesa',
        address: 'Av. Michoacán 100, Condesa',
        tagline: 'Café de especialidad · tostado propio',
        etaMinutes: 4,
        rating: 4.9,
        imageUrl:
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600&h=400&fit=crop',
      ),
      Branch(
        id: 'roma',
        name: 'Barra Roma Norte',
        address: 'Álvaro Obregón 50, Roma Nte.',
        tagline: 'Brunch y métodos de filtrado',
        etaMinutes: 6,
        rating: 4.7,
        imageUrl:
            'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=600&h=400&fit=crop',
      ),
      Branch(
        id: 'polanco',
        name: 'Barra Polanco',
        address: 'Emilio Castelar 20, Polanco',
        tagline: 'Espresso bar & pastelería',
        etaMinutes: 5,
        rating: 4.8,
        imageUrl:
            'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=600&h=400&fit=crop',
      ),
    ];
  }
}

class FirestoreBranchRepository implements BranchRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<Branch>> fetchBranches() async {
    final snap = await _db.collection('branches').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return Branch(
        id: doc.id,
        name: data['name'] as String? ?? '',
        address: data['address'] as String? ?? '',
        lockerCount: (data['lockerCount'] as num?)?.toInt() ?? 12,
      );
    }).toList();
  }
}

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  if (AppConfig.useMockBackend) return MockBranchRepository();
  return FirestoreBranchRepository();
});

final branchesProvider = FutureProvider<List<Branch>>((ref) {
  return ref.watch(branchRepositoryProvider).fetchBranches();
});

/// Sucursal elegida por el cliente para recoger su pedido.
/// Si es null, se usa la primera disponible.
final selectedBranchIdProvider = StateProvider<String?>((ref) => null);
