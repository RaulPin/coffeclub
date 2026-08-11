import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// Formatea centavos de MXN como moneda: 100 -> "$1.00".
String formatCents(int cents) => _formatter.format(cents / 100);
