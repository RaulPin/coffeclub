import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// Formatea centavos de MXN como moneda: 100 -> "$1.00".
String formatCents(int cents) => _formatter.format(cents / 100);

final _pesos = NumberFormat.decimalPattern('es_MX');

/// Formato compacto estilo menú: 13000 -> "$130 MXN" (sin centavos cuando es
/// una cantidad entera; con centavos solo si los hay).
String formatMxn(int cents) {
  final pesos = cents / 100;
  final isWhole = cents % 100 == 0;
  final number =
      isWhole ? _pesos.format(pesos.round()) : _pesos.format(pesos);
  return '\$$number MXN';
}
