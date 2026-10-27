/// Configuración global de la app.
///
/// `useMockBackend = true` permite correr la app SIN Firebase ni Stripe,
/// usando datos de ejemplo (ideal para desarrollar la UI). Cámbialo a `false`
/// cuando hayas configurado Firebase (`flutterfire configure`) y Stripe.
class AppConfig {
  const AppConfig._();

  /// Mientras esté en `true`, la app funciona en modo demo con datos mock.
  static const bool useMockBackend = true;

  /// Usar Firestore para los DATOS (cafés, menús, pedidos) aunque el login y
  /// los pagos sigan en modo demo. Permite migrar a la base real por partes.
  static const bool useFirestoreData = true;

  /// Usar Firebase Auth real (correo/contraseña) para los clientes.
  static const bool useFirebaseAuth = true;

  /// Usar Firebase Auth real para el personal/cafeterías (estación de tienda).
  /// Con esto, las cafeterías se registran solas y entran con su cuenta real.
  static const bool useFirebaseStaffAuth = true;

  /// `true` si los datos deben leerse/escribirse en Firestore.
  static bool get dataFromFirestore => !useMockBackend || useFirestoreData;

  /// `true` si se requiere inicializar Firebase (datos o auth reales).
  static bool get usesFirebase =>
      dataFromFirestore ||
      useFirebaseAuth ||
      useFirebaseStaffAuth ||
      !useMockBackend;

  /// Nombre comercial.
  static const String appName = 'Barra';

  /// Correos que entran como ADMINISTRADOR general (ven todas las cafeterías y
  /// sus ventas). Edita esta lista con los correos de tu equipo de dirección.
  /// Quien inicie sesión en la estación con uno de estos correos obtiene el
  /// panel de administración, sin necesidad de configurar nada en Firebase.
  static const List<String> adminEmails = <String>[
    'raulpineda.0197@gmail.com',
  ];

  /// `true` si el correo pertenece a un administrador general.
  static bool isAdminEmail(String email) => adminEmails
      .map((e) => e.toLowerCase())
      .contains(email.trim().toLowerCase());

  // --- Modelo de negocio ---

  /// Comisión que Barra cobra a la cafetería por pedido (sobre el subtotal
  /// de productos). 0.05 = 5%.
  static const double platformCommissionRate = 0.05;

  /// Cuota de servicio fija que paga el cliente por pedido (centavos de MXN).
  static const int serviceFeeCents = 1000; // $10.00

  /// Precio de la membresía "Barra+" (centavos de MXN / mes).
  /// Beneficio: se elimina la cuota de servicio en todos los pedidos.
  static const int membershipMonthlyCents = 2900; // $29.00

  // --- Stripe (rellenar al integrar pagos) ---
  static const String stripePublishableKey = 'pk_test_TODO';
}
