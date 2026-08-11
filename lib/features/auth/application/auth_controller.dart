import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Provee la implementación de `AuthRepository`.
/// Cambia aquí a `FirebaseAuthRepository()` cuando integres Firebase.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Estado de la sesión: null = no autenticado.
class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._repository) : super(_repository.currentUser);

  final AuthRepository _repository;

  bool _loading = false;
  bool get isLoading => _loading;

  Future<void> signIn(SocialProvider provider) async {
    _loading = true;
    state = await _repository.signInWith(provider);
    _loading = false;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = null;
  }

  /// Marca al usuario como socio tras comprar la suscripción.
  void markAsSubscriber() {
    final user = state;
    if (user != null) state = user.copyWith(isSubscriber: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
