# CoffeClub — Brief de Diseño (Figma)

> Documento de referencia para el rediseño visual en Figma.
> Refleja la app **tal como existe hoy** en el código. No inventa pantallas.
> Marca de la app: **The Club Coffe** — estética minimalista blanco/negro.

---

## 1. Producto y concepto

App móvil de pedidos de café para socios de **The Club Coffe**. El socio pide
desde el celular, paga, y recoge su pedido en un **casillero (locker) con PIN**
en la sucursal — sin fila. El gancho del negocio es la membresía:
**"1 café al día por $1"** (hoy aplica al Americano).

Hay dos mundos dentro de la app:

- **Cliente (socio):** pide, paga y rastrea su pedido.
- **Estación de tienda (staff/admin):** gestiona la cola de pedidos por
  sucursal y cierra turno. Entra por una ruta aparte (`/staff`).

Moneda: **MXN**. Menú real: café (bebidas), **pizza ($130)** y **postre ($39)**.

---

## 2. Público y tono

- **Usuario:** cliente urbano, joven-adulto, que quiere rapidez y cero fricción.
- **Personalidad de marca:** minimalista, premium accesible, "club" (sentido de
  pertenencia). Blanco y negro como base; el café/producto pone el color.
- **Tono visual objetivo:** limpio, mucho aire, tipografía fuerte, fotografía de
  producto protagonista, microinteracciones sutiles.

---

## 3. Fundamentos de diseño (punto de partida actual)

Esto ya vive en el código (`lib/core/theme/app_theme.dart`). Sirve como base;
en Figma lo puedes evolucionar, pero conviene mantener la lógica de tokens.

**Color**
| Token | Valor | Uso |
|---|---|---|
| `ink` | `#0A0A0A` | Texto principal, botones, acentos |
| `paper` | `#F7F5F1` | Fondo de pantalla |
| `surface` | `#FFFFFF` | Cards, superficies elevadas |
| `muted` | `#6B6B6B` | Texto secundario |
| onPrimary | `#FFFFFF` | Texto sobre botón oscuro |

> Falta por definir en el rediseño: color de **éxito**, **error/alerta**,
> **info**, y un posible **acento de marca** (si se quiere romper el B/N).

**Tipografía:** `Inter` (Google Fonts). Definir escala: Display / H1 / H2 /
Título / Cuerpo / Caption / Botón.

**Forma:** radios ~12px (botones/cards). Botón primario altura 52px, ancho
completo. Definir en Figma: escala de spacing (4/8/12/16/24/32), elevaciones y
estilo de sombra.

---

## 4. Inventario de pantallas

### 4.1 Cliente

| # | Pantalla | Ruta | Propósito | Elementos clave |
|---|---|---|---|---|
| 1 | **Login** | `/login` | Entrada del socio | Logo, campos de acceso, CTA entrar |
| 2 | **Menú** | `/menu` | Explorar y agregar productos | Categorías (Café / Pizza / Postre), cards de producto (imagen, nombre, desc, precio), badge del **beneficio diario** en Americano, acceso a carrito |
| 3 | **Suscripción** | `/subscription` | Vender/gestionar membresía "1 café al día por $1" | Estado de socio, beneficio del día (disponible / ya usado), CTA |
| 4 | **Carrito** | `/cart` | Revisar antes de pagar | Lista de ítems, cantidades, subtotal/total, CTA checkout, estado vacío |
| 5 | **Checkout** | `/checkout` | Pagar el pedido | Resumen, método de pago, sucursal de recogida, CTA pagar |
| 6 | **Rastreo de pedido** | `/order` | Seguir el pedido hasta recoger | Estado (En cola → Preparando → Listo → Recogido), contador estimado, **número de casillero + PIN** |

### 4.2 Estación de tienda (staff / admin)

| # | Pantalla | Ruta | Propósito | Elementos clave |
|---|---|---|---|---|
| 7 | **Login de staff** | `/staff` | Acceso de empleado/admin | Distinto del login de cliente |
| 8 | **Dashboard empleado** | `/staff` (rol empleado) | Cola de pedidos de SU sucursal | Lista de pedidos por estado, acciones (avanzar estado, asignar casillero) |
| 9 | **Dashboard admin** | `/staff` (rol admin) | Vista multi-sucursal | Lista de sucursales, métricas, entrar a una sucursal |
| 10 | **Sucursal (admin)** | `/staff/branch/:id` | Operar una sucursal específica | Cola, casilleros (1–12), estado |
| 11 | **Cierre de turno** | `/staff/close` | Cerrar caja/turno | Resumen del turno, confirmación |

---

## 5. Componentes reutilizables a diseñar

Diseñar como **componentes con variantes** en Figma (no pantallas sueltas):

- **Botón** — primario / secundario / texto; estados: normal, presionado,
  cargando, deshabilitado.
- **Card de producto** — con y sin imagen; con badge de beneficio.
- **Ítem de carrito** — con stepper de cantidad y precio.
- **Badge / Chip** — categorías, "beneficio del día", estado de pedido.
- **Píldora de estado de pedido** — 4 estados (En cola, Preparando, Listo,
  Recogido) con color propio cada uno.
- **Campo de formulario** — normal, foco, error.
- **App bar** — centrada, sin elevación (como hoy).
- **Barra inferior / navegación** — definir si el cliente navega por tabs.
- **Tarjeta de casillero + PIN** — el momento estrella del pedido listo.
- **Fila de pedido (staff)** — para la cola operativa.

---

## 6. Estados que NO se pueden olvidar

Para cada pantalla con datos, diseñar los 4 estados:

- **Cargando** (skeletons preferidos sobre spinners).
- **Vacío** (carrito vacío, sin pedidos, sin resultados).
- **Error** (falló la red / el pago) con acción de reintento.
- **Éxito** (pago confirmado, pedido listo).

---

## 7. Flujos (prototipar en Figma)

1. **Compra del socio:** Login → Menú → (agregar) Carrito → Checkout → Pago →
   Rastreo → **Casillero + PIN** → Recogido.
2. **Beneficio diario:** Menú/Suscripción → Americano a $1 → confirmación →
   beneficio marcado como usado hoy.
3. **Operación de tienda:** Login staff → Cola → avanzar pedido → asignar
   casillero → listo → cierre de turno.

---

## 8. Qué necesito de Figma para implementarlo

Para bajar el diseño a Flutter fiel y rápido, entrégame:

- **Design tokens definidos** (colores, tipografía, spacing, radios) como
  estilos/variables de Figma — no colores sueltos.
- **Componentes con variantes y estados** (ver §5).
- **Todas las pantallas de §4** en tamaño móvil (recomendado: 390×844 iPhone y/o
  360×800 Android).
- **Prototipo navegable** de los 3 flujos de §7.
- Acceso en **Dev Mode** (o export) para leer medidas, colores y exportar
  imágenes/íconos.

---

## Apéndice — estructura sugerida del archivo Figma

```
📄 00 · Cover / brief
📄 01 · Foundations (color, tipografía, spacing, iconografía)
📄 02 · Components (con variantes)
📄 03 · Cliente (pantallas 1–6)
📄 04 · Staff/Admin (pantallas 7–11)
📄 05 · Prototype (flujos)
```
