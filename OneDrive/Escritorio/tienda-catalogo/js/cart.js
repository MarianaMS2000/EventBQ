/**
 * CARRITO DE COMPRAS
 * Se guarda en localStorage del navegador, así que persiste aunque
 * la persona cierre y vuelva a abrir la página.
 *
 * Flujo actual: "Finalizar pedido" arma un mensaje con el resumen
 * de la compra y lo envía por WhatsApp a CONFIG.whatsappNumero.
 *
 * Cuando tengan la pasarela de pago (Wompi/ePayco) lista, reemplacen
 * la función finalizarPedido() por procesarPagoConTarjeta(), que ya
 * queda esbozada abajo con el punto exacto de integración.
 */
const CARRITO_KEY = "tienda_carrito_v1";

function obtenerCarrito() {
  try {
    return JSON.parse(localStorage.getItem(CARRITO_KEY)) || [];
  } catch {
    return [];
  }
}

function guardarCarrito(carrito) {
  localStorage.setItem(CARRITO_KEY, JSON.stringify(carrito));
}

function agregarAlCarrito(id, cantidad = 1) {
  const carrito = obtenerCarrito();
  const existente = carrito.find(item => item.id === id);
  if (existente) {
    existente.cantidad += cantidad;
  } else {
    carrito.push({ id, cantidad });
  }
  guardarCarrito(carrito);
  renderCarrito();
}

function actualizarCantidad(id, delta) {
  const carrito = obtenerCarrito();
  const item = carrito.find(i => i.id === id);
  if (!item) return;
  item.cantidad += delta;
  const nuevo = item.cantidad <= 0 ? carrito.filter(i => i.id !== id) : carrito;
  guardarCarrito(nuevo);
  renderCarrito();
}

function quitarDelCarrito(id) {
  guardarCarrito(obtenerCarrito().filter(i => i.id !== id));
  renderCarrito();
}

function detalleCarrito() {
  return obtenerCarrito().map(item => {
    const producto = TODOS_LOS_PRODUCTOS.find(p => p.id === item.id);
    return producto ? { ...producto, cantidad: item.cantidad } : null;
  }).filter(Boolean);
}

function totalCarrito() {
  return detalleCarrito().reduce((sum, p) => sum + p.precio * p.cantidad, 0);
}

function renderCarrito() {
  const items = detalleCarrito();
  const cont = document.getElementById("cart-count");
  const totalItems = items.reduce((s, p) => s + p.cantidad, 0);
  cont.textContent = totalItems;
  cont.style.display = totalItems > 0 ? "flex" : "none";

  const body = document.getElementById("cart-body");
  const summary = document.getElementById("cart-summary");

  if (items.length === 0) {
    body.innerHTML = `<div class="cart-empty">Tu carrito está vacío</div>`;
    summary.style.display = "none";
    return;
  }

  summary.style.display = "block";
  body.innerHTML = items.map(p => `
    <div class="cart-item">
      <img src="${imagenProducto(p)}" alt="${p.nombre}">
      <div class="ci-body">
        <div class="cat">${etiquetaCategoria(p.categoria)}</div>
        <h4>${p.nombre}</h4>
        <div class="ci-row">
          <div class="ci-qty">
            <button data-menos="${p.id}">−</button>
            <span>${p.cantidad}</span>
            <button data-mas="${p.id}">+</button>
          </div>
          <strong>${formatearPrecio(p.precio * p.cantidad)}</strong>
        </div>
        <button class="ci-remove" data-quitar="${p.id}">Quitar</button>
      </div>
    </div>
  `).join("");

  document.getElementById("cart-total").textContent = formatearPrecio(totalCarrito());
}

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("cart-body").addEventListener("click", (e) => {
    if (e.target.dataset.mas) actualizarCantidad(e.target.dataset.mas, 1);
    if (e.target.dataset.menos) actualizarCantidad(e.target.dataset.menos, -1);
    if (e.target.dataset.quitar) quitarDelCarrito(e.target.dataset.quitar);
  });

  document.getElementById("btn-abrir-carrito").addEventListener("click", () => {
    abrirPanel(document.getElementById("panel-carrito"));
  });

  document.getElementById("btn-finalizar").addEventListener("click", finalizarPedido);
});

function finalizarPedido() {
  const items = detalleCarrito();
  if (items.length === 0) return;

  // ---- PUNTO DE INTEGRACIÓN DE PAGO ----
  // Si CONFIG.pagoDirectoActivo es true, aquí se llamaría a
  // procesarPagoConTarjeta(items, totalCarrito()) en vez de WhatsApp.
  if (CONFIG.pagoDirectoActivo) {
    procesarPagoConTarjeta(items, totalCarrito());
    return;
  }

  const lineas = items.map(p =>
    `• ${p.nombre} x${p.cantidad} — ${formatearPrecio(p.precio * p.cantidad)}`
  ).join("\n");

  const mensaje =
    `Hola, quiero confirmar este pedido:\n\n${lineas}\n\n` +
    `*Total: ${formatearPrecio(totalCarrito())}*\n\n` +
    `Quedo atento(a) para coordinar el pago y el envío.`;

  window.open(`https://wa.me/${CONFIG.whatsappNumero}?text=${encodeURIComponent(mensaje)}`, "_blank");
}

/**
 * Esqueleto para cuando conecten Wompi o ePayco.
 * Normalmente esto abre el widget de la pasarela (checkout.js de Wompi)
 * y en el backend (que deben crear aparte, esto NO se puede hacer
 * de forma segura solo con archivos estáticos) se confirma el pago
 * antes de descontar el stock y notificar al vendedor.
 */
function procesarPagoConTarjeta(items, total) {
  alert("Aquí se abriría el checkout de la pasarela de pago (Wompi/ePayco) una vez esté configurada.");
}
