import '../domain/app_user.dart';

/// Métodos de inicio de sesión social soportados.
enum SocialProvider { google, apple, facebook }

/// Contrato de autenticación. La app usa esta interfaz; la implementación
/// concreta (mock o Firebase) se inyecta vía Riverpod en `auth_controller.dart`.
abstract interface class AuthRepository {
  /// Usuario actual (null si no hay sesión).
  AppUser? get currentUser;

  /// Inicia sesión con un proveedor social.
  Future<AppUser> signInWith(SocialProvider provider);

  /// Cierra la sesión.
  Future<void> signOut();
}

/// Implementación de ejemplo para desarrollo sin backend.
class MockAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWith(SocialProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _user = AppUser(
      id: 'demo-user',
      name: 'Socio Demo',
      email: 'socio@theclubcoffe.mx',
      isSubscriber: false,
    );
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}
