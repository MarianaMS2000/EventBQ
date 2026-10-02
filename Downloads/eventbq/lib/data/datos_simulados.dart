import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/evento.dart';
import '../models/item_agenda.dart';
import '../models/notificacion.dart';
import '../models/organizador.dart';
import '../models/pagina_onboarding.dart';
import '../models/usuario.dart';

// DATOS SIMULADOS: se reemplazarán por un backend más adelante.
// Solo los usa la carpeta "repositories".

final Usuario datosUsuarioPorDefecto = Usuario(
  nombre: 'Connor Storrie',
  usuario: 'connor',
  correo: 'connor@email.com',
  foto: 'assets/images/avatar.png',
  telefono: '+57 315 987 6543',
  rol: 'Entrenador Deportivo',
  miembroDesde: 'Agosto 2024',
  eventosAsistidos: 12,
  eventosCreados: 1,
  rating: 4.5,
);

final List<Categoria> datosCategorias = [
  Categoria(
    nombre: 'Música',
    icono: Icons.headphones,
    colorFondo: const Color(0xFFC9A8D8),
    colorTexto: const Color(0xFF7B3F98),
  ),
  Categoria(
    nombre: 'Deporte',
    icono: Icons.sports_basketball,
    colorFondo: const Color(0xFFD95F5F),
    colorTexto: const Color(0xFFB02A2A),
  ),
  Categoria(
    nombre: 'Arte',
    icono: Icons.palette,
    colorFondo: const Color(0xFFF08DB3),
    colorTexto: const Color(0xFFC2185B),
  ),
  Categoria(
    nombre: 'Gastronomía',
    icono: Icons.ramen_dining,
    colorFondo: const Color(0xFFF7B77A),
    colorTexto: const Color(0xFFE0801E),
  ),
];

// Eventos de la pantalla Inicio
final List<Evento> datosEventosTop = [
  Evento(
    id: 'e1',
    titulo: 'Festival Indietronica',
    categoria: 'Música',
    fechaCompleta: 'Nov 27 • 08:00 PM • 2026',
    dia: '27',
    mes: 'Nov',
    lugar: 'Pabellón Cristal, Gran Malecón',
    precio: '\$ 25.00',
    imagen: 'assets/images/evento_festival.jpg',
  ),
  Evento(
    id: 'e2',
    titulo: 'Sabores Urbanos Food Fest',
    categoria: 'Gastronomía',
    fechaCompleta: 'Dic 02 • 01:00 PM • 2026',
    dia: '02',
    mes: 'Dic',
    lugar: 'Parque La Electrificadora',
    precio: '\$ Gratis',
    imagen: 'assets/images/evento_food_fest.jpg',
  ),
];

// Eventos de la pantalla Explorar
final List<Evento> datosEventosExplorar = [
  Evento(
    id: 'e3',
    titulo: 'Yoga & Sunset al Aire Libre',
    categoria: 'Deportes',
    fechaCompleta: 'Dic 18 • 05:00 PM • 2026',
    dia: '18',
    mes: 'Dic',
    lugar: 'Pabellón Cristal',
    precio: '\$ 15.000',
    imagen: 'assets/images/evento_yoga.jpg',
  ),
  Evento(
    id: 'e4',
    titulo: 'Noche de Teatro Improv: Escena Abierta',
    categoria: 'Arte',
    fechaCompleta: 'Dic 20 • 07:30 PM • 2026',
    dia: '20',
    mes: 'Dic',
    lugar: 'Teatro José Consuegra Higgins',
    precio: '\$ 20.000',
    imagen: 'assets/images/evento_teatro.jpg',
  ),
  Evento(
    id: 'e5',
    titulo: 'Exposición: Retrospectiva Acuarelas',
    categoria: 'Arte',
    fechaCompleta: 'Dic 10 • 10:00 AM • 2026',
    dia: '10',
    mes: 'Dic',
    lugar: 'Museo del Caribe',
    precio: '\$ Gratis',
    imagen: 'assets/images/evento_exposicion.jpg',
    fechaLarga: '10 de Diciembre 2026',
    horario: '10:00 AM - 2:00 PM',
    cuposDisponibles: 32,
    cuposTotales: 60,
    descripcion:
        'La Retrospectiva de Acuarelas es un espacio cultural y visual diseñado para recorrer la evolución técnica, temática y emocional de la acuarela a lo largo del tiempo. Reúne una colección seleccionada de obras que destacan el uso de la luz, las transparencias y la pigmentación sobre agua. Es una experiencia inmersiva dirigida tanto a amantes del arte como a estudiantes, artistas locales y público general que busque apreciar la delicadeza de esta técnica.',
    incluye: [
      'Exhibición de Obras: Galería temática y cronológica de piezas en acuarela.',
      'Fichas con QR: Información del autor y contexto de cada obra.',
      'Taller en Vivo: Demostración práctica de pintura en tiempo real.',
      'Catálogo & Café: Material digital descargable y espacio de networking.',
    ],
    agenda: [
      ItemAgenda(
        hora: '10:00 AM - 11:00 AM',
        descripcion: 'Recepción de asistentes e inicio de la exhibición guiada.',
      ),
      ItemAgenda(
        hora: '11:00 AM - 12:30 PM',
        descripcion: 'Creación de una pieza de acuarela en tiempo real.',
      ),
      ItemAgenda(
        hora: '12:30 PM - 02:00 PM',
        descripcion: 'Espacio para conversar con los artistas, café y evaluación.',
      ),
    ],
  ),
  Evento(
    id: 'e6',
    titulo: 'Tarde de Mixología y Coctelería',
    categoria: 'Gastronomía',
    fechaCompleta: 'Dic 15 • 04:00 PM • 2026',
    dia: '15',
    mes: 'Dic',
    lugar: 'Mall Plaza Buenavista',
    precio: '\$ 45.000',
    imagen: 'assets/images/evento_mixologia.jpg',
  ),
  Evento(
    id: 'e9',
    titulo: 'Carrera "Corre por un Norte"',
    categoria: 'Deportes',
    fechaCompleta: 'Sep 29 • 06:00 AM • 2026',
    dia: '29',
    mes: 'Sep',
    lugar: 'Parque de las Raquetas',
    precio: '\$ Gratis',
    imagen: 'assets/images/evento_carrera.jpg',
    esHoy: true,
  ),
  Evento(
    id: 'e10',
    titulo: 'Entrenamiento Funcional al Atardecer',
    categoria: 'Deportes',
    fechaCompleta: 'Sep 29 • 05:30 PM • 2026',
    dia: '29',
    mes: 'Sep',
    lugar: 'Gran Malecón (Sector Puerta de Oro)',
    precio: '\$ Gratis',
    imagen: 'assets/images/evento_entrenamiento.jpg',
    esHoy: true,
  ),
  Evento(
    id: 'e11',
    titulo: 'Ciclovia Nocturna y Ciclopaseo Urbano',
    categoria: 'Deportes',
    fechaCompleta: 'Sep 29 • 07:30 PM • 2026',
    dia: '29',
    mes: 'Sep',
    lugar: 'Gran Malecón (Punto de encuentro: Puerta de Oro)',
    precio: '\$ Gratis',
    imagen: 'assets/images/evento_ciclovia.jpg',
    esHoy: true,
  ),
];

