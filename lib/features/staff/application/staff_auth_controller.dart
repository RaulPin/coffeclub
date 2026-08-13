import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/firebase_staff_auth_repository.dart';
import '../data/staff_auth_repository.dart';
import '../domain/staff_user.dart';

final staffAuthRepositoryProvider = Provider<StaffAuthRepository>((ref) {
  if (AppConfig.useMockBackend) return MockStaffAuthRepository();
  return FirebaseStaffAuthRepository();
});

/// Sesión del personal (empleado o admin). null = no autenticado.
class StaffAuthController extends StateNotifier<StaffUser?> {
  StaffAuthController(this._repository) : super(_repository.currentUser);

  final StaffAuthRepository _repository;

  Future<StaffUser> signIn(String email, String password) async {
    final user = await _repository.signIn(email, password);
    state = user;
    return user;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = null;
  }
}

final staffAuthControllerProvider =
    StateNotifierProvider<StaffAuthController, StaffUser?>((ref) {
  return StaffAuthController(ref.watch(staffAuthRepositoryProvider));
});
