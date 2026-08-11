# Guía de activación — Firebase + Stripe (Fase 1)

Esta guía te lleva del **modo demo** (mock) al **backend real**. Los comandos
se ejecutan en tu máquina (aquí no hay Flutter SDK ni credenciales).

El interruptor está en `lib/core/config/app_config.dart`:

```dart
static const bool useMockBackend = true; // ← ponlo en false al terminar
```

---

## 1. Requisitos

```bash
# Flutter (3.4+), Node 20, y las CLIs:
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

Crea un proyecto en <https://console.firebase.google.com> (Auth, Firestore,
Functions). Necesitas plan **Blaze** para usar Cloud Functions (tiene capa
gratuita generosa).

---

## 2. Conectar la app a Firebase

Desde la raíz del proyecto:

```bash
flutter pub get
flutterfire configure   # genera lib/firebase_options.dart (reemplaza el placeholder)
```

Esto registra las apps Android/iOS y descarga `google-services.json` /
`GoogleService-Info.plist` (ignorados por git; son de tu proyecto).

---

## 3. Autenticación social

En **Firebase Console → Authentication → Sign-in method**, habilita:

- **Google** (listo casi de inmediato).
- **Apple** (obligatorio en iOS; requiere Apple Developer + Service ID).
- **Facebook** (crea una app en Meta for Developers y pega App ID / Secret).

Configuración por plataforma:
- **Android**: agrega la huella SHA-1/SHA-256 al proyecto Firebase.
- **iOS**: agrega el `CFBundleURLScheme` inverso del cliente OAuth, y para
  Apple activa la capability *Sign in with Apple* en Xcode.

---

## 4. Firestore: reglas, índices y datos

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Puebla el menú y los 12 casilleros (ver `scripts/seed.mjs`):

```bash
# Descarga la clave de servicio como scripts/serviceAccountKey.json
npm i firebase-admin
node scripts/seed.mjs
```

**Marcar a un empleado como staff** (para la estación de tienda). Las reglas y
funciones exigen el custom claim `staff`. Con la clave de servicio:

```js
await admin.auth().setCustomUserClaims(uid, {staff: true});
```

---

## 5. Stripe

1. Crea cuenta en <https://dashboard.stripe.com>.
2. Copia la **publishable key** a `AppConfig.stripePublishableKey`.
3. Crea un **producto/precio recurrente** (la membresía) y copia su `price_id`.
4. Guarda los secretos del servidor:

```bash
cd functions
npm install
firebase functions:secrets:set STRIPE_SECRET_KEY      # sk_live/sk_test...
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET  # (paso 6)
# El price de la suscripción (no secreto):
echo "STRIPE_SUBSCRIPTION_PRICE=price_XXXX" > .env
```

---

## 6. Desplegar funciones y webhook

```bash
firebase deploy --only functions
```

Toma la URL de `stripeWebhook` y regístrala en **Stripe → Developers →
Webhooks**, escuchando estos eventos:

- `payment_intent.succeeded`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`

Copia el *signing secret* (`whsec_...`) y guárdalo:

```bash
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase deploy --only functions   # re-deploy para tomar el secreto
```

---

## 7. Encender el backend real

```dart
// lib/core/config/app_config.dart
static const bool useMockBackend = false;
```

```bash
flutter run
```

Ahora los dos extremos comparten Firestore en vivo, los pagos pasan por Stripe
y el beneficio de socio se valida en el servidor.

---

## Funciones desplegadas

| Función | Quién la llama | Qué hace |
|---------|----------------|----------|
| `createPaymentIntent` | Cliente | Recalcula total, aplica beneficio, crea orden + PaymentIntent |
| `createSubscription` | Cliente | Inicia la membresía (Stripe Billing) |
| `stripeWebhook` | Stripe | Confirma pago → orden pagada; sincroniza estado de socio |
| `markOrderReady` | Empleado | Asigna casillero libre (transacción) y marca listo |
| `openLocker` | Cliente | Valida el pedido, abre casillero, marca recogido |
| `closeShift` | Empleado | Calcula totales del turno y lo cierra |

---

## Pendiente de hardware

`markOrderReady` y `openLocker` tienen un `TODO(hardware)` donde se envía el
comando físico al casillero. Ahí conectas el proveedor de smart lockers (API) o
tu electrónica propia (MQTT/HTTP) cuando lo definas. El resto del sistema ya
funciona alrededor de esos dos puntos.
