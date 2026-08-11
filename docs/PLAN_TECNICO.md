# Plan Técnico — The Club Coffe

Documento de arquitectura y roadmap para llevar la app de café con recogida en
casilleros de MVP a producción.

---

## 1. Visión del producto

App móvil (iOS + Android) donde un **socio**:

1. Inicia sesión / crea cuenta con Google, Apple o Facebook.
2. Compra una **suscripción** (1 café al día por $1).
3. Ve el **menú** y arma un pedido.
4. **Paga** con tarjeta (Stripe).
5. Recibe un **contador** del tiempo de preparación y el **número de casillero**.
6. Recoge su pedido abriendo el **casillero** desde la app.

---

## 2. Stack tecnológico

| Capa | Tecnología | Motivo |
|------|-----------|--------|
| App móvil | **Flutter** | Un código para iOS + Android |
| Estado | **Riverpod** | Escalable, testeable, sin boilerplate |
| Navegación | **go_router** | Rutas declarativas + deep links |
| Auth | **Firebase Auth** | Login social listo (Google/Apple/FB) |
| Base de datos | **Cloud Firestore** | Tiempo real (ideal para estado de pedidos) |
| Lógica de servidor | **Cloud Functions** | Pagos, asignación de lockers, webhooks |
| Notificaciones | **Firebase Cloud Messaging** | Aviso "pedido listo" |
| Pagos | **Stripe** (Billing + Payment Intents) | Suscripciones + pagos únicos |
| Casilleros | **Interfaz `LockerService`** | Agnóstica del hardware (por definir) |

> **Por qué Firebase**: para un equipo pequeño elimina el costo de montar y
> mantener servidores. El tiempo real de Firestore encaja perfecto con el
> estado del pedido y el contador. Alternativa válida: Supabase (Postgres).

---

## 3. Arquitectura de la app (ya implementada en el scaffold)

Feature-first, con cada feature dividida en capas:

- `domain/` — modelos puros (sin dependencias de framework).
- `data/` — repositorios/servicios (interfaz + implementación mock/real).
- `application/` — controladores de estado (Riverpod).
- `presentation/` — pantallas y widgets.

**Regla clave**: la UI nunca habla directo con Firebase/Stripe/hardware, solo
con interfaces (`AuthRepository`, `PaymentService`, `LockerService`,
`MenuRepository`). Cambiar de mock a producción = cambiar una línea en el
`Provider`.

---

## 4. Modelo de datos (Firestore)

```
users/{userId}
  ├─ name, email, photoUrl
  ├─ isSubscriber: bool
  ├─ stripeCustomerId: string
  └─ subscriptionStatus: active | canceled | past_due

products/{productId}
  ├─ name, description, category
  ├─ priceCents: int
  └─ available: bool

orders/{orderId}
  ├─ userId
  ├─ items: [{ productId, name, priceCents, quantity }]
  ├─ totalCents: int
  ├─ status: pending | preparing | ready | pickedUp
  ├─ paymentRef: string (Stripe PaymentIntent)
  ├─ lockerNumber: int | null
  ├─ createdAt, estimatedReadyAt: timestamp

lockers/{lockerNumber}
  ├─ status: free | reserved | occupied
  └─ currentOrderId: string | null

shifts/{shiftId}
  ├─ employeeName: string
  ├─ startedAt: timestamp
  ├─ endedAt: timestamp | null   (null = turno abierto)
  ├─ ordersCount: int            (se calcula al cerrar)
  └─ totalSalesCents: int        (cierre de caja)
```

La app **escucha** `orders/{orderId}` en tiempo real: cuando el backend cambia
`status` a `ready` y asigna `lockerNumber`, la UI se actualiza sola.

---

## 5. Flujos críticos

### 5.1 Pago seguro (Stripe)
Nunca calcular montos ni usar la secret key en el cliente:
1. App → Cloud Function `createPaymentIntent(orderId)`.
2. La función recalcula el total en el servidor y crea el `PaymentIntent`.
3. Devuelve `clientSecret` → app confirma con **Stripe Payment Sheet**.
4. **Webhook** de Stripe → Cloud Function marca la orden como pagada. **Esta es
   la fuente de verdad**, no la respuesta del cliente.

### 5.2 Suscripción y beneficio de socio
- Stripe **Billing** con un producto/precio recurrente.
- Webhook `customer.subscription.updated` → actualiza `isSubscriber`.

**Regla de negocio del menú**: el menú es **café + pizza**. El beneficio de
socio es **1 café Americano al día por $1** (solo el Americano; ninguna otra
bebida ni un segundo Americano el mismo día). Esto implica una lógica de
*entitlement*:
- El socio tiene derecho a **1 Americano a $1 por día**.
- El segundo Americano del día, y todo lo demás (pizzas, postre, otras
  bebidas), se cobra a precio normal.
- Este beneficio debe validarse **en el servidor** (Cloud Function) leyendo los
  pedidos del día del usuario, no en el cliente. Guardar `lastPerkDate` en
  `users/{uid}` o contar pedidos con perk en `orders/` evita el abuso.

En el scaffold: el producto elegible se marca con `Product.eligibleForDailyPerk`
(hoy solo el Americano) y `cartPricingProvider` aplica el precio de socio a una
unidad si el beneficio está disponible ese día.

### 5.3 Asignación y apertura de casillero
1. Orden pagada → Cloud Function busca un `locker` libre y lo reserva
   (transacción para evitar doble asignación).
2. Cuando el café está listo → `status = ready`, se notifica por FCM.
3. El socio toca "Abrir casillero" → Cloud Function ordena al hardware abrir.
   **La app nunca habla directo con el hardware** (credenciales solo en servidor).

