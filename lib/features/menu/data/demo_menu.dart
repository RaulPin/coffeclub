import '../domain/product.dart';

/// Menú de ejemplo (demo). En producción cada cafetería carga el suyo en
/// Firestore; aquí sirve como semilla del store editable en memoria.
///
/// Precios: PIZZAS ($130) y POSTRE ($39) son del menú oficial; los de BEBIDAS
/// son placeholder. Imágenes de Unsplash (demo).
const kDemoMenu = <Product>[
  // --- Café ---
  Product(
    id: 'espresso',
    name: 'Espresso',
    description: 'Shot de espresso de la casa.',
    priceCents: 3500,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'americano',
    name: 'Americano',
    description: 'Espresso con agua caliente.',
    priceCents: 4000,
    category: 'Café',
    eligibleForDailyPerk: true,
    imageUrl:
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'latte',
    name: 'Latte',
    description: 'Espresso con leche vaporizada.',
    priceCents: 5000,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'matcha',
    name: 'Matcha',
    description: 'Té matcha con leche.',
    priceCents: 6000,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'lucuma-matcha-latte',
    name: 'Lucuma Matcha Latte',
    description: 'Matcha latte con lúcuma.',
    priceCents: 7000,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'cold-brew',
    name: 'Cold Brew',
    description: 'Café de extracción en frío.',
    priceCents: 5500,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'lemonade',
    name: 'Lemonade',
    description: 'Limonada natural.',
    priceCents: 4500,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'smoothie',
    name: 'Smoothie',
    description: 'Smoothie de frutos rojos.',
    priceCents: 6500,
    category: 'Café',
    imageUrl:
        'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&h=300&fit=crop',
  ),

  // --- Pizza (NY Style — 30 cm · 6 rebanadas · $130) ---
  Product(
    id: 'pizza-doble-pepperoni',
    name: 'Doble Pepperoni',
    description: 'Doble pepperoni y queso mozzarella.',
    priceCents: 13000,
    category: 'Pizza',
    imageUrl:
        'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'pizza-3-quesos',
    name: '3 Quesos',
    description: 'Mozzarella, manchego y queso de cabra.',
    priceCents: 13000,
    category: 'Pizza',
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'pizza-lomo-canadiense',
    name: 'Lomo Canadiense con Tomate',
    description: 'Lomo canadiense, tomate fresco y queso mozzarella.',
    priceCents: 13000,
    category: 'Pizza',
    imageUrl:
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'pizza-mexicana',
    name: 'La Mexicana',
    description: 'Tocino, tomate, cebolla, chorizo y queso mozzarella.',
    priceCents: 13000,
    category: 'Pizza',
    imageUrl:
        'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'pizza-espanola',
    name: 'La Española',
    description: 'Queso manchego con chorizo Pamplona.',
    priceCents: 13000,
    category: 'Pizza',
    imageUrl:
        'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=400&h=300&fit=crop',
  ),
  Product(
    id: 'pizza-italiana',
    name: 'La Italiana',
    description: 'Mozzarella + Salami Sobrassata.',
    priceCents: 13000,
    category: 'Pizza',
    imageUrl:
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=300&fit=crop',
  ),

  // --- Postre ---
  Product(
    id: 'postre-galleta',
    name: 'Sándwich de Galleta con Chispas',
    description: 'Galleta con chispas de chocolate y helado de fresa.',
    priceCents: 3900,
    category: 'Postre',
    imageUrl:
        'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400&h=300&fit=crop',
  ),
];
