/**
 * Cloud Functions de The Club Coffe.
 *
 * Responsabilidades del servidor (fuente de verdad):
 *  - Recalcular montos y validar el beneficio de socio (1 Americano/día).
 *  - Crear PaymentIntents y suscripciones de Stripe (secret key solo aquí).
 *  - Confirmar pagos vía webhook y registrar la orden como pagada.
 *  - Asignar/abrir casilleros de forma transaccional (sin exponer hardware).
 *  - Cerrar turnos (cierre de caja) calculando totales.
 */
import {onCall, onRequest, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {defineSecret, defineString} from "firebase-functions/params";
import * as admin from "firebase-admin";
import Stripe from "stripe";

admin.initializeApp();

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
const subscriptionPrice = defineString("STRIPE_SUBSCRIPTION_PRICE");

/** Precio del Americano para socios: $1.00. */
const SOCIO_PRICE_CENTS = 100;

function getStripe(): Stripe {
  return new Stripe(stripeSecret.value());
}

/** Fecha "hoy" en zona horaria de Ciudad de México (YYYY-MM-DD). */
function todayStr(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Mexico_City",
  }).format(new Date());
}

function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Inicia sesión.");
  return uid;
}

function requireStaff(request: CallableRequest): void {
  if (request.auth?.token?.staff !== true) {
    throw new HttpsError("permission-denied", "Acción solo para personal.");
  }
}

async function ensureCustomer(
  uid: string,
  user: FirebaseFirestore.DocumentData,
  stripe: Stripe
): Promise<string> {
  if (typeof user.stripeCustomerId === "string") return user.stripeCustomerId;
  const customer = await stripe.customers.create({
    email: user.email,
    metadata: {uid},
  });
  await admin.firestore().collection("users").doc(uid).set(
    {stripeCustomerId: customer.id},
    {merge: true}
  );
  return customer.id;
}

async function uidFromCustomer(
  customerId: string,
  db: FirebaseFirestore.Firestore
): Promise<string | null> {
  const snap = await db
    .collection("users")
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();
  return snap.empty ? null : snap.docs[0].id;
}

/**
 * [CLIENTE] Crea la orden y el PaymentIntent. El servidor recalcula el total
 * desde `products/` y aplica el beneficio de socio si corresponde.
 */
export const createPaymentIntent = onCall(
  {secrets: [stripeSecret]},
  async (request) => {
    const uid = requireAuth(request);
    const items = request.data?.items as
      | {productId: string; quantity: number}[]
      | undefined;
    if (!items || items.length === 0) {
      throw new HttpsError("invalid-argument", "El carrito está vacío.");
    }

    const db = admin.firestore();

    let subtotal = 0;
    const orderItems: FirebaseFirestore.DocumentData[] = [];
    let eligiblePriceCents: number | null = null;

    for (const it of items) {
      const snap = await db.collection("products").doc(it.productId).get();
      if (!snap.exists) {
        throw new HttpsError("not-found", `Producto ${it.productId} no existe.`);
      }
      const p = snap.data()!;
      const qty = Math.max(1, Math.floor(it.quantity || 1));
      const priceCents = Number(p.priceCents) || 0;
      subtotal += priceCents * qty;
      if (p.eligibleForDailyPerk === true && eligiblePriceCents === null) {
        eligiblePriceCents = priceCents;
      }
      orderItems.push({
        productId: it.productId,
        name: p.name,
        priceCents,
        quantity: qty,
      });
    }

    // Beneficio de socio: 1 Americano/día a $1.
    const userSnap = await db.collection("users").doc(uid).get();
    const user = userSnap.data() || {};
    const isSubscriber = user.isSubscriber === true;
    const perkAvailable = isSubscriber && user.lastPerkDate !== todayStr();

    let discount = 0;
    if (perkAvailable && eligiblePriceCents !== null) {
      discount = Math.max(0, eligiblePriceCents - SOCIO_PRICE_CENTS);
    }
    const perkApplied = discount > 0;
    const totalCents = subtotal - discount;

    const now = admin.firestore.Timestamp.now();
    const orderRef = await db.collection("orders").add({
      userId: uid,
      items: orderItems,
      totalCents,
      status: "awaiting_payment",
      createdAt: now,
      estimatedReadyAt: admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 5 * 60 * 1000
      ),
      lockerNumber: null,
      perkApplied,
    });

    const stripe = getStripe();
    const customerId = await ensureCustomer(uid, user, stripe);
    const intent = await stripe.paymentIntents.create({
      amount: totalCents,
      currency: "mxn",
      customer: customerId,
      automatic_payment_methods: {enabled: true},
      metadata: {orderId: orderRef.id, uid, perkApplied: String(perkApplied)},
    });

    return {
      clientSecret: intent.client_secret,
      orderId: orderRef.id,
      amountCents: totalCents,
      perkApplied,
    };
  }
);

/**
 * [CLIENTE] Inicia la suscripción de socio con Stripe Billing.
 */