final List<PaginaOnboarding> datosOnboarding = [
  PaginaOnboarding(
    titulo: 'Encuentra planes a tu medida',
    subtitulo:
        'Encuentra siempre el plan perfecto. Filtra por lo que más te gusta y no te pierdas de nada.',
    imagen: 'assets/images/onboarding_1.png',
    colorFondoImagen: const Color(0xFF6F8BE0),
  ),
  PaginaOnboarding(
    titulo: 'Crea y publica tu propio evento',
    subtitulo:
        'Publica tus eventos en minutos, gestiona el aforo y comparte la ubicación exacta para que todos sepan cómo llegar.',
    imagen: 'assets/images/onboarding_2.png',
    colorFondoImagen: const Color(0xFFFDBF85),
  ),
  PaginaOnboarding(
    titulo: 'Acceso rápido y control total',
    subtitulo:
        'Entradas digitales en un solo lugar para los asistentes y control de acceso sencillo para los organizadores el día del evento.',
    imagen: 'assets/images/onboarding_3.png',
    colorFondoImagen: const Color(0xFF4CBF94),
  ),
];

final Organizador datosOrganizador = Organizador(
  id: 'o1',
  nombre: 'Rosa Valenzuela',
  rol: 'Maestra Acuarelista y Conservadora de Arte',
  foto: 'assets/images/organizadora.png',
  correo: 'rosa.valenzuela@eventbq.com',
  telefono: '+57 315 987 6543',
  miembroDesde: 'Marzo 2023',
  eventos: 3,
  asistentes: 450,
  rating: 4.9,
);

// Eventos del perfil del organizador (el primero es el mismo de Explorar)
final List<Evento> datosEventosOrganizador = [
  datosEventosExplorar[2],
  Evento(
    id: 'e7',
    titulo: 'Taller de Pigmentos con Acuarela Botánica',
    categoria: 'Arte',
    fechaCompleta: 'May 15 • 03:00 PM • 2026',
    dia: '15',
    mes: 'May',
    lugar: 'Museo del Atlántico',
    precio: '\$ 45.000',
    imagen: 'assets/images/evento_pigmentos.jpg',
    estado: 'Finalizado',
  ),
  Evento(
    id: 'e8',
    titulo: 'Muestra Luces y Sombras del Caribe',
    categoria: 'Arte',
    fechaCompleta: 'Feb 8 • 06:00 PM • 2026',
    dia: '8',
    mes: 'Feb',
    lugar: 'Centro Cultural La Aduana',
    precio: '\$ 20.000',
    imagen: 'assets/images/evento_luces.jpg',
    estado: 'Finalizado',
  ),
];

// Opciones del modal de filtros
final List<String> datosCategoriasFiltro = [
  'Salud',
  'Música',
  'Deportes',
  'Tecnología',
  'Gastronomía',
  'Cultura',
  'Empresarial',
  'Arte',
];

final List<String> datosOpcionesFecha = [
  'Cualquier fecha',
  'Hoy',
  'Esta semana',
  'Este mes',
];

final List<Notificacion> datosNotificaciones = [
  Notificacion(
    id: 'n1',
    titulo: 'Tu inscripción fue confirmada',
    descripcion: 'Foro Internacional de Diseño de Interiores 2026',
    tiempo: 'Hace 2 horas',
    tipo: 'Eventos',
  ),
  Notificacion(
    id: 'n2',
    titulo: 'Recordatorio: tu evento es mañana',
    descripcion: 'Conferencia de Innovación Tecnológica del Caribe',
    tiempo: 'Hace 5 horas',
    tipo: 'Eventos',
  ),
  Notificacion(
    id: 'n3',
    titulo: '¿Qué tal estuvo el evento? ¡Califícalo!',
    descripcion: 'Festival de Música Electrónica',
    tiempo: 'Hace 10 horas',
    tipo: 'Eventos',
    pideCalificacion: true,
    idEvento: 'e1',
  ),
];
