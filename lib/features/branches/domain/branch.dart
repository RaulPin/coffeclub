/// Sucursal de The Club Coffe.
class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    this.lockerCount = 12,
  });

  final String id;
  final String name;
  final String address;

  /// Cantidad de casilleros de la sucursal.
  final int lockerCount;
}
