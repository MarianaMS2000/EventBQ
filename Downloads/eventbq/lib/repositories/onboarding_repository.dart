import '../data/datos_simulados.dart';
import '../models/pagina_onboarding.dart';

class OnboardingRepository {
  List<PaginaOnboarding> obtenerPaginas() {
    return datosOnboarding;
  }
}
