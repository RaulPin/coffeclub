import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fecha (día) en que el socio canjeó por última vez su beneficio diario
/// (1 Americano por $1). `null` = nunca.
///
/// ⚠️ En producción, la fuente de verdad es el SERVIDOR: una Cloud Function
/// valida contra `orders/` del día del usuario antes de aplicar el precio de
/// socio. Este estado en cliente es solo para el demo/UX.
final lastPerkRedemptionProvider = StateProvider<DateTime?>((ref) => null);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// `true` si el socio aún no ha usado su beneficio del Americano hoy.
final perkAvailableTodayProvider = Provider<bool>((ref) {
  final last = ref.watch(lastPerkRedemptionProvider);
  if (last == null) return true;
  return !_isSameDay(last, DateTime.now());
});
