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

const LOCKER_COUNT = 12;

async function main() {
  const batch = db.batch();

  for (const p of products) {
    const {id, ...data} = p;
    batch.set(db.collection("products").doc(id), {
      ...data,
      eligibleForDailyPerk: data.eligibleForDailyPerk ?? false,
      available: true,
    });
  }

  for (let n = 1; n <= LOCKER_COUNT; n++) {
    batch.set(db.collection("lockers").doc(String(n)), {
      number: n,
      status: "free",
      currentOrderId: null,
    });
  }

  await batch.commit();
  console.log(`Seed listo: ${products.length} productos y ${LOCKER_COUNT} casilleros.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
