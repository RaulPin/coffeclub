import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';

/// Provee la implementación de `AuthRepository` según el modo.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockBackend) return MockAuthRepository();
  return FirebaseAuthRepository();
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
