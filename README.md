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

## 🔌 Pasar a producción (Firebase + Stripe)

La integración real **ya está implementada** detrás del flag
`AppConfig.useMockBackend`. Para activarla sigue la guía paso a paso:
**[`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)**.

En resumen:
1. `flutterfire configure` (genera `lib/firebase_options.dart`).
2. Habilita Auth social, despliega reglas de Firestore y puebla datos
   (`scripts/seed.mjs`).
3. Configura Stripe (claves + price de la membresía) y despliega las Cloud
   Functions (`functions/`).
4. Pon `AppConfig.useMockBackend = false` y `flutter run`.

**Backend** (carpeta `functions/`): pagos, webhook de Stripe, asignación/apertura
de casilleros y cierre de caja. Reglas de seguridad en `firestore.rules`.

**Lockers**: implementa el `TODO(hardware)` en `markOrderReady`/`openLocker`
según el hardware que elijas (interfaz `LockerService` en el cliente).

---

## 📄 Licencia

Privado — The Club Coffe.