export const createSubscription = onCall(
  {secrets: [stripeSecret]},
  async (request) => {
    const uid = requireAuth(request);
    const db = admin.firestore();
    const userSnap = await db.collection("users").doc(uid).get();
    const user = userSnap.data() || {};

    const stripe = getStripe();
    const customerId = await ensureCustomer(uid, user, stripe);

    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{price: subscriptionPrice.value()}],
      payment_behavior: "default_incomplete",
      payment_settings: {save_default_payment_method: "on_subscription"},
      expand: ["latest_invoice.payment_intent"],
    });

    const invoice = subscription.latest_invoice as Stripe.Invoice;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const pi = (invoice as any).payment_intent as Stripe.PaymentIntent;

    return {clientSecret: pi.client_secret, subscriptionId: subscription.id};
  }
);

/**
 * Webhook de Stripe. Fuente de verdad para pagos y estado de suscripción.
 */
export const stripeWebhook = onRequest(
  {secrets: [stripeSecret, webhookSecret]},
  async (req, res) => {
    const stripe = getStripe();
    const signature = req.headers["stripe-signature"] as string;
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        // rawBody lo agrega Firebase al request de Express.
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (req as any).rawBody,
        signature,
        webhookSecret.value()
      );
    } catch (err) {
      res.status(400).send(`Webhook Error: ${(err as Error).message}`);
      return;
    }

    const db = admin.firestore();

    switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object as Stripe.PaymentIntent;
        const orderId = pi.metadata.orderId;
        const uid = pi.metadata.uid;
        if (orderId) {
          await db
            .collection("orders")
            .doc(orderId)
            .update({status: "pending", paymentRef: pi.id});
        }
        if (pi.metadata.perkApplied === "true" && uid) {
          await db
            .collection("users")
            .doc(uid)
            .set({lastPerkDate: todayStr()}, {merge: true});
        }
        break;
      }
      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const uid = await uidFromCustomer(sub.customer as string, db);
        if (uid) {
          const active = sub.status === "active" || sub.status === "trialing";
          await db
            .collection("users")
            .doc(uid)
            .set(
              {isSubscriber: active, subscriptionStatus: sub.status},
              {merge: true}
            );
        }
        break;
      }
      default:
        break;
    }

    res.json({received: true});
  }
);

/**
 * [EMPLEADO] Marca la orden lista y asigna un casillero libre (transaccional).
 */
export const markOrderReady = onCall(async (request) => {
  requireStaff(request);
  const orderId = request.data?.orderId as string | undefined;
  if (!orderId) throw new HttpsError("invalid-argument", "Falta orderId.");

  const db = admin.firestore();
  const lockerNumber = await db.runTransaction(async (tx) => {
    const q = await tx.get(
      db.collection("lockers").where("status", "==", "free").limit(1)
    );
    if (q.empty) {
      throw new HttpsError("resource-exhausted", "No hay casilleros libres.");
    }
    const lockerDoc = q.docs[0];
    tx.update(lockerDoc.ref, {status: "occupied", currentOrderId: orderId});
    return Number(lockerDoc.data().number);
  });

  const pin = String(1000 + Math.floor(Math.random() * 9000));
  await db
    .collection("orders")
    .doc(orderId)
    .update({status: "ready", lockerNumber, lockerPin: pin});

  // TODO(hardware): reservar físicamente el casillero si el proveedor lo exige.
  return {lockerNumber};
});

/**
 * [CLIENTE] Abre el casillero de su pedido y confirma la recogida.
 */
export const openLocker = onCall(async (request) => {
  const uid = requireAuth(request);
  const orderId = request.data?.orderId as string | undefined;
  if (!orderId) throw new HttpsError("invalid-argument", "Falta orderId.");

  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);
  const order = (await orderRef.get()).data();
  if (!order || order.userId !== uid) {
    throw new HttpsError("permission-denied", "No es tu pedido.");
  }
  if (order.status !== "ready") {
    throw new HttpsError("failed-precondition", "El pedido no está listo.");
  }

  const lockerNumber = Number(order.lockerNumber);
  // TODO(hardware): enviar el comando de apertura al casillero `lockerNumber`.
  await orderRef.update({status: "pickedUp"});

  const q = await db
    .collection("lockers")
    .where("number", "==", lockerNumber)
    .limit(1)
    .get();
  if (!q.empty) {
    await q.docs[0].ref.update({status: "free", currentOrderId: null});
  }

  return {opened: true};
});

/**
 * [EMPLEADO] Cierre de caja: calcula totales del turno y lo cierra.
 */
export const closeShift = onCall(async (request) => {
  requireStaff(request);
  const shiftId = request.data?.shiftId as string | undefined;
  if (!shiftId) throw new HttpsError("invalid-argument", "Falta shiftId.");

  const db = admin.firestore();
  const shiftRef = db.collection("shifts").doc(shiftId);
  const shift = (await shiftRef.get()).data();
  if (!shift) throw new HttpsError("not-found", "Turno no encontrado.");

  const startedAt = shift.startedAt as admin.firestore.Timestamp;
  const closedAt = admin.firestore.Timestamp.now();

  const ordersSnap = await db
    .collection("orders")
    .where("createdAt", ">=", startedAt)
    .where("createdAt", "<=", closedAt)
    .get();

  let totalSalesCents = 0;
  ordersSnap.forEach((d) => {
    totalSalesCents += Number(d.data().totalCents) || 0;
  });

  await shiftRef.update({
    endedAt: closedAt,
    ordersCount: ordersSnap.size,
    totalSalesCents,
  });

  return {ordersCount: ordersSnap.size, totalSalesCents};
});
