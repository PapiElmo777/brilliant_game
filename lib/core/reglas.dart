import '../models/tipo.dart';

/// Comprueba una configuración completa, incluido el rango de cada número.
/// Las restricciones de color pertenecen exclusivamente a las clases Tipo.
bool validarValoresDeTipo(Tipo tipo, Iterable<int> valores) {
  final anteriores = <int>[];
  for (final valor in valores) {
    if (valor < 1 ||
        valor > 6 ||
        !tipo.esPosibleAgregar(List.unmodifiable(anteriores), valor)) {
      return false;
    }
    anteriores.add(valor);
  }
  return true;
}

// Adaptadores de las funciones existentes a la jerarquía de tipos.
bool cumpleReglaRojoAmarillo(List<int> lista, int numero) =>
    validarValoresDeTipo(const TipoRojo(), [...lista, numero]);

bool cumpleReglaVerde(List<int> lista, int numero) =>
    validarValoresDeTipo(const TipoVerde(), [...lista, numero]);

bool cumpleReglaAzul(List<int> lista, int numero) =>
    validarValoresDeTipo(const TipoAzul(), [...lista, numero]);

bool cumpleReglaMorado(List<int> lista, int numero) =>
    validarValoresDeTipo(const TipoMorado(), [...lista, numero]);
