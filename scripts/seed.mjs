/**
 * Puebla Firestore con el menú y los 12 casilleros.
 *
 * Uso:
 *   1. Descarga la clave de servicio de tu proyecto Firebase
 *      (Configuración del proyecto → Cuentas de servicio → Generar clave)
 *      y guárdala como `scripts/serviceAccountKey.json` (NO la subas a git).
 *   2. npm i firebase-admin   (o desde functions/)
 *   3. node scripts/seed.mjs
 */
import {readFileSync} from "node:fs";
import admin from "firebase-admin";

const serviceAccount = JSON.parse(
  readFileSync(new URL("./serviceAccountKey.json", import.meta.url))
);
admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
const db = admin.firestore();

const products = [
  {id: "espresso", name: "Espresso", description: "Shot de espresso de la casa.", priceCents: 3500, category: "Café"},
  {id: "americano", name: "Americano", description: "Espresso con agua caliente.", priceCents: 4000, category: "Café", eligibleForDailyPerk: true},
  {id: "latte", name: "Latte", description: "Espresso con leche vaporizada.", priceCents: 5000, category: "Café"},
  {id: "matcha", name: "Matcha", description: "Té matcha con leche.", priceCents: 6000, category: "Café"},
  {id: "lucuma-matcha-latte", name: "Lucuma Matcha Latte", description: "Matcha latte con lúcuma.", priceCents: 7000, category: "Café"},
  {id: "cold-brew", name: "Cold Brew", description: "Café de extracción en frío.", priceCents: 5500, category: "Café"},
  {id: "lemonade", name: "Lemonade", description: "Limonada natural.", priceCents: 4500, category: "Café"},
  {id: "smoothie", name: "Smoothie", description: "Smoothie de frutos rojos.", priceCents: 6500, category: "Café"},
  {id: "pizza-doble-pepperoni", name: "Doble Pepperoni", description: "Doble pepperoni y queso mozzarella.", priceCents: 13000, category: "Pizza"},
  {id: "pizza-3-quesos", name: "3 Quesos", description: "Mozzarella, manchego y queso de cabra.", priceCents: 13000, category: "Pizza"},
  {id: "pizza-lomo-canadiense", name: "Lomo Canadiense con Tomate", description: "Lomo canadiense, tomate fresco y queso mozzarella.", priceCents: 13000, category: "Pizza"},
  {id: "pizza-mexicana", name: "La Mexicana", description: "Tocino, tomate, cebolla, chorizo y queso mozzarella.", priceCents: 13000, category: "Pizza"},
  {id: "pizza-espanola", name: "La Española", description: "Queso manchego con chorizo Pamplona.", priceCents: 13000, category: "Pizza"},
  {id: "pizza-italiana", name: "La Italiana", description: "Mozzarella + Salami Sobrassata.", priceCents: 13000, category: "Pizza"},
  {id: "postre-galleta", name: "Sándwich de Galleta con Chispas", description: "Galleta con chispas de chocolate y helado de fresa.", priceCents: 3900, category: "Postre"},
];

const branches = [
  {id: "condesa", name: "Condesa", address: "Av. Michoacán 100, Condesa"},
  {id: "roma", name: "Roma Norte", address: "Álvaro Obregón 50, Roma Nte."},
  {id: "polanco", name: "Polanco", address: "Emilio Castelar 20, Polanco"},
];

const LOCKERS_PER_BRANCH = 12;

// Cuentas del personal (email/contraseña) con su rol y sucursal.
const staff = [
  {email: "condesa@theclubcoffe.mx", password: "1234", name: "Empleado Condesa", role: "employee", branchId: "condesa"},
  {email: "roma@theclubcoffe.mx", password: "1234", name: "Empleado Roma", role: "employee", branchId: "roma"},
  {email: "admin@theclubcoffe.mx", password: "admin1234", name: "Administrador General", role: "admin", branchId: null},
];

async function seedFirestore() {
  const batch = db.batch();

  for (const p of products) {
    const {id, ...data} = p;
    batch.set(db.collection("products").doc(id), {
      ...data,
      eligibleForDailyPerk: data.eligibleForDailyPerk ?? false,
      available: true,
    });
  }

  for (const b of branches) {
    const {id, ...data} = b;
    batch.set(db.collection("branches").doc(id), {...data, lockerCount: LOCKERS_PER_BRANCH});
    // Casilleros por sucursal: id = "<branchId>-<n>".
    for (let n = 1; n <= LOCKERS_PER_BRANCH; n++) {
      batch.set(db.collection("lockers").doc(`${id}-${n}`), {
        number: n,
        branchId: id,
        status: "free",
        currentOrderId: null,
      });
    }
  }

  await batch.commit();
}

async function seedStaff() {
  for (const s of staff) {
    let uid;
    try {
      const existing = await admin.auth().getUserByEmail(s.email);
      uid = existing.uid;
    } catch {
      const created = await admin.auth().createUser({email: s.email, password: s.password});
      uid = created.uid;
    }
    // Custom claims: rol y sucursal (los usan reglas y Cloud Functions).
    await admin.auth().setCustomUserClaims(uid, {role: s.role, branchId: s.branchId ?? null});
    await db.collection("staff").doc(uid).set({
      name: s.name,
      email: s.email,
      role: s.role,
      branchId: s.branchId ?? null,
    });
  }
}

async function main() {
  await seedFirestore();
  await seedStaff();
  console.log(
    `Seed listo: ${products.length} productos, ${branches.length} sucursales ` +
    `(${LOCKERS_PER_BRANCH} casilleros c/u) y ${staff.length} cuentas de personal.`
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
