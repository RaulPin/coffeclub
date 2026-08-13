import '../domain/staff_user.dart';

/// Autenticación del personal por usuario (correo) y contraseña.
abstract interface class StaffAuthRepository {
  StaffUser? get currentUser;
  Future<StaffUser> signIn(String email, String password);
  Future<void> signOut();
}

/// Implementación de demo con cuentas de ejemplo.
///
/// Cuentas para probar:
///   - condesa@theclubcoffe.mx / 1234   → empleado (sucursal Condesa)
///   - roma@theclubcoffe.mx    / 1234   → empleado (sucursal Roma Norte)
///   - admin@theclubcoffe.mx   / admin  → administrador general
class MockStaffAuthRepository implements StaffAuthRepository {
  static final Map<String, ({String password, StaffUser user})> _accounts = {
    'condesa@theclubcoffe.mx': (
      password: '1234',
      user: StaffUser(
        id: 'emp_condesa',
        name: 'Empleado Condesa',
        email: 'condesa@theclubcoffe.mx',
        role: StaffRole.employee,
        branchId: 'condesa',
      ),
    ),
    'roma@theclubcoffe.mx': (
      password: '1234',
      user: StaffUser(
        id: 'emp_roma',
        name: 'Empleado Roma',
        email: 'roma@theclubcoffe.mx',
        role: StaffRole.employee,
        branchId: 'roma',
      ),
    ),
    'admin@theclubcoffe.mx': (
      password: 'admin',
      user: StaffUser(
        id: 'admin_general',
        name: 'Administrador General',
        email: 'admin@theclubcoffe.mx',
        role: StaffRole.admin,
      ),
    ),
  };

  StaffUser? _current;

  @override
  StaffUser? get currentUser => _current;

  @override
  Future<StaffUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw Exception('Usuario o contraseña incorrectos');
    }
    _current = account.user;
    return account.user;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }
}
