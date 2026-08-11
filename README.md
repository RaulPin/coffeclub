# The Club Coffe ☕

App móvil (iOS + Android) de membresía de café con pedidos y recogida en
casilleros (lockers), construida en **Flutter**.

Un socio puede: iniciar sesión con redes sociales → suscribirse → ver el menú →
ordenar → pagar → seguir un contador del tiempo de preparación → recoger su
pedido en el casillero asignado.

---

## 🚀 Cómo correrlo (modo demo, sin backend)

El proyecto arranca **sin necesidad de Firebase ni Stripe** gracias a datos de
ejemplo (`AppConfig.useMockBackend = true`). Ideal para desarrollar la UI.

```bash
flutter pub get
flutter run
```

> Requiere el [SDK de Flutter](https://docs.flutter.dev/get-started/install)
> (3.4 o superior). Este entorno no lo tiene instalado; corre estos comandos en
> tu máquina.

Flujo demo: Login (cualquier botón) → Menú → agrega productos → carrito →
pagar → verás el contador y el número de casillero → "Abrir casillero".

---

## 🏗️ Arquitectura

Organización **feature-first** con **Riverpod** (estado) y **go_router**
(navegación):

```
lib/
├── main.dart                 # arranque
├── app.dart                  # MaterialApp.router
├── core/                     # config, tema, router, utils
├── features/
│   ├── auth/                 # login social
│   ├── subscription/         # membresía de socio
│   ├── menu/                 # menú de productos
│   ├── cart/                 # carrito
│   ├── checkout/             # pago (Stripe)
│   └── orders/               # pedido + contador + casillero
└── services/
    └── lockers/              # interfaz agnóstica del hardware de casilleros
```

Cada feature separa `domain/` (modelos), `data/` (repositorios/servicios),
`application/` (controladores Riverpod) y `presentation/` (pantallas).

**Todo el backend está detrás de interfaces** (`AuthRepository`,
`PaymentService`, `LockerService`, `MenuRepository`). Hoy usan implementaciones
mock; para pasar a producción solo se cambia la implementación en el `Provider`
correspondiente, sin tocar la UI.

---

## 🔌 Pasar a producción

Ver el plan completo en [`docs/PLAN_TECNICO.md`](docs/PLAN_TECNICO.md). En resumen:

1. **Firebase**: `flutterfire configure`, descomenta las dependencias en
   `pubspec.yaml`, implementa `FirebaseAuthRepository` y pon
   `AppConfig.useMockBackend = false`.
2. **Stripe**: implementa `PaymentService` real con `flutter_stripe` +
   Cloud Functions (el `PaymentIntent` se crea en el servidor).
3. **Lockers**: implementa `LockerService` según el hardware que elijas.

---

## 📄 Licencia

Privado — The Club Coffe.
