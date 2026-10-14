import 'package:flutter/material.dart';
import 'navegacion.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/calificar_screen.dart';
import 'screens/detalle_evento_screen.dart';
import 'screens/gracias_opinion_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notificaciones_screen.dart';
import 'screens/crear_evento_screen.dart';
import 'screens/detalle_evento_organizador_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/panel_asistente_screen.dart';
import 'screens/panel_organizador_screen.dart';
import 'screens/perfil_organizador_screen.dart';
import 'screens/planes_screen.dart';
import 'screens/registro_exitoso_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/ticket_screen.dart';
import 'theme/colores.dart';

class EventBQApp extends StatelessWidget {
  const EventBQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventBQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colores.azulOscuro,
        scaffoldBackgroundColor: Colores.fondo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colores.azulOscuro),
        // fontFamily: 'Lexend', // <- descomentar cuando agregues la fuente
      ),
      initialRoute: '/',
      // Para agregar una pantalla nueva: crea el archivo en screens/ y
      // añade una línea aquí.
      routes: {
        '/': (context) => const SplashScreen(),
        '/bienvenida': (context) => const BienvenidaScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) {
          // irAPestana() manda el número de pestaña como argumento
          final args = ModalRoute.of(context)?.settings.arguments;
          return MainScreen(indiceInicial: args is int ? args : 0);
        },
        '/detalle-evento': (context) => const DetalleEventoScreen(),
        '/perfil-organizador': (context) => const PerfilOrganizadorScreen(),
        '/registro-exitoso': (context) => const RegistroExitosoScreen(),
        '/notificaciones': (context) => const NotificacionesScreen(),
        '/calificar': (context) => const CalificarScreen(),
        '/gracias-opinion': (context) => const GraciasOpinionScreen(),
        '/planes': (context) => const PlanesScreen(),
        '/panel-organizador': (context) => const PanelOrganizadorScreen(),
        '/panel-asistente': (context) => const PanelAsistenteScreen(),
        '/ticket': (context) => const TicketScreen(),
        '/crear-evento': (context) => const CrearEventoScreen(),
        '/detalle-evento-organizador': (context) =>
            const DetalleEventoOrganizadorScreen(),
      },
    );
  }
}
