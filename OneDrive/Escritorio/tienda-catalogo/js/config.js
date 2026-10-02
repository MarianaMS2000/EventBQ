/**
 * CONFIGURACIÓN DE LA TIENDA
 * Edita estos valores para personalizar la marca sin tocar el resto del código.
 */
const CONFIG = {
  // Nombre que aparece en el header y el título de la pestaña
  nombreTienda: "LUME",

  // Frase corta que aparece en el hero de inicio
  eslogan: "Catálogo digital de ropa, perfumes y accesorios.",

  // Número de WhatsApp de la marca en formato internacional SIN + ni espacios
  // Ejemplo: 573001234567  (57 = Colombia, luego el número a 10 dígitos)
  whatsappNumero: "573024465664",

  // Moneda usada para formatear precios
  moneda: "COP",
  local: "es-CO",

  // ¿Ya tienes pasarela de pago conectada (Wompi/ePayco)?
  // Déjalo en false mientras el flujo sea "pedir por WhatsApp".
  // Cuando integres el backend de pagos, cambia esto a true
  // y completa la función procesarPagoConTarjeta() en cart.js
  pagoDirectoActivo: false
};

function formatearPrecio(numero) {
  return new Intl.NumberFormat(CONFIG.local, {
    style: "currency",
    currency: CONFIG.moneda,
    maximumFractionDigits: 0
  }).format(numero);
}
