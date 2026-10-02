/**
 * CATÁLOGO — filtros, render de tarjetas y panel de detalle.
 * Para añadir una categoría nueva (ej. "accesorios"):
 *  1. Crea data/accesorios.js siguiendo el mismo formato que ropa.js
 *  2. Enlázalo en index.html (<script src="data/accesorios.js">)
 *  3. Agrégalo al arreglo TODOS_LOS_PRODUCTOS abajo
 *  4. Agrega un botón en el <nav class="category-nav"> del HTML
 */
const TODOS_LOS_PRODUCTOS = [
  ...PRODUCTOS_ROPA,
  ...PRODUCTOS_PERFUMES,
  ...PRODUCTOS_BOLSOS
];

const estado = {
  genero: "todos",     // "todos" | "hombre" | "mujer"
  categoria: "todos"   // "todos" | "ropa" | "perfumes" | "bolsos" | "accesorios"
};

function productosFiltrados() {
  return TODOS_LOS_PRODUCTOS.filter(p => {
    const okGenero = estado.genero === "todos" || p.genero === estado.genero || p.genero === "unisex";
    const okCategoria = estado.categoria === "todos" || p.categoria === estado.categoria;
    return okGenero && okCategoria;
  });
}

function renderGrid() {
  const grid = document.getElementById("product-grid");
  const lista = productosFiltrados();
  const contador = document.getElementById("grid-count");
  contador.textContent = `${lista.length} artículo${lista.length === 1 ? "" : "s"}`;

  if (lista.length === 0) {
    grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1">
      <h3>No hay productos en esta sección todavía</h3>
      <p>Prueba con otra categoría o vuelve pronto.</p>
    </div>`;
    return;
  }

  grid.innerHTML = lista.map(p => `
    <div class="card" data-id="${p.id}">
      <div class="card-inner">
        <div class="card-face card-front">
          ${!p.stock ? '<span class="badge-agotado">Agotado</span>' : ''}
          <div class="thumb"><img src="${imagenProducto(p)}" alt="${p.nombre}" loading="lazy"></div>
          <div class="info">
            <div class="cat">${etiquetaCategoria(p.categoria)} · ${p.genero}</div>
            <h3>${p.nombre}</h3>
            <div class="price">${formatearPrecio(p.precio)}</div>
          </div>
        </div>
        <div class="card-face card-back">
          <div class="label-head">
            <span>FICHA TÉCNICA</span>
            <span>${p.id.toUpperCase()}</span>
          </div>
          <div>
            <h4>${p.nombre}</h4>
            <ul class="spec-list">
              ${Object.entries(p.especificaciones).slice(0, 4).map(([k, v]) => `
                <li><span>${k}</span><span>${v}</span></li>
              `).join("")}
            </ul>
          </div>
          <div class="actions">
            <button class="btn btn-light" data-action="detalle" data-id="${p.id}">Ver detalle</button>
            <button class="btn" data-action="agregar" data-id="${p.id}" ${!p.stock ? "disabled" : ""}>+ Carrito</button>
          </div>
        </div>
      </div>
    </div>
  `).join("");
}

function abrirDetalle(id) {
  const p = TODOS_LOS_PRODUCTOS.find(x => x.id === id);
  if (!p) return;
  const panel = document.getElementById("panel-detalle");
  const body = document.getElementById("panel-detalle-body");

  body.innerHTML = `
    <div class="pd-image"><img src="${imagenProducto(p)}" alt="${p.nombre}"></div>
    <div class="pd-cat">${etiquetaCategoria(p.categoria)} · ${p.genero}</div>
    <h2 class="pd-title">${p.nombre}</h2>
    <div class="pd-price">${formatearPrecio(p.precio)}</div>
    <p class="pd-desc">${p.descripcion}</p>
    <ul class="pd-specs">
      ${Object.entries(p.especificaciones).map(([k, v]) => `
        <li><span>${k}</span><span>${v}</span></li>
      `).join("")}
    </ul>
    ${p.stock ? `
      <div class="pd-qty">
        <button id="pd-menos">−</button>
        <span id="pd-cantidad">1</span>
        <button id="pd-mas">+</button>
      </div>
      <div class="pd-actions">
        <button class="btn btn-full" id="pd-agregar">Añadir al carrito</button>
      </div>
      <div class="pd-actions" style="margin-top:10px">
        <button class="btn btn-outline btn-full" id="pd-whatsapp">Consultar por WhatsApp</button>
      </div>
    ` : `<p style="color:var(--danger); font-weight:600;">Agotado por ahora</p>`}
  `;

  if (p.stock) {
    let cantidad = 1;
    document.getElementById("pd-menos").onclick = () => {
      cantidad = Math.max(1, cantidad - 1);
      document.getElementById("pd-cantidad").textContent = cantidad;
    };
    document.getElementById("pd-mas").onclick = () => {
      cantidad += 1;
      document.getElementById("pd-cantidad").textContent = cantidad;
    };
    document.getElementById("pd-agregar").onclick = () => {
      agregarAlCarrito(p.id, cantidad);
      mostrarToast(`${p.nombre} añadido al carrito`);
    };
    document.getElementById("pd-whatsapp").onclick = () => {
      abrirWhatsAppConsulta(p);
    };
  }

  abrirPanel(panel);
}

function abrirPanel(panel) {
  document.getElementById("scrim").classList.add("open");
  panel.classList.add("open");
}
function cerrarPaneles() {
  document.getElementById("scrim").classList.remove("open");
  document.querySelectorAll(".panel").forEach(p => p.classList.remove("open"));
}

function abrirWhatsAppConsulta(p) {
  const msg = `Hola, estoy interesado en este producto:\n*${p.nombre}* (${formatearPrecio(p.precio)})\n\nID: ${p.id}`;
  window.open(`https://wa.me/${CONFIG.whatsappNumero}?text=${encodeURIComponent(msg)}`, "_blank");
}

/* ---- eventos de filtro y delegación de clicks en el grid ---- */
document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("nombre-tienda").textContent = CONFIG.nombreTienda;
  document.title = CONFIG.nombreTienda + " — Catálogo";
  document.getElementById("hero-eslogan").textContent = CONFIG.eslogan;

  document.querySelectorAll(".gender-toggle button").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".gender-toggle button").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      estado.genero = btn.dataset.genero;
      renderGrid();
    });
  });

  document.querySelectorAll(".category-nav button").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".category-nav button").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      estado.categoria = btn.dataset.categoria;
      renderGrid();
    });
  });

  document.getElementById("product-grid").addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-action]");
    if (!btn) return;
    const id = btn.dataset.id;
    if (btn.dataset.action === "detalle") abrirDetalle(id);
    if (btn.dataset.action === "agregar") {
      agregarAlCarrito(id, 1);
      const p = TODOS_LOS_PRODUCTOS.find(x => x.id === id);
      mostrarToast(`${p.nombre} añadido al carrito`);
    }
  });

  document.getElementById("scrim").addEventListener("click", cerrarPaneles);
  document.querySelectorAll(".panel-close").forEach(b => b.addEventListener("click", cerrarPaneles));

  renderGrid();
  renderCarrito();
});
