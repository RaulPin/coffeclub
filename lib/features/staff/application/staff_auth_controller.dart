import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/firebase_staff_auth_repository.dart';
import '../data/staff_auth_repository.dart';
import '../domain/staff_user.dart';

final staffAuthRepositoryProvider = Provider<StaffAuthRepository>((ref) {
  if (AppConfig.useFirebaseStaffAuth) return FirebaseStaffAuthRepository();
  return MockStaffAuthRepository();
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

  Future<StaffUser> signInWithGoogle() async {
    final user = await _repository.signInWithGoogle();
    state = user;
    return user;
  }

  /// Fija la sesión tras registrar una cafetería (ya quedó autenticada).
  void applySession(StaffUser user) => state = user;

  Future<void> signOut() async {
    await _repository.signOut();
    state = null;
  }
}

final staffAuthControllerProvider =
    StateNotifierProvider<StaffAuthController, StaffUser?>((ref) {
  return StaffAuthController(ref.watch(staffAuthRepositoryProvider));
});