---

## 5.4 App de empleado (estación de tienda)

El sistema tiene **dos extremos sobre el mismo backend**:

- **App cliente** (móvil): crea la orden y sigue su estado.
- **App empleado** (tablet en tienda): recibe las órdenes en tiempo real, las
  prepara y las coloca en un casillero.

No hay envío directo entre apps: la app cliente **escribe** en `orders/` y la
app empleado **escucha** esa colección (`snapshots()` de Firestore). Cualquier
cambio se propaga solo a ambos lados.

**Recomendación**: un solo proyecto Flutter con dos experiencias por rol. La app
de empleado corre en una tablet dedicada. Reutiliza modelos, tema y backend.

### Ciclo de vida de un pedido (dos extremos)

```
[Cliente] paga        → orders/{id}.status = pending          (en cola)
[Empleado] toma       → status = preparing
[Empleado] termina    → status = ready + lockerNumber asignado
[Cliente] recoge      → abre casillero → status = pickedUp
```

### Turnos y cierre de caja

- El empleado **inicia turno** (login) → se crea `shifts/{id}` abierto.
- Trabaja sobre la cola de pedidos.
- Al terminar, **cierre de caja**: se calculan órdenes y ventas del turno
  (fuente de verdad: `orders/` en la ventana del turno, no un contador manual),
  se cierra `shifts/{id}` y se muestran los casilleros aún ocupados para el
  relevo.
- El **siguiente empleado inicia sesión** y abre un turno nuevo; el estado de
  pedidos y casilleros es compartido, así que continúa sin perder contexto.

> En producción, el paso `preparing → ready` puede ser manual (el empleado lo
> marca) o disparar la apertura/asignación del casillero vía Cloud Function.
> Los totales del cierre deben calcularse en el servidor para evitar
> manipulación desde el cliente.

---

## 6. Integración de casilleros (pendiente de definir hardware)

Diseñamos la app agnóstica con la interfaz `LockerService`. Opciones:

| Opción | Cómo se integra | Trade-off |
|--------|-----------------|-----------|
| **Proveedor con API** (smart lockers) | HTTP a la API del proveedor desde Cloud Function | Rápido, pero costo por unidad y dependes del proveedor |
| **Hardware propio (IoT)** | ESP32/Raspberry con cerradura eléctrica; comunicación por **MQTT** o HTTP a un endpoint que dispara la apertura | Más barato a escala, pero requiere firmware, seguridad IoT y mantenimiento |

Recomendación para arrancar: validar el negocio con **1 sucursal** y el hardware
más simple que abra un casillero por comando; la interfaz ya permite cambiarlo
después sin reescribir la app.

---

## 7. Roadmap por fases

### Fase 0 — Scaffold (✅ hecho)
UI navegable end-to-end con datos mock, **de los dos lados**:
- Cliente: login → menú → carrito → pago → contador + casillero.
- Empleado: inicio de turno → cola de pedidos → preparar → asignar casillero →
  cierre de caja y relevo de turno.
Ambos comparten un store de órdenes en memoria (simula Firestore). Corre sin
backend.

### Fase 1 — MVP funcional (2–4 semanas)
- [ ] Proyecto Firebase + `flutterfire configure`.
- [ ] Firebase Auth real (Google, Apple, Facebook).
- [ ] Menú desde Firestore.
- [ ] Pago único con Stripe + Cloud Function + webhook.
- [ ] Órdenes en Firestore con estado en tiempo real.
- [ ] Contador real basado en `estimatedReadyAt`.

### Fase 2 — Suscripción, casilleros y operación (2–3 semanas)
- [ ] Suscripción de socio con Stripe Billing.
- [ ] Asignación de casillero (transacción Firestore).
- [ ] Integración real del hardware de lockers.
- [ ] Notificaciones push (FCM) "pedido listo".
- [ ] App de empleado sobre Firestore en tiempo real (cola de pedidos).
- [ ] Turnos y cierre de caja calculados en el servidor (Cloud Function).

### Fase 3 — Producción (2–3 semanas)
- [ ] Panel/rol para el staff (marcar pedidos listos) o automatización.
- [ ] Reglas de seguridad de Firestore.
- [ ] Manejo de errores, reintentos, reembolsos.
- [ ] Analítica (Firebase Analytics) y crash reporting (Crashlytics).
- [ ] Publicación en App Store y Google Play.

---

## 8. Seguridad (imprescindible)

- **Firestore Security Rules**: cada usuario solo lee/escribe sus propios datos;
  `orders` y `lockers` solo se modifican desde Cloud Functions.
- **Montos siempre en el servidor** (nunca confiar en el cliente).
- **Webhooks de Stripe** verificados con firma.
- **Credenciales del hardware** solo en el backend, nunca en la app.
- **Apple Sign In** es obligatorio en iOS si ofreces otro login social.

---

## 9. Costos aproximados (arranque)

- Firebase: plan Spark gratis para empezar; Blaze (pago por uso) es barato a
  bajo volumen.
- Stripe: ~3.6% + comisión por transacción (México), sin costo fijo.
- Apple Developer: $99 USD/año. Google Play: $25 USD una sola vez.
- Hardware de casilleros: variable (principal inversión).

---

## 10. Siguientes pasos sugeridos

1. Correr el scaffold (`flutter run`) y validar el flujo/UX.
2. Crear el proyecto de Firebase y conectar Auth real (Fase 1).
3. Definir el proveedor/hardware de casilleros para cerrar la integración.
