/**
 * ROPA — un producto por objeto.
 * Para añadir un producto nuevo, copia un bloque {...} y cambia los datos.
 * `id` debe ser único en TODO el catálogo (entre todos los archivos data/*.js).
 * `img` puede ser una URL real (https://...) o dejarse vacío para usar un
 * marcador de color automático mientras no tengas fotos.
 */
const PRODUCTOS_ROPA = [
  {
    id: "ropa-001",
    nombre: "Camiseta de algodón Essential",
    categoria: "ropa",
    genero: "hombre",
    precio: 89000,
    stock: true,
    img: "",
    colorPlaceholder: "#EDE9DE",
    descripcion: "Camiseta básica de corte recto en algodón peinado 100%, ideal para uso diario.",
    especificaciones: {
      "Material": "100% algodón peinado",
      "Corte": "Regular fit",
      "Tallas": "S, M, L, XL",
      "Cuidado": "Lavado en frío, no usar secadora"
    }
  },
  {
    id: "ropa-002",
    nombre: "Camiseta de corte oversize",
    categoria: "ropa",
    genero: "hombre",
    precio: 99000,
    stock: true,
    img: "",
    colorPlaceholder: "#D8D1C0",
    descripcion: "Silueta oversize con caída relajada, estampado frontal minimalista.",
    especificaciones: {
      "Material": "95% algodón / 5% elastano",
      "Corte": "Oversize",
      "Tallas": "S, M, L, XL",
      "Cuidado": "Lavado en frío, secado a la sombra"
    }
  },
  {
    id: "ropa-003",
    nombre: "Camiseta gráfica edición limitada",
    categoria: "ropa",
    genero: "hombre",
    precio: 109000,
    stock: false,
    img: "",
    colorPlaceholder: "#211F1C",
    descripcion: "Serie limitada con print artístico, tela premium de mayor gramaje.",
    especificaciones: {
      "Material": "100% algodón (220 g/m²)",
      "Corte": "Regular fit",
      "Tallas": "M, L, XL",
      "Edición": "Limitada — 200 unidades"
    }
  },
  {
    id: "ropa-004",
    nombre: "Blusa satinada manga larga",
    categoria: "ropa",
    genero: "mujer",
    precio: 129000,
    stock: true,
    img: "",
    colorPlaceholder: "#E3DDCD",
    descripcion: "Blusa de tacto satinado con caída fluida, ideal para looks formales o casuales.",
    especificaciones: {
      "Material": "Poliéster satinado",
      "Corte": "Fit clásico",
      "Tallas": "XS, S, M, L",
      "Cuidado": "Lavado a mano"
    }
  },
  {
    id: "ropa-005",
    nombre: "Vestido midi acanalado",
    categoria: "ropa",
    genero: "mujer",
    precio: 159000,
    stock: true,
    img: "",
    colorPlaceholder: "#96713D",
    descripcion: "Vestido midi en punto acanalado, entallado, con abertura lateral.",
    especificaciones: {
      "Material": "Punto acanalado (viscosa/elastano)",
      "Largo": "Midi",
      "Tallas": "XS, S, M, L",
      "Cuidado": "Lavado en frío"
    }
  },
  {
    id: "ropa-006",
    nombre: "Pantalón palazzo de lino",
    categoria: "ropa",
    genero: "mujer",
    precio: 139000,
    stock: true,
    img: "",
    colorPlaceholder: "#D8D1C0",
    descripcion: "Pantalón de pierna ancha en mezcla de lino, tiro alto y cintura elástica.",
    especificaciones: {
      "Material": "70% lino / 30% viscosa",
      "Corte": "Palazzo, tiro alto",
      "Tallas": "S, M, L, XL",
      "Cuidado": "Lavado a mano, planchar tibio"
    }
  }
];
