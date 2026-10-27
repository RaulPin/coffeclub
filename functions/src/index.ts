/**
 * Cloud Functions de Barra — Pagos con Mercado Pago (modelo marketplace/split).
 *
 * Responsabilidades del servidor (fuente de verdad, nunca el cliente):
 *  - Conexión de cada cafetería con su cuenta de Mercado Pago (OAuth).
 *  - Crear el cobro de un pedido reteniendo la comisión de Barra
 *    (`marketplace_fee`): MP divide el dinero en automático.
 *  - Confirmar el pago vía webhook y marcar el pedido como pagado; recién
 *    entonces la cafetería lo ve en su cola.
 *
 * La llave secreta de Mercado Pago vive SOLO aquí (secretos de Firebase).
 */
import {onCall, onRequest, HttpsError, CallableRequest} from
  "firebase-functions/v2/https";
import {defineSecret, defineString} from "firebase-functions/params";
import * as admin from "firebase-admin";

admin.initializeApp();

// --- Credenciales de la aplicación de Mercado Pago (de tu panel de MP) ---
const MP_CLIENT_ID = defineString("MP_CLIENT_ID");
const MP_CLIENT_SECRET = defineSecret("MP_CLIENT_SECRET");
/** Access token de la app marketplace (para consultar pagos en el webhook). */
const MP_ACCESS_TOKEN = defineSecret("MP_ACCESS_TOKEN");
/** URL pública de la función mpOAuthCallback (redirect_uri registrada en MP). */
const MP_REDIRECT_URI = defineString("MP_REDIRECT_URI");
/** A dónde regresa el usuario tras conectar o pagar (web o deep link). */
const APP_RETURN_URL = defineString("APP_RETURN_URL");

// --- Modelo de negocio (fuente de verdad en el servidor) ---
const COMMISSION_RATE = 0.08; // 8% al café
const SERVICE_FEE_CENTS = 1000; // $10 no socio
const MEMBER_FEE_CENTS = 500; // $5 socio

const MP_API = "https://api.mercadopago.com";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Inicia sesión.");
  return uid;
}

/** Código de recogida corto, p. ej. "K4T9". */
function pickupCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 4; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

/** Llamada REST a Mercado Pago con un bearer token. */
async function mpFetch<T>(
  path: string,
  token: string,
  init?: {method?: string; body?: unknown}
): Promise<T> {
  const res = await fetch(`${MP_API}${path}`, {
    method: init?.method ?? "GET",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: init?.body ? JSON.stringify(init.body) : undefined,
  });
  const data = await res.json();
  if (!res.ok) {
    throw new HttpsError(
      "internal",
      `Mercado Pago (${res.status}): ${JSON.stringify(data)}`
    );
  }
  return data as T;
}

/** Token de la cafetería (obtenido en el OAuth). Lanza si no está conectada. */
async function cafeAccessToken(cafeId: string): Promise<string> {
  const snap = await admin
    .firestore()
    .collection("cafe_payments")
    .doc(cafeId)
    .get();
  const token = snap.data()?.accessToken as string | undefined;
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "La cafetería aún no conectó su cuenta de Mercado Pago."
    );
  }
  return token;
}

// ─── Paso 1: Conexión de la cafetería con Mercado Pago (OAuth) ───────────────

/**
 * [CAFÉ] Devuelve la URL para que el dueño autorice a Barra a cobrar en su
 * nombre. El `state` lleva el id de la cafetería para el callback.
 */
