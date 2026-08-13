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
        name: 'Condesa',
        address: 'Av. Michoacán 100, Condesa',
      ),
      Branch(
        id: 'roma',
        name: 'Roma Norte',
        address: 'Álvaro Obregón 50, Roma Nte.',
      ),
      Branch(
        id: 'polanco',
        name: 'Polanco',
        address: 'Emilio Castelar 20, Polanco',
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
