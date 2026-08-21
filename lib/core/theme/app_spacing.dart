/// Escala de espaciado (grid de 8) y radios de esquina del diseño.
///
/// Usar estas constantes en vez de números sueltos mantiene el ritmo visual
/// consistente en toda la app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Padding horizontal estándar de pantalla.
  static const double screen = 16;
}

/// Radios de esquina.
abstract final class AppRadius {
  /// Chips / píldoras muy redondeadas.
  static const double pill = 999;

  /// Botones y campos.
  static const double button = 12;

  /// Cards y superficies.
  static const double card = 16;

  /// Superficies grandes (tarjeta de membresía, modales).
  static const double sheet = 24;

  /// Alto del botón primario.
  static const double buttonHeight = 52;
}