export const mpConnectUrl = onCall(async (request) => {
  const uid = requireAuth(request);
  const cafeId = request.data?.cafeId as string | undefined;
  if (!cafeId) throw new HttpsError("invalid-argument", "Falta cafeId.");

  // Solo el dueño (o un admin) puede conectar la cuenta de esa cafetería.
  const staff = (
    await admin.firestore().collection("staff").doc(uid).get()
  ).data();
  const isOwner = staff?.branchId === cafeId;
  const isAdmin = staff?.role === "admin";
  if (!isOwner && !isAdmin) {
    throw new HttpsError("permission-denied", "No es tu cafetería.");
  }

  const url =
    "https://auth.mercadopago.com/authorization" +
    `?client_id=${encodeURIComponent(MP_CLIENT_ID.value())}` +
    "&response_type=code&platform_id=mp" +
    `&state=${encodeURIComponent(cafeId)}` +
    `&redirect_uri=${encodeURIComponent(MP_REDIRECT_URI.value())}`;

  return {url};
});

/**
 * [CAFÉ] Callback de OAuth: Mercado Pago regresa aquí con `code` + `state`.
 * Intercambiamos el code por los tokens de la cafetería y los guardamos.
 */
export const mpOAuthCallback = onRequest(
  {secrets: [MP_CLIENT_SECRET]},
  async (req, res) => {
    const code = req.query.code as string | undefined;
    const cafeId = req.query.state as string | undefined;
    if (!code || !cafeId) {
      res.status(400).send("Faltan parámetros de autorización.");
      return;
    }

    try {
      const token = await mpFetch<{
        access_token: string;
        refresh_token: string;
        user_id: number;
        public_key: string;
      }>("/oauth/token", "", {
        method: "POST",
        body: {
          client_id: MP_CLIENT_ID.value(),
          client_secret: MP_CLIENT_SECRET.value(),
          code,
          grant_type: "authorization_code",
          redirect_uri: MP_REDIRECT_URI.value(),
        },
      });

      const db = admin.firestore();
      // Credenciales sensibles: colección aparte (bloquear a clientes en rules).
      await db.collection("cafe_payments").doc(cafeId).set({
        mpUserId: token.user_id,
        accessToken: token.access_token,
        refreshToken: token.refresh_token,
        publicKey: token.public_key,
        connectedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      // Bandera pública para que la app sepa que ya está conectada.
      await db.collection("cafes").doc(cafeId).set(
        {mpConnected: true},
        {merge: true}
      );

      res.redirect(`${APP_RETURN_URL.value()}?mp=connected`);
    } catch (err) {
      res.status(500).send(`Error al conectar: ${(err as Error).message}`);
    }
  }
);

// ─── Paso 2: Cobro del pedido con split + webhook (listo para habilitar) ─────

/**
 * [CLIENTE] Crea el pedido (sin pagar) y genera el cobro en Mercado Pago con
 * la comisión de Barra retenida (`marketplace_fee`). Devuelve la URL de pago.
 * El servidor recalcula los montos desde Firestore (no confía en el cliente).
 */
export const createOrderPayment = onCall(
  {secrets: [MP_ACCESS_TOKEN]},
  async (request) => {
    const uid = requireAuth(request);
    const branchId = request.data?.branchId as string | undefined;
    const items = request.data?.items as
      | {productId: string; quantity: number}[]
      | undefined;
    if (!branchId) throw new HttpsError("invalid-argument", "Falta sucursal.");
    if (!items || items.length === 0) {
      throw new HttpsError("invalid-argument", "El carrito está vacío.");
    }

    const db = admin.firestore();

    // 1) Recalcular subtotal desde el menú real de la cafetería.
    let subtotal = 0;
    const orderItems: FirebaseFirestore.DocumentData[] = [];
    const mpItems: Record<string, unknown>[] = [];
    for (const it of items) {
      const snap = await db
        .collection("cafes")
        .doc(branchId)
        .collection("products")
        .doc(it.productId)
        .get();
      if (!snap.exists) {
        throw new HttpsError("not-found", `Producto ${it.productId} no existe.`);
      }
      const p = snap.data()!;
      const qty = Math.max(1, Math.floor(it.quantity || 1));
      const priceCents = Number(p.priceCents) || 0;
      subtotal += priceCents * qty;
      orderItems.push({
        productId: it.productId,
        name: p.name,
        priceCents,
        quantity: qty,
      });
      mpItems.push({
        title: String(p.name),
        quantity: qty,
        unit_price: priceCents / 100,
        currency_id: "MXN",
      });
    }

    // 2) Cuota de servicio (socio vs no socio) y comisión de Barra.
    const user = (await db.collection("users").doc(uid).get()).data() || {};
    const isMember = user.isSubscriber === true;
    const feeCents = isMember ? MEMBER_FEE_CENTS : SERVICE_FEE_CENTS;
    const commissionCents = Math.round(subtotal * COMMISSION_RATE);
    const totalCents = subtotal + feeCents;
    const marketplaceFeeCents = commissionCents + feeCents; // lo que retiene Barra

    // La cuota de servicio es un concepto más en el cobro.
    if (feeCents > 0) {
      mpItems.push({
        title: "Cuota de servicio Barra",
        quantity: 1,
        unit_price: feeCents / 100,
        currency_id: "MXN",
      });
    }

    // 3) Crear el pedido SIN pagar (invisible para la cafetería hasta el pago).
    const now = admin.firestore.Timestamp.now();
    const orderRef = await db.collection("orders").add({
      userId: uid,
      branchId,
      items: orderItems,
      totalCents,
      status: "pending",
      createdAt: now,
      estimatedReadyAt: admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 5 * 60 * 1000
      ),
      pickupCode: pickupCode(),
      paymentMethod: "mercadopago",
      paid: false,
    });

    // 4) Crear la preferencia de pago con el token de la cafetería + split.
    const sellerToken = await cafeAccessToken(branchId);
    const pref = await mpFetch<{id: string; init_point: string}>(
      "/checkout/preferences", sellerToken, {
        method: "POST",
        body: {
        items: mpItems,
        marketplace_fee: marketplaceFeeCents / 100,
        external_reference: orderRef.id,
        notification_url: `${MP_REDIRECT_URI.value().replace(
          "mpOAuthCallback",
          "mpWebhook"
        )}`,
        back_urls: {
          success: `${APP_RETURN_URL.value()}?order=${orderRef.id}`,
          pending: `${APP_RETURN_URL.value()}?order=${orderRef.id}`,
          failure: `${APP_RETURN_URL.value()}?order=${orderRef.id}&pay=failed`,
        },
        auto_return: "approved",
        metadata: {orderId: orderRef.id},
        },
      });

    await orderRef.update({mpPreferenceId: pref.id});

    return {orderId: orderRef.id, initPoint: pref.init_point};
  }
);

/**
 * Webhook de Mercado Pago. Cuando un pago se aprueba, marca el pedido como
 * pagado; a partir de ahí la cafetería lo ve en su cola.
 */
export const mpWebhook = onRequest(
  {secrets: [MP_ACCESS_TOKEN]},
  async (req, res) => {
    // MP notifica con { type: "payment", data: { id } } (o query params).
    const paymentId =
      (req.body?.data?.id as string | undefined) ??
      (req.query["data.id"] as string | undefined) ??
      (req.query.id as string | undefined);
    const topic = (req.body?.type as string | undefined) ??
      (req.query.topic as string | undefined);

    if (topic && topic !== "payment") {
      res.status(200).send("ignored");
      return;
    }
    if (!paymentId) {
      res.status(200).send("no id");
      return;
    }

    try {
      const payment = (await mpFetch(
        `/v1/payments/${paymentId}`,
        MP_ACCESS_TOKEN.value()
      )) as {status: string; external_reference?: string};

      const orderId = payment.external_reference;
      if (payment.status === "approved" && orderId) {
        await admin
          .firestore()
          .collection("orders")
          .doc(orderId)
          .set({paid: true, paymentRef: paymentId}, {merge: true});
      }
      res.status(200).send("ok");
    } catch (err) {
      // 200 para que MP no reintente en bucle ante errores no recuperables.
      res.status(200).send(`handled: ${(err as Error).message}`);
    }
  }
);
