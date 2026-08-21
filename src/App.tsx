import { useState, useEffect } from "react";

// ─── Types ────────────────────────────────────────────────────────────────────

type Screen = "menu" | "cart" | "tracking" | "membership" | "staff";
type OrderStatus = "queued" | "preparing" | "ready" | "collected";
type MemberState = "active" | "used" | "inactive";

interface CartItem { id: string; name: string; variant: string; price: number; qty: number; image: string; }
interface Product   { id: string; name: string; desc: string; price: number; image: string; category: string; badge?: string; }
interface StaffOrder {
  id: string; customer: string;
  items: { name: string; variant: string; qty: number }[];
  status: OrderStatus; locker: number | null;
  placedAt: Date; pin: string; isMember: boolean; total: number;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const fmt  = (n: number) => "$" + Math.round(n).toLocaleString("es-MX") + " MXN";
const fmtS = (n: number) => "$" + Math.round(n).toLocaleString("es-MX");
const elapsed = (d: Date) => { const m = Math.floor((Date.now()-d.getTime())/60000); return m<1?"ahora":m===1?"1 min":`${m} min`; };
const ago = (mins: number) => new Date(Date.now() - mins*60000);

// ─── Data ─────────────────────────────────────────────────────────────────────

const PRODUCTS: Product[] = [
  { id:"esp",  name:"Espresso",         desc:"Shot etíope, crema densa, cacao y cítrico.",               price:55,  image:"https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400&h=300&fit=crop&auto=format", category:"Café" },
  { id:"ame",  name:"Americano",        desc:"Espresso diluido en agua caliente. Limpio y profundo.",    price:1,   image:"https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=300&fit=crop&auto=format", category:"Café", badge:"1 café al día por $1 — beneficio de socio" },
  { id:"fw",   name:"Flat White",       desc:"Doble ristretto con leche micro-espumada.",                price:79,  image:"https://images.unsplash.com/photo-1534040385115-33dcb3acba5b?w=400&h=300&fit=crop&auto=format", category:"Café" },
  { id:"cb",   name:"Cold Brew",        desc:"Infusionado 24 h en frío. Naturalmente dulce.",            price:95,  image:"https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=300&fit=crop&auto=format", category:"Café" },
  { id:"piz",  name:"Pizza Margherita", desc:"San Marzano, mozzarella fresca y albahaca.",               price:130, image:"https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=300&fit=crop&auto=format", category:"Pizza" },
  { id:"brw",  name:"Brownie Club",     desc:"Chocolate 70%, sal de mar, helado de vainilla.",           price:39,  image:"https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400&h=300&fit=crop&auto=format", category:"Postre" },
];

const STAFF_ORDERS: StaffOrder[] = [
  { id:"CC-4829", customer:"Valentina R.", items:[{name:"Americano",variant:"Regular",qty:1},{name:"Brownie",variant:"Individual",qty:1}], status:"queued",    locker:null, placedAt:ago(2),  pin:"3849", isMember:true,  total:40  },
  { id:"CC-4830", customer:"Diego M.",     items:[{name:"Flat White",variant:"Avena",qty:1}],                                               status:"queued",    locker:null, placedAt:ago(4),  pin:"7213", isMember:false, total:94  },
  { id:"CC-4831", customer:"Sofía T.",     items:[{name:"Espresso",variant:"Doble shot",qty:2}],                                            status:"preparing", locker:null, placedAt:ago(7),  pin:"5502", isMember:false, total:130 },
  { id:"CC-4832", customer:"Andrés K.",    items:[{name:"Cold Brew",variant:"Regular",qty:1},{name:"Pizza",variant:"Personal",qty:1}],      status:"preparing", locker:3,    placedAt:ago(9),  pin:"9981", isMember:true,  total:225 },
  { id:"CC-4833", customer:"Camila V.",    items:[{name:"Matcha Latte",variant:"Almendra",qty:1}],                                          status:"ready",     locker:7,    placedAt:ago(14), pin:"4417", isMember:false, total:120 },
  { id:"CC-4834", customer:"Luis G.",      items:[{name:"Americano",variant:"Regular",qty:1}],                                             status:"ready",     locker:2,    placedAt:ago(18), pin:"6630", isMember:true,  total:1   },
  { id:"CC-4835", customer:"Mariana F.",   items:[{name:"Cortado",variant:"Regular",qty:1},{name:"Brownie",variant:"Individual",qty:2}],    status:"collected", locker:5,    placedAt:ago(35), pin:"1128", isMember:false, total:147 },
];

const STATUS_CFG: Record<OrderStatus,{label:string;color:string;bg:string;dot:string;border:string;next:OrderStatus|null;nextLabel:string;nextColor:string}> = {
  queued:    {label:"En cola",    color:"text-[#7A5C3A]",bg:"bg-[#F5EDE0]",dot:"bg-[#C8B89A]",border:"border-[#E8D9C4]",next:"preparing",nextLabel:"Iniciar preparación",nextColor:"bg-[#E8A838] text-[#0A0A0A]"},
  preparing: {label:"Preparando", color:"text-[#7A4F00]",bg:"bg-[#FEF3D0]",dot:"bg-[#E8A838]",border:"border-[#F0D88A]",next:"ready",    nextLabel:"Marcar como listo",   nextColor:"bg-[#3DAA6B] text-white"},
  ready:     {label:"Listo",      color:"text-[#0E5C30]",bg:"bg-[#D8F5E7]",dot:"bg-[#3DAA6B]",border:"border-[#A8E0C0]",next:"collected",nextLabel:"Confirmar recogida", nextColor:"bg-[#0A0A0A] text-white"},
  collected: {label:"Recogido",   color:"text-[#0A0A0A]",bg:"bg-[#E8E6E2]",dot:"bg-[#0A0A0A]",border:"border-[#D0CEC9]",next:null,      nextLabel:"",                   nextColor:""},
};

// ─── Icons ────────────────────────────────────────────────────────────────────

const I = {
  menu:       () => <svg width={20} height={20} fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16"/></svg>,
  cart:       () => <svg width={20} height={20} fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4zM3 6h18M16 10a4 4 0 01-8 0"/></svg>,
  track:      () => <svg width={20} height={20} fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path strokeLinecap="round" d="M12 7v5l3 3"/></svg>,
  member:     () => <svg width={20} height={20} fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"/></svg>,
  staff:      () => <svg width={20} height={20} fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>,
  plus:       () => <svg width={16} height={16} fill="none" stroke="currentColor" strokeWidth={2.2} viewBox="0 0 24 24"><path strokeLinecap="round" d="M12 5v14M5 12h14"/></svg>,
  minus:      () => <svg width={14} height={14} fill="none" stroke="currentColor" strokeWidth={2.2} viewBox="0 0 24 24"><path strokeLinecap="round" d="M5 12h14"/></svg>,
  trash:      () => <svg width={15} height={15} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>,
  check:      () => <svg width={14} height={14} fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7"/></svg>,
  chevron:    () => <svg width={14} height={14} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M9 18l6-6-6-6"/></svg>,
  locker:     () => <svg width={16} height={16} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><rect x="3" y="7" width="18" height="14" rx="2"/><path strokeLinecap="round" d="M8 7V5a4 4 0 018 0v2"/><circle cx="12" cy="14.5" r="1.6" fill="currentColor" stroke="none"/></svg>,
  lock:       () => <svg width={15} height={15} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2"/><path strokeLinecap="round" d="M7 11V7a5 5 0 0110 0v4"/></svg>,
  alert:      () => <svg width={14} height={14} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/></svg>,
  refresh:    () => <svg width={15} height={15} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>,
  coffee:     () => <svg width={18} height={18} fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M18 8h1a4 4 0 010 8h-1M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8zM6 2v2M10 2v2M14 2v2"/></svg>,
  star:       () => <svg width={14} height={14} fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87L18.18 21 12 17.77 5.82 21 7 14.14l-5-4.87 6.91-1.01L12 2z"/></svg>,
  clock:      () => <svg width={13} height={13} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path strokeLinecap="round" d="M12 7v5l3 3"/></svg>,
  pin:        () => <svg width={14} height={14} fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>,
};

// ─── Nav config ───────────────────────────────────────────────────────────────

const NAV: { id: Screen; label: string; Icon: () => JSX.Element }[] = [
  { id: "menu",       label: "Menú",       Icon: I.menu },
  { id: "cart",       label: "Carrito",    Icon: I.cart },
  { id: "tracking",   label: "Mi pedido",  Icon: I.track },
  { id: "membership", label: "Club",       Icon: I.member },
  { id: "staff",      label: "Staff",      Icon: I.staff },
];

// ─── Shared: section label ────────────────────────────────────────────────────

function SLabel({ children }: { children: string }) {
  return <p className="text-[10px] font-bold tracking-[0.2em] uppercase text-[#6B6B6B] mb-3">{children}</p>;
}

// ════════════════════════════════════════════════════════════════════════════════
// SCREEN: MENU
// ════════════════════════════════════════════════════════════════════════════════

function MenuScreen({ onAddToCart }: { onAddToCart: (p: Product) => void }) {
  const cats = ["Todos", "Café", "Pizza", "Postre"];
  const [active, setActive] = useState("Todos");

  const filtered = active === "Todos" ? PRODUCTS : PRODUCTS.filter(p => p.category === active);

  return (
    <div className="space-y-6">
      {/* Hero */}
      <div className="rounded-2xl overflow-hidden relative h-40 md:h-52 bg-[#1A1A1A]">
        <img src="https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=900&h=400&fit=crop&auto=format" alt="Coffee" className="w-full h-full object-cover opacity-60"/>
        <div className="absolute inset-0 flex flex-col justify-end p-5 md:p-7">
          <p className="text-white/70 text-xs font-bold tracking-[0.2em] uppercase mb-1">Sin fila</p>
          <p className="text-white text-xl md:text-3xl font-black leading-tight">Ordena antes.<br/>Recoge con PIN.</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-2 flex-wrap">
        {cats.map(c => (
          <button key={c} onClick={() => setActive(c)}
            className={`h-9 px-4 rounded-full text-sm font-semibold transition-all ${active===c?"bg-[#0A0A0A] text-white":"bg-white border border-[#E8E6E2] text-[#6B6B6B]"}` }>
            {c}
          </button>
        ))}
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map(p => (
          <div key={p.id} className="bg-white rounded-2xl overflow-hidden shadow-[0_1px_6px_rgba(0,0,0,0.07)]">
            <div className="relative h-40 bg-[#F7F5F1]">
              <img src={p.image} alt={p.name} className="w-full h-full object-cover"/>
              {p.badge && (
                <div className="absolute top-3 left-3 right-3 bg-[#0A0A0A] rounded-xl px-3 py-2">
                  <p className="text-white text-[11px] font-semibold leading-tight">⭐ {p.badge}</p>
                </div>
              )}
            </div>
            <div className="p-4">
              <h3 className="font-bold text-[#0A0A0A] text-base mb-1">{p.name}</h3>
              <p className="text-[#6B6B6B] text-sm mb-4 leading-relaxed">{p.desc}</p>
              <div className="flex items-center justify-between">
                <p className="font-black text-[#0A0A0A] text-lg">{fmt(p.price)}</p>
                <button onClick={() => onAddToCart(p)}
                  className="w-9 h-9 bg-[#0A0A0A] rounded-xl flex items-center justify-center text-white active:scale-95 transition-transform">
                  <I.plus/>
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// SCREEN: CART
// ════════════════════════════════════════════════════════════════════════════════

function CartScreen({ cart, onUpdate, onRemove }: {
  cart: CartItem[]; onUpdate: (id:string,d:number)=>void; onRemove: (id:string)=>void;
}) {
  const subtotal = cart.reduce((s,i) => s+i.price*i.qty, 0);
  const iva = subtotal*0.16;
  const total = subtotal+iva;

  if (!cart.length) return (
    <div className="flex flex-col items-center justify-center py-24 text-center">
      <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center mb-5 shadow-sm">
        <I.cart/>
      </div>
      <h2 className="text-xl font-black text-[#0A0A0A] mb-2">Carrito vacío</h2>
      <p className="text-[#6B6B6B] text-sm max-w-xs">Ve al menú y agrega tus favoritos.</p>
    </div>
  );

  return (
    <div className="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-6 items-start">
      {/* Items */}
      <div className="space-y-3">
        <SLabel>Tus artículos</SLabel>
        {cart.map(item => (
          <div key={item.id} className="bg-white rounded-2xl flex gap-0 overflow-hidden shadow-[0_1px_6px_rgba(0,0,0,0.06)]">
            <div className="w-24 h-24 flex-shrink-0 bg-[#F7F5F1]">
              <img src={item.image} alt={item.name} className="w-full h-full object-cover"/>
            </div>
            <div className="flex-1 px-4 py-3 flex flex-col justify-between min-w-0">
              <div className="flex justify-between gap-2">
                <div className="min-w-0">
                  <p className="font-bold text-[#0A0A0A] text-sm truncate">{item.name}</p>
                  <p className="text-xs text-[#6B6B6B] mt-0.5">{item.variant}</p>
                </div>
                <button onClick={() => onRemove(item.id)} className="text-[#C8C5C0] hover:text-red-400 transition-colors flex-shrink-0"><I.trash/></button>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-0 bg-[#F7F5F1] rounded-xl">
                  <button onClick={() => onUpdate(item.id,-1)} disabled={item.qty===1} className="w-8 h-8 flex items-center justify-center text-[#0A0A0A] disabled:opacity-30"><I.minus/></button>
                  <span className="w-6 text-center text-sm font-bold tabular-nums">{item.qty}</span>
                  <button onClick={() => onUpdate(item.id,1)} className="w-8 h-8 flex items-center justify-center text-[#0A0A0A]"><I.plus/></button>
                </div>
                <p className="font-black text-[#0A0A0A] text-sm tabular-nums">{fmt(item.price*item.qty)}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Summary */}
      <div className="space-y-3 lg:sticky lg:top-6">
        <SLabel>Resumen</SLabel>
        <div className="bg-white rounded-2xl shadow-[0_1px_6px_rgba(0,0,0,0.06)] p-5 space-y-3">
          {([[`Subtotal`,subtotal],[`IVA 16%`,iva]] as [string,number][]).map(([l,v])=>(
            <div key={l} className="flex justify-between text-sm text-[#6B6B6B]">
              <span>{l}</span><span className="tabular-nums">{fmt(v)}</span>
            </div>
          ))}
          <div className="flex justify-between text-sm text-[#6B6B6B]">
            <span>Casillero</span><span className="text-[#3DAA6B] font-bold">Gratis</span>
          </div>
          <div className="h-px bg-[#F0EDEA]"/>
          <div className="flex justify-between font-black text-[#0A0A0A] text-lg">
            <span>Total</span><span className="tabular-nums">{fmt(total)}</span>
          </div>
          <div className="bg-[#F7F5F1] rounded-xl px-3 py-2.5 flex items-center gap-2">
            <span className="text-[#6B6B6B]"><I.locker/></span>
            <p className="text-xs text-[#6B6B6B]">Recoge con <span className="font-semibold text-[#0A0A0A]">PIN en casillero</span> sin esperar fila.</p>
          </div>
          <button className="w-full h-[52px] bg-[#0A0A0A] text-white rounded-xl font-bold text-sm flex items-center justify-between px-5 active:scale-[0.98] transition-transform">
            <div className="flex items-center gap-2"><I.lock/><span>Confirmar y pagar</span></div>
            <span className="tabular-nums">{fmt(total)}</span>
          </button>
          <p className="text-center text-[10px] text-[#6B6B6B]">Cifrado SSL · Sin datos almacenados</p>
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// SCREEN: TRACKING
// ════════════════════════════════════════════════════════════════════════════════

type Stage = 0|1|2|3;
const STAGE_CFG = [
  { label:"En cola",    sub:"Tu pedido fue recibido",          color:"bg-[#C8B89A]", bar:"bg-[#C8B89A]", tag:"bg-[#F5EDE0] text-[#7A5C3A]", eta:8  },
  { label:"Preparando", sub:"El barista está en ello",         color:"bg-[#E8A838]", bar:"bg-[#E8A838]", tag:"bg-[#FEF3D0] text-[#7A4F00]", eta:4  },
  { label:"Listo",      sub:"Tu pedido está en el casillero",  color:"bg-[#3DAA6B]", bar:"bg-[#3DAA6B]", tag:"bg-[#D8F5E7] text-[#0E5C30]", eta:null },
  { label:"Recogido",   sub:"¡Que lo disfrutes!",              color:"bg-[#0A0A0A]", bar:"bg-[#0A0A0A]", tag:"bg-[#E8E6E2] text-[#0A0A0A]", eta:null },
];

function TrackingScreen() {
  const [stage, setStage] = useState<Stage>(1);
  const [pinShown, setPinShown] = useState(false);
  const [secs, setSecs] = useState(0);
  const cfg = STAGE_CFG[stage];
  const PIN = "3849";

  useEffect(() => {
    const eta = cfg.eta;
    if (!eta) return;
    setSecs(eta*60);
    const id = setInterval(() => setSecs(s => Math.max(0,s-1)), 1000);
    return () => clearInterval(id);
  }, [stage]);

  const pct = stage===0?0:stage===1?33:stage===2?66:100;

  return (
    <div className="space-y-6 max-w-2xl mx-auto">
      <div>
        <h2 className="text-2xl md:text-3xl font-black text-[#0A0A0A] tracking-tight">{cfg.sub}</h2>
        <p className="text-[#6B6B6B] text-sm mt-1">Pedido <span className="font-bold text-[#0A0A0A]">CC-482910</span> · Americano + Brownie Club</p>
      </div>

      <div>
        <div className="flex justify-between mb-3">
          {STAGE_CFG.map((s,i) => (
            <p key={i} className={`text-xs font-bold text-center flex-1 leading-tight transition-colors ${i===stage?"text-[#0A0A0A]":i<stage?"text-[#6B6B6B]":"text-[#D0CEC9]"}`}>{s.label}</p>
          ))}
        </div>
        <div className="relative h-2 bg-[#E8E6E2] rounded-full">
          <div className={`absolute left-0 top-0 h-full rounded-full transition-all duration-700 ${cfg.bar}`} style={{width:`${pct}%`}}/>
        </div>
        <div className="flex justify-between mt-2">
          {STAGE_CFG.map((_,i)=>{
            const done=i<stage,cur=i===stage;
            return (
              <div key={i} className="flex-1 flex justify-center">
                <div className={`w-7 h-7 rounded-full flex items-center justify-center text-white transition-all duration-300 ${done?"bg-[#0A0A0A]":cur?`${cfg.color} scale-110`:"bg-[#E8E6E2]"}`}>
                  {done?<I.check/>:<span className="text-[10px] font-black">{i+1}</span>}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {cfg.eta && (
          <div className="bg-white rounded-2xl shadow-[0_1px_6px_rgba(0,0,0,0.06)] p-5 flex flex-col items-center justify-center">
            <p className="text-[10px] font-bold tracking-[0.18em] uppercase text-[#6B6B6B] mb-3">Tiempo estimado</p>
            <p className="text-5xl font-black text-[#0A0A0A] tabular-nums">
              {Math.floor(secs/60)}:{String(secs%60).padStart(2,"0")}
            </p>
            <p className="text-[#6B6B6B] text-xs mt-2">minutos restantes</p>
          </div>
        )}

        <div className={`rounded-2xl p-5 ${stage===3?"bg-[#0A0A0A]":"bg-white shadow-[0_1px_6px_rgba(0,0,0,0.06)]"}`}>
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className={`text-[10px] font-bold tracking-[0.18em] uppercase mb-1 ${stage===3?"text-white/50":"text-[#6B6B6B]"}`}>Casillero</p>
              <p className={`text-2xl font-black ${stage===3?"text-white":"text-[#0A0A0A]"}`}>Casillero #7</p>
            </div>
            <span className={`px-3 py-1.5 rounded-full text-xs font-bold ${cfg.tag}`}>{cfg.label}</span>
          </div>
          <p className={`text-[10px] font-bold tracking-[0.18em] uppercase mb-3 ${stage===3?"text-white/50":"text-[#6B6B6B]"}`}>PIN de acceso</p>
          <div className="flex gap-2 mb-3">
            {PIN.split("").map((d,i)=>(
              <div key={i} className={`flex-1 h-12 rounded-xl flex items-center justify-center ${stage===3?"bg-white/10":"bg-[#F7F5F1]"}`}>
                <span className={`text-xl font-black ${stage===3?"text-white":stage>=2?"text-[#0A0A0A]":"text-[#C8C5C0]"}`}>
                  {stage>=2?(pinShown?d:"•":"•")}
                </span>
              </div>
            ))}
          </div>
          {stage>=2&&stage<3&&(
            <button onClick={()=>setPinShown(v=>!v)} className={`text-xs font-semibold underline underline-offset-2 ${stage===3?"text-white/50":"text-[#6B6B6B]"}`}>
              {pinShown?"Ocultar PIN":"Revelar PIN"}
            </button>
          )}
          {stage<2&&<p className="text-xs text-[#6B6B6B]">El PIN aparece cuando tu pedido esté listo.</p>}
        </div>
      </div>

      <div className="bg-white border border-[#E8E6E2] rounded-2xl p-4">
        <p className="text-[10px] font-bold tracking-[0.2em] uppercase text-[#6B6B6B] mb-3">Simular estado</p>
        <div className="grid grid-cols-4 gap-2">
          {STAGE_CFG.map((s,i)=>(
            <button key={i} onClick={()=>setStage(i as Stage)}
              className={`h-10 rounded-xl text-xs font-bold transition-all ${stage===i?`${s.color} text-white`:"bg-[#F7F5F1] text-[#6B6B6B]"}`}>
              {s.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// SCREEN: MEMBERSHIP
// ════════════════════════════════════════════════════════════════════════════════

function MembershipScreen() {
  const [state, setState] = useState<MemberState>("active");
  const available = state==="active", inactive=state==="inactive";

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div className="rounded-3xl overflow-hidden bg-[#0A0A0A]">
        <div className="px-6 pt-6 pb-5 relative">
          <div className="absolute top-0 right-0 w-48 h-48 rounded-full bg-white/5 translate-x-16 -translate-y-16 pointer-events-none"/>
          <div className="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-5">
            <div>
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-white"><I.coffee/></div>
                <span className="text-white/50 text-xs font-bold tracking-[0.2em] uppercase">The Club Coffee</span>
              </div>
              {inactive?(
                <>
                  <p className="text-white/50 text-xs font-semibold tracking-widest uppercase mb-1">Membresía Club</p>
                  <h2 className="text-white text-4xl font-black leading-none tracking-tight">$1<span className="text-xl text-white/50"> / café</span></h2>
                  <p className="text-white/50 text-sm mt-1">Un café al día, todos los días del mes</p>
                </>
              ):(
                <>
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-bold flex items-center gap-1.5 ${available?"bg-[#3DAA6B]/25 text-[#5DD68E]":"bg-white/10 text-white/50"}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${available?"bg-[#3DAA6B] animate-pulse":"bg-white/30"}`}/>
                      Socio activo
                    </span>
                  </div>
                  <p className="text-white font-black text-xl">Alex Rivera</p>
                  <p className="text-white/50 text-sm">Miembro desde agosto 2024 · 🔥 4 días de racha</p>
                </>
              )}
            </div>
            {!inactive&&(
              <div className={`rounded-2xl p-4 min-w-[200px] ${available?"bg-[#3DAA6B]/20 border border-[#3DAA6B]/30":"bg-white/6 border border-white/10"}`}>
                <p className={`font-black text-lg leading-tight ${available?"text-[#5DD68E]":"text-white/50"}`}>
                  {available?"¡Disponible hoy!":"Beneficio usado"}
                </p>
                <p className={`text-xs mt-1 ${available?"text-[#5DD68E]/70":"text-white/30"}`}>
                  {available?"Tu Americano por $1 MXN":"Vuelve mañana · Sáb 22 ago"}
                </p>
              </div>
            )}
          </div>
        </div>
        <div className="mx-5 h-px bg-white/8"/>
        <div className="px-6 py-3">
          {inactive?(
            <p className="text-white/40 text-xs">Desde <span className="text-white/70 font-bold">$29 MXN / mes</span> · Cancela cuando quieras</p>
          ):(
            <p className="text-white/40 text-xs">Renueva 1 sep 2025 · Cancela cuando quieras</p>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-4">
          {!inactive?(
            available?(
              <button className="w-full h-[52px] bg-[#0A0A0A] text-white rounded-xl font-bold text-sm flex items-center justify-between px-5 active:scale-[0.98] transition-transform shadow-[0_4px_14px_rgba(0,0,0,0.16)]">
                <div className="flex items-center gap-2"><span>☕</span><span>Pedir mi Americano</span></div>
                <span className="font-black">$1 MXN</span>
              </button>
            ):(
              <div className="bg-white rounded-2xl shadow-[0_1px_6px_rgba(0,0,0,0.06)] px-5 py-4 flex items-center gap-4">
                <div className="w-11 h-11 bg-[#F7F5F1] rounded-xl flex items-center justify-center flex-shrink-0 text-[#6B6B6B]"><I.lock/></div>
                <div>
                  <p className="font-bold text-[#0A0A0A] text-sm">Beneficio canjeado hoy</p>
                  <p className="text-[#6B6B6B] text-xs mt-0.5">Vuelve mañana · <span className="font-bold text-[#0A0A0A]">Sáb 22 ago</span></p>
                </div>
                <div className="ml-auto bg-[#F7F5F1] rounded-xl px-3 py-2"><p className="text-xs font-bold text-[#6B6B6B]">−23 h</p></div>
              </div>
            )
          ):(
            <>
              <div className="bg-[#F7F5F1] rounded-2xl px-4 py-4 space-y-2.5">
                {["1 Americano al día por $1 MXN","Sin fila — recoge con PIN","15% off en toda la carta","Cancela cuando quieras"].map(l=>(
                  <div key={l} className="flex items-center gap-2.5">
                    <div className="w-4 h-4 bg-[#0A0A0A] rounded-full flex items-center justify-center flex-shrink-0 text-white"><I.check/></div>
                    <p className="text-sm font-semibold text-[#0A0A0A]">{l}</p>
                  </div>
                ))}
              </div>
              <button onClick={()=>setState("active")} className="w-full h-[52px] bg-[#0A0A0A] text-white rounded-xl font-bold text-sm flex items-center justify-between px-5 active:scale-[0.98] transition-transform">
                <span>Unirme al Club</span><span className="font-black">$29 MXN / mes</span>
              </button>
              <p className="text-center text-xs text-[#6B6B6B]">Sin permanencia · 7 días gratis al inicio</p>
            </>
          )}

          {!inactive&&(
            <div className="bg-white rounded-2xl shadow-[0_1px_6px_rgba(0,0,0,0.06)] overflow-hidden">
              <div className="px-4 pt-4 pb-1"><SLabel>Historial este mes</SLabel></div>
              {[{date:"Lun 18 ago",branch:"Condesa"},{date:"Mar 19 ago",branch:"Roma"},{date:"Mié 20 ago",branch:"Condesa"},{date:"Jue 21 ago",branch:"Polanco"}].map((h,i)=>(
                <div key={i} className="flex items-center justify-between px-4 py-3 border-t border-[#F7F5F1]">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-[#F7F5F1] rounded-lg flex items-center justify-center text-[#6B6B6B]"><I.coffee/></div>
                    <div><p className="text-sm font-semibold text-[#0A0A0A]">Americano</p><p className="text-xs text-[#6B6B6B]">{h.date} · {h.branch}</p></div>
                  </div>
                  <span className="text-sm font-black text-[#0A0A0A]">$1 MXN</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="space-y-3">
          <SLabel>{inactive?"Beneficios del Club":"Tus beneficios"}</SLabel>
          <div className="grid grid-cols-2 gap-3">
            {[
              {icon:"☕",title:"1 café al día",desc:"Americano por $1 todos los días"},
              {icon:"⚡",title:"Sin fila",desc:"Acceso prioritario a casilleros"},
              {icon:"🎁",title:"15% descuento",desc:"En toda la carta para socios"},
              {icon:"📍",title:"3 sucursales",desc:"Condesa, Roma Norte, Polanco"},
            ].map(p=>(
              <div key={p.title} className={`bg-white rounded-2xl p-3.5 shadow-[0_1px_6px_rgba(0,0,0,0.06)] relative ${inactive?"opacity-60":""}` }>
                <span className="text-xl mb-2 block">{p.icon}</span>
                <p className="font-bold text-[#0A0A0A] text-sm mb-1">{p.title}</p>
                <p className="text-[#6B6B6B] text-xs leading-snug">{p.desc}</p>
                <div className={`absolute top-2.5 right-2.5 ${inactive?"text-[#C8C5C0]":"text-[#3DAA6B]"}`}>
                  {inactive?<I.lock/>:<I.check/>}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-white border border-[#E8E6E2] rounded-2xl p-4">
        <p className="text-[10px] font-bold tracking-[0.2em] uppercase text-[#6B6B6B] mb-3">Simular estado</p>
        <div className="flex gap-2">
          {([["active","☕ Disponible"],["used","✓ Usado"],["inactive","🔒 Sin membresía"]] as [MemberState,string][]).map(([s,l])=>(
            <button key={s} onClick={()=>setState(s)}
              className={`flex-1 h-10 rounded-xl text-xs font-bold transition-all ${state===s?"bg-[#0A0A0A] text-white":"bg-[#F7F5F1] text-[#6B6B6B]"}`}>
              {l}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// SCREEN: STAFF
// ════════════════════════════════════════════════════════════════════════════════

function useTick() { const [,s]=useState(0); useEffect(()=>{const id=setInterval(()=>s(t=>t+1),30000);return()=>clearInterval(id);},[]);}

function StaffScreen() {
  const [orders, setOrders] = useState<StaffOrder[]>(STAFF_ORDERS);
  const [filter, setFilter] = useState<OrderStatus|"all">("all");
  const [lockerTarget, setLockerTarget] = useState<string|null>(null);
  const [lastSync, setLastSync] = useState(new Date());
  useTick();

  const usedLockers = orders.filter(o=>o.locker!==null).map(o=>o.locker as number);
  const advance = (id:string) => setOrders(p=>p.map(o=>{if(o.id!==id)return o;const n=STATUS_CFG[o.status].next;return n?{...o,status:n}:o;}));
  const assignLocker = (id:string,n:number) => { setOrders(p=>p.map(o=>o.id===id?{...o,locker:n}:o)); setLockerTarget(null); };

  type FT = OrderStatus|"all";
  const counts: Record<FT,number> = {
    all:orders.length, queued:orders.filter(o=>o.status==="queued").length,
    preparing:orders.filter(o=>o.status==="preparing").length,
    ready:orders.filter(o=>o.status==="ready").length,
    collected:orders.filter(o=>o.status==="collected").length,
  };

  const visible = (filter==="all"?orders:orders.filter(o=>o.status===filter))
    .slice().sort((a,b)=>{
      const pr:Record<OrderStatus,number>={queued:0,preparing:1,ready:2,collected:3};
      return pr[a.status]!==pr[b.status]?pr[a.status]-pr[b.status]:a.placedAt.getTime()-b.placedAt.getTime();
    });

  const urgentCount = orders.filter(o=>Math.floor((Date.now()-o.placedAt.getTime())/60000)>=8&&o.status!=="collected").length;
  const revenue = orders.filter(o=>o.status==="collected").reduce((s,o)=>s+o.total,0);

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-3 md:grid-cols-6 gap-3">
        {[
          {l:"Activos",v:orders.filter(o=>o.status!=="collected").length},
          {l:"Vendido",v:fmtS(revenue)+" MXN"},
          {l:"Urgentes",v:urgentCount},
          {l:"En cola",v:counts.queued},
          {l:"Preparando",v:counts.preparing},
          {l:"Listos",v:counts.ready},
        ].map(({l,v})=>(
          <div key={l} className="bg-white rounded-xl px-3 py-3 border border-[#F0EDEA]">
            <p className="text-[9px] font-bold tracking-[0.15em] uppercase text-[#6B6B6B] mb-0.5">{l}</p>
            <p className="text-lg font-black text-[#0A0A0A] tabular-nums leading-none">{v}</p>
          </div>
        ))}
      </div>

      <div className="flex gap-2 flex-wrap">
        {([["all","Todos"],["queued","En cola"],["preparing","Preparando"],["ready","Listo"],["collected","Recogido"]] as [FT,string][]).map(([s,l])=>{
          const cfg = s!=="all"?STATUS_CFG[s as OrderStatus]:null;
          return (
            <button key={s} onClick={()=>setFilter(s)}
              className={`flex items-center gap-1.5 h-8 px-3 rounded-lg text-xs font-bold transition-all ${filter===s?"bg-[#0A0A0A] text-white":"bg-white border border-[#E8E6E2] text-[#6B6B6B]"}`}>
              {cfg&&<span className={`w-2 h-2 rounded-full ${filter===s?"bg-white/50":cfg.dot}`}/>}
              {l}
              <span className={`font-black ${filter===s?"text-white/70":"text-[#0A0A0A]"}`}>{counts[s]}</span>
            </button>
          );
        })}
        <div className="ml-auto flex items-center gap-2 text-xs text-[#6B6B6B]">
          <span>{lastSync.toLocaleTimeString("es-MX",{hour:"2-digit",minute:"2-digit"})}</span>
          <button onClick={()=>setLastSync(new Date())} className="w-8 h-8 bg-white border border-[#E8E6E2] rounded-lg flex items-center justify-center"><I.refresh/></button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-3">
        {visible.map(order=>{
          const cfg = STATUS_CFG[order.status];
          const mins = Math.floor((Date.now()-order.placedAt.getTime())/60000);
          const urgent = mins>=8&&order.status!=="collected";
          const collected = order.status==="collected";
          return (
            <div key={order.id} className={`bg-white rounded-2xl overflow-hidden border transition-all ${urgent&&!collected?"border-[#E8A838]":"border-[#F0EDEA]"}`}>
              {urgent&&!collected&&<div className="h-1 bg-[#E8A838]"/>}
              <div className="p-4">
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-black text-[#0A0A0A] text-sm">{order.id}</span>
                      {order.isMember&&<span className="flex items-center gap-0.5 bg-[#0A0A0A] text-white text-[9px] font-bold px-1.5 py-0.5 rounded-full"><I.star/>SOCIO</span>}
                      {urgent&&!collected&&<span className="text-[#7A4F00] text-[10px] font-bold flex items-center gap-1"><I.alert/>Tardando</span>}
                    </div>
                    <p className="text-xs text-[#6B6B6B] font-semibold mt-0.5">{order.customer}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold flex items-center gap-1.5 ${cfg.bg} ${cfg.color}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot} ${order.status==="preparing"?"animate-pulse":""}`}/>
                      {cfg.label}
                    </span>
                    <div className={`flex items-center gap-1 ${urgent&&!collected?"text-[#E8A838]":"text-[#6B6B6B]"}`}>
                      <I.clock/><span className="text-[10px] font-semibold">{elapsed(order.placedAt)}</span>
                    </div>
                  </div>
                </div>
                <p className="text-xs text-[#0A0A0A] font-semibold mb-0.5 truncate">
                  {order.items.map(i=>`${i.qty>1?`${i.qty}× `:""  }${i.name}`).join(", ")}
                </p>
                <p className="text-[11px] text-[#6B6B6B] truncate">{order.items.map(i=>i.variant).join(" · ")}</p>
              </div>

              {!collected&&(
                <div className={`px-4 py-3 border-t ${cfg.border} bg-[#FAFAF9] flex items-center gap-2`}>
                  <button onClick={()=>setLockerTarget(order.id)}
                    className={`flex items-center gap-1.5 h-9 px-3 rounded-lg text-xs font-bold flex-shrink-0 transition-all ${order.locker?"bg-[#0A0A0A] text-white":"bg-white border border-[#E8E6E2] text-[#6B6B6B]"}`}>
                    <I.locker/>{order.locker?`#${order.locker}`:"Casillero"}
                  </button>
                  {order.locker&&(
                    <div className="flex items-center gap-1.5 h-9 px-3 bg-white border border-[#E8E6E2] rounded-lg">
                      <span className="text-[10px] text-[#6B6B6B] font-semibold">PIN</span>
                      <span className="text-xs font-black text-[#0A0A0A] font-mono tracking-widest">{order.pin}</span>
                    </div>
                  )}
                  {cfg.next&&(
                    <button onClick={()=>advance(order.id)}
                      className={`flex-1 h-9 rounded-lg text-xs font-bold flex items-center justify-center gap-1 active:scale-[0.98] transition-all ${cfg.nextColor}`}>
                      {cfg.nextLabel}<I.chevron/>
                    </button>
                  )}
                </div>
              )}
              {collected&&(
                <div className="px-4 py-2.5 border-t border-[#F0EDEA] bg-[#FAFAF9] flex items-center justify-between">
                  <div className="flex items-center gap-1.5 text-[#6B6B6B]"><I.check/><span className="text-[10px] font-semibold">Recogido · #{order.locker}</span></div>
                  <span className="text-[10px] font-black text-[#0A0A0A]">{fmt(order.total)}</span>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {lockerTarget&&(
        <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center p-4 bg-black/40 backdrop-blur-sm" onClick={()=>setLockerTarget(null)}>
          <div className="bg-white rounded-3xl p-5 w-full max-w-sm shadow-2xl" onClick={e=>e.stopPropagation()}>
            <div className="w-10 h-1 bg-[#E8E6E2] rounded-full mx-auto mb-4"/>
            <p className="text-[10px] font-bold tracking-[0.18em] uppercase text-[#6B6B6B] mb-4">Asignar casillero</p>
            <div className="grid grid-cols-6 gap-2 mb-4">
              {Array.from({length:12},(_,i)=>i+1).map(n=>{
                const order = orders.find(o=>o.id===lockerTarget);
                const taken = usedLockers.includes(n)&&n!==order?.locker;
                const sel = order?.locker===n;
                return (
                  <button key={n} onClick={()=>!taken&&assignLocker(lockerTarget,n)} disabled={taken}
                    className={`h-12 rounded-xl font-black text-sm flex items-center justify-center transition-all ${sel?"bg-[#0A0A0A] text-white":taken?"bg-[#F7F5F1] text-[#D0CEC9] cursor-not-allowed":"bg-[#F7F5F1] text-[#0A0A0A] hover:bg-[#E8E6E2] active:scale-95"}`}>
                    {sel?<I.check/>:n}
                  </button>
                );
              })}
            </div>
            <p className="text-xs text-[#6B6B6B] text-center">{usedLockers.length} de 12 casilleros ocupados</p>
          </div>
        </div>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// ROOT APP
// ════════════════════════════════════════════════════════════════════════════════

export default function App() {
  const [screen, setScreen] = useState<Screen>("menu");
  const [cart, setCart] = useState<CartItem[]>([]);

  const cartCount = cart.reduce((s,i)=>s+i.qty,0);

  function addToCart(p: Product) {
    setCart(prev=>{
      const ex = prev.find(i=>i.id===p.id);
      if(ex) return prev.map(i=>i.id===p.id?{...i,qty:i.qty+1}:i);
      return [...prev,{id:p.id,name:p.name,variant:"Regular",price:p.price,qty:1,image:p.image}];
    });
  }

  function updateCart(id:string,delta:number) {
    setCart(prev=>prev.map(i=>i.id===id?{...i,qty:Math.max(1,i.qty+delta)}:i));
  }

  function removeFromCart(id:string) {
    setCart(prev=>prev.filter(i=>i.id!==id));
  }

  const titles: Record<Screen,string> = {
    menu:"Menú", cart:"Mi Carrito", tracking:"Tu Pedido", membership:"Club Coffee", staff:"Estación Staff"
  };

  return (
    <div className="min-h-screen bg-[#F7F5F1]" style={{fontFamily:"'Inter',system-ui,sans-serif"}}>

      {/* Desktop sidebar */}
      <aside className="hidden md:flex fixed left-0 top-0 bottom-0 w-56 lg:w-64 bg-white border-r border-[#E8E6E2] flex-col z-40">
        <div className="px-5 py-6 border-b border-[#E8E6E2]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 bg-[#0A0A0A] rounded-lg flex items-center justify-center text-white">
              <I.coffee/>
            </div>
            <div>
              <p className="font-black text-[#0A0A0A] text-sm leading-none">The Club</p>
              <p className="font-black text-[#0A0A0A] text-sm leading-none">Coffee</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map(({id,label,Icon})=>{
            const active = screen===id;
            return (
              <button key={id} onClick={()=>setScreen(id)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition-all ${active?"bg-[#0A0A0A] text-white":"text-[#6B6B6B] hover:bg-[#F7F5F1] hover:text-[#0A0A0A]"}`}>
                <Icon/>
                {label}
                {id==="cart"&&cartCount>0&&(
                  <span className={`ml-auto text-[10px] font-black w-5 h-5 rounded-full flex items-center justify-center ${active?"bg-white text-[#0A0A0A]":"bg-[#0A0A0A] text-white"}`}>{cartCount}</span>
                )}
              </button>
            );
          })}
        </nav>

        <div className="px-5 py-4 border-t border-[#E8E6E2]">
          <div className="flex items-center gap-2 text-[#6B6B6B]">
            <I.pin/>
            <span className="text-xs font-semibold">Sucursal Condesa</span>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="md:ml-56 lg:ml-64 flex flex-col min-h-screen">
        <header className="sticky top-0 z-30 bg-[#F7F5F1]/90 backdrop-blur-md border-b border-[#E8E6E2]">
          <div className="px-4 md:px-8 h-14 flex items-center justify-between">
            <div className="flex items-center gap-2 md:hidden">
              <div className="w-7 h-7 bg-[#0A0A0A] rounded-lg flex items-center justify-center text-white scale-90"><I.coffee/></div>
              <span className="font-black text-[#0A0A0A] text-sm">The Club Coffee</span>
            </div>
            <h1 className="hidden md:block text-lg font-black text-[#0A0A0A] tracking-tight">{titles[screen]}</h1>
            <div className="flex items-center gap-2">
              <button onClick={()=>setScreen("cart")}
                className="relative w-9 h-9 bg-white border border-[#E8E6E2] rounded-xl flex items-center justify-center text-[#0A0A0A] shadow-sm">
                <I.cart/>
                {cartCount>0&&(
                  <span className="absolute -top-1 -right-1 w-4 h-4 bg-[#0A0A0A] text-white text-[9px] font-black rounded-full flex items-center justify-center">{cartCount}</span>
                )}
              </button>
            </div>
          </div>
        </header>

        <main className="flex-1 px-4 md:px-8 py-6 pb-24 md:pb-8">
          {screen==="menu"       && <MenuScreen      onAddToCart={addToCart}/>}
          {screen==="cart"       && <CartScreen      cart={cart} onUpdate={updateCart} onRemove={removeFromCart}/>}
          {screen==="tracking"   && <TrackingScreen  />}
          {screen==="membership" && <MembershipScreen/>}
          {screen==="staff"      && <StaffScreen     />}
        </main>
      </div>

      {/* Mobile bottom nav */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-[#E8E6E2]">
        <div className="flex">
          {NAV.map(({id,label,Icon})=>{
            const active = screen===id;
            return (
              <button key={id} onClick={()=>setScreen(id)}
                className={`flex-1 flex flex-col items-center justify-center py-2.5 gap-1 transition-colors ${active?"text-[#0A0A0A]":"text-[#C8C5C0]"}`}>
                <div className="relative">
                  <Icon/>
                  {id==="cart"&&cartCount>0&&(
                    <span className="absolute -top-1.5 -right-1.5 w-4 h-4 bg-[#0A0A0A] text-white text-[9px] font-black rounded-full flex items-center justify-center">{cartCount}</span>
                  )}
                </div>
                <span className="text-[10px] font-semibold">{label}</span>
                {active&&<div className="w-1 h-1 bg-[#0A0A0A] rounded-full"/>}
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
