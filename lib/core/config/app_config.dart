/// Configuración global de la app.
///
/// `useMockBackend = true` permite correr la app SIN Firebase ni Stripe,
/// usando datos de ejemplo (ideal para desarrollar la UI). Cámbialo a `false`
/// cuando hayas configurado Firebase (`flutterfire configure`) y Stripe.
class AppConfig {
  const AppConfig._();

  /// Mientras esté en `true`, la app funciona en modo demo con datos mock.
  static const bool useMockBackend = true;

  /// Nombre comercial.
  static const String appName = 'The Club Coffe';

  /// Precio del café para socios (en centavos de MXN).
  static const int socioCoffeePriceCents = 100; // $1.00

  // --- Stripe (rellenar al integrar pagos) ---
  static const String stripePublishableKey = 'pk_test_TODO';

  // --- Casilleros / lockers ---
  /// Cantidad de casilleros disponibles en la sucursal (ver imagen: 12 cajas).
  static const int lockerCount = 12;
}
