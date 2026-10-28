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

  /// Cobrar de verdad con Mercado Pago a través del backend (Cloud Functions).
  /// Déjalo en `false` hasta DESPLEGAR las funciones; mientras tanto el checkout
  /// simula el pago para poder probar la app completa.
  static const bool useMercadoPagoBackend = false;

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

  // --- Modelo de negocio (parámetros ajustables) ---

  /// Comisión que Barra cobra a la cafetería por pedido (sobre el subtotal
  /// de productos). 0.08 = 8%.
  static const double platformCommissionRate = 0.08;

  /// Cuota de servicio fija que paga un cliente NO socio por pedido (centavos).
  static const int serviceFeeCents = 1000; // $10.00

  /// Cuota de servicio para socios Barra+ (reducida, no $0). Cubre el costo
  /// fijo de procesamiento de pago para que cada pedido de socio no pierda.
  static const int memberServiceFeeCents = 500; // $5.00

  /// Precio de la membresía "Barra+" (centavos de MXN / mes).
  /// Beneficio: cuota de servicio reducida en todos los pedidos.
  static const int membershipMonthlyCents = 2900; // $29.00

  // --- Costo de procesamiento de pago (Mercado Pago) ---
  // Para modelar el margen real de Barra. Mercado Pago cobra un porcentaje
  // por transacción MÁS un cargo fijo por operación.

  /// Porcentaje que cobra Mercado Pago sobre el monto cobrado. 0.0349 = 3.49%.
  static const double paymentPercentRate = 0.0349;

  /// Cargo fijo por transacción de Mercado Pago (centavos de MXN).
  static const int paymentFixedFeeCents = 400; // $4.00

  /// Costo estimado de procesar un cobro de [amountCents] con Mercado Pago.
  static int paymentProcessingCost(int amountCents) =>
      (amountCents * paymentPercentRate).round() + paymentFixedFeeCents;

  // --- Stripe (rellenar al integrar pagos) ---
  static const String stripePublishableKey = 'pk_test_TODO';
}
