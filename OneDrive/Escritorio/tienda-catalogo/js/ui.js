/**
 * UTILIDADES DE INTERFAZ
 * generarPlaceholder(): crea una imagen de marcador de posición en SVG
 * (sin depender de internet) mientras no haya fotos reales del producto.
 * Cuando tengas fotos reales, simplemente llena el campo `img` en los
 * archivos de data/*.js con la ruta o URL de la imagen y se usará esa.
 */
function generarPlaceholder(nombre, color) {
  const inicial = nombre.trim().charAt(0).toUpperCase();
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="400" height="500" viewBox="0 0 400 500">
      <rect width="400" height="500" fill="${color || '#EDE9DE'}"/>
      <text x="50%" y="52%" font-family="Georgia, serif" font-size="120"
        fill="rgba(33,31,28,0.18)" text-anchor="middle" dominant-baseline="middle">${inicial}</text>
    </svg>`;
  return "data:image/svg+xml;base64," + btoa(unescape(encodeURIComponent(svg)));
}

function imagenProducto(producto) {
  return producto.img && producto.img.length > 0
    ? producto.img
    : generarPlaceholder(producto.nombre, producto.colorPlaceholder);
}

function mostrarToast(mensaje) {
  let toast = document.getElementById("toast");
  if (!toast) {
    toast = document.createElement("div");
    toast.id = "toast";
    toast.className = "toast";
    document.body.appendChild(toast);
  }
  toast.textContent = mensaje;
  toast.classList.add("show");
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => toast.classList.remove("show"), 2200);
}

function etiquetaCategoria(cat) {
  const nombres = { ropa: "Ropa", perfumes: "Perfumes", bolsos: "Bolsos", accesorios: "Accesorios" };
  return nombres[cat] || cat;
}
