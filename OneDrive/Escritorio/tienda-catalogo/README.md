# Catálogo digital — guía rápida

## Estructura del proyecto
```
tienda-catalogo/
├── index.html          → página única, arma todo el sitio
├── css/
│   └── style.css        → colores, tipografías, todo el diseño
├── js/
│   ├── config.js         → nombre de la tienda, número de WhatsApp, moneda
│   ├── ui.js              → helpers (imágenes placeholder, avisos)
│   ├── catalog.js         → filtros, tarjetas de producto, panel de detalle
│   └── cart.js            → carrito, checkout por WhatsApp
└── data/
    ├── ropa.js            → productos de ropa
    ├── perfumes.js        → productos de perfumes
    └── bolsos.js          → productos de bolsos
```

## Cómo añadir un producto nuevo
Abre el archivo de la categoría correspondiente en `data/` y copia un bloque
completo `{ ... }`, cámbiale el `id` (debe ser único) y los datos. No necesitas
tocar ningún otro archivo. Ejemplo mínimo:

```js
{
  id: "ropa-007",
  nombre: "Chaqueta bomber",
  categoria: "ropa",
  genero: "hombre",
  precio: 199000,
  stock: true,
  img: "",                 // deja "" para usar un color de marcador automático
  colorPlaceholder: "#211F1C",
  descripcion: "Chaqueta bomber en nylon con forro interno.",
  especificaciones: {
    "Material": "Nylon / poliéster",
    "Tallas": "S, M, L, XL"
  }
}
```

Para usar una **foto real**, sube la imagen a la carpeta `img/` del proyecto
y pon la ruta en el campo `img`, por ejemplo: `img: "img/chaqueta-bomber.jpg"`.

## Cómo añadir una categoría nueva (ej. "accesorios")
1. Crea `data/accesorios.js` copiando la estructura de `data/ropa.js`
   (cambia `PRODUCTOS_ROPA` por `PRODUCTOS_ACCESORIOS`).
2. En `index.html`, agrega antes de `catalog.js`:
   `<script src="data/accesorios.js"></script>`
3. En `js/catalog.js`, agrega `...PRODUCTOS_ACCESORIOS` al arreglo
   `TODOS_LOS_PRODUCTOS`.
4. En `index.html`, dentro de `<nav class="category-nav">`, agrega:
   `<button data-categoria="accesorios">Accesorios</button>`

## Personalizar marca
Todo esto se edita en **un solo lugar**: `js/config.js`
- `nombreTienda` → nombre que aparece en el header
- `whatsappNumero` → número de WhatsApp de la marca (formato: `57` + 10 dígitos, sin `+` ni espacios)
- `eslogan` → frase del hero

## Cómo probarlo en tu computador
No necesitas instalar nada. Opción simple: doble clic en `index.html` y se
abre en el navegador. (Algunos navegadores restringen `localStorage` en
`file://`; si el carrito no guarda, usa la opción de abajo).

Opción recomendada (evita ese problema): con Python instalado, desde la
carpeta del proyecto:
```
python3 -m http.server 8000
```
y abre `http://localhost:8000` en el navegador.

## Cómo publicarlo gratis (Vercel)
1. Crea una cuenta gratis en https://vercel.com
2. Arrastra la carpeta `tienda-catalogo` completa en "Add New Project" →
   "Deploy" (o sube el proyecto a un repositorio de GitHub y conéctalo).
3. Vercel te da un link tipo `tu-tienda.vercel.app` que ya funciona para
   cualquiera que lo abra — eso es todo lo que necesitas para compartir el
   catálogo por WhatsApp o redes.
4. (Opcional, con costo) Si más adelante quieren un dominio propio como
   `tumarca.com`, se compra en Namecheap o GoDaddy (~10-15 USD/año) y se
   conecta desde el panel de Vercel en "Domains" — es un paso de 5 minutos.

## Sobre el pago dentro de la página (PSE, Nequi, tarjetas)
Ahora mismo el botón "Finalizar pedido" arma un mensaje de WhatsApp con el
resumen de la compra — así el vendedor confirma el pago directamente con el
cliente, sin costo ni papeleo.

Para que el pago se haga **dentro** de la página:
- **Wompi** (Bancolombia) o **ePayco** son las opciones más usadas en
  Colombia; ambas soportan PSE, Nequi y tarjeta.
- Se necesita: cuenta bancaria colombiana + registro como comercio (persona
  natural con cédula/RUT alcanza para empezar).
- Cobran comisión por transacción (no hay costo fijo mensual); en Wompi ronda
  2.65%-3.5% + IVA según el medio de pago — confirma las tarifas vigentes
  en su sitio antes de decidir.
- **Importante:** confirmar un pago de forma segura requiere un pequeño
  servidor (backend) que valide la transacción con una llave secreta; no se
  puede hacer 100% seguro solo con estos archivos HTML/JS estáticos. Cuando
  tengan la cuenta de Wompi/ePayco lista, avísame y te ayudo a montar ese
  backend (por ejemplo con una función serverless gratis en Vercel) y a
  conectarlo en el punto ya marcado como `procesarPagoConTarjeta()` dentro
  de `js/cart.js`.
