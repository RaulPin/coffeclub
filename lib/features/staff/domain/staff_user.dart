/// Roles del back-office.
enum StaffRole {
  /// Empleado de una sucursal (atiende pedidos de su sucursal).
  employee,

  /// Administrador general (ve todas las sucursales).
  admin,
}

/// Usuario del personal (empleado o administrador).
class StaffUser {
  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.branchId,
    this.isOwner = false,
  });

  final String id;
  final String name;
  final String email;
  final StaffRole role;

  /// Sucursal asignada. `null` para el administrador general.
  final String? branchId;

  /// `true` si es el dueño de la cafetería (puede editar el café, el menú y
  /// gestionar empleados). Los baristas tienen `false`.
  final bool isOwner;

  bool get isAdmin => role == StaffRole.admin;

  /// Puede administrar la cafetería (datos, menú, empleados).
  bool get canManageCafe => isAdmin || isOwner;
}
