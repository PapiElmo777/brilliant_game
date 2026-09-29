import '../models/celda.dart';
import '../models/zona.dart';
import 'tablero.dart';

/// Preparación manual: cada número del 1 al 6 en una casilla inicial distinta.
/// Trabaja con una copia para que cambios externos no alteren la preparación.
class PreparacionInicial {
  final Tablero _tablero;

  PreparacionInicial(Tablero tablero) : _tablero = _copiar(tablero) {
    final iniciales = celdas.values.where((celda) => celda.esInicio).toList();
    if (iniciales.length != 6) {
      throw ArgumentError(
        'El tablero debe tener exactamente seis casillas de inicio.',
      );
    }
    final valores = iniciales
        .map((celda) => celda.valor)
        .whereType<int>()
        .toList();
    if (valores.toSet().length != valores.length) {
      throw ArgumentError('Los números iniciales no pueden repetirse.');
    }
    if (celdas.values.any((celda) => !celda.esInicio && celda.estaOcupada)) {
      throw ArgumentError(
        'Las casillas de juego deben estar vacías antes de iniciar.',
      );
    }
  }

  Map<String, Celda> get celdas => _tablero.celdas;

  Set<int> get numerosFaltantes {
    final colocados = celdas.values
        .where((celda) => celda.esInicio)
        .map((celda) => celda.valor)
        .whereType<int>()
        .toSet();
    return Set.unmodifiable({1, 2, 3, 4, 5, 6}.difference(colocados));
  }

  bool get estaLista => numerosFaltantes.isEmpty;

  void colocarValor(String celdaId, int valor) {
    validarColocacion(celdaId, valor);
    _tablero.colocarValor(celdaId, valor);
  }

  void validarColocacion(String celdaId, int valor) {
    _comprobarCeldaInicial(celdaId);
    if (celdas.values.any(
      (celda) => celda.id != celdaId && celda.valor == valor,
    )) {
      throw ArgumentError('El número $valor ya está colocado.');
    }
    if (!_tablero.puedeColocarValor(celdaId, valor)) {
      throw ArgumentError('El valor $valor incumple la regla o el rango de la zona.');
    }
  }

  void vaciarCelda(String celdaId) {
    _comprobarCeldaInicial(celdaId);
    _tablero.vaciarCelda(celdaId);
  }

  /// Entrega una copia independiente del tablero ya preparado.
  Tablero crearTableroParaJuego() {
    if (!estaLista) {
      throw StateError(
        'Debes colocar los números del 1 al 6 antes de iniciar.',
      );
    }
    return _copiar(_tablero);
  }

  void _comprobarCeldaInicial(String celdaId) {
    if (!_tablero.obtenerCelda(celdaId).esInicio) {
      throw ArgumentError('La celda $celdaId no es una casilla de inicio.');
    }
  }

  static Tablero _copiar(Tablero tablero) => Tablero(
    id: tablero.id,
    zonas: [
      for (final zona in tablero.zonas.values)
        Zona(
          id: zona.id,
          tipo: zona.tipo,
          campoPuntuacion: zona.campoPuntuacion,
          celdas: zona.celdas.values,
        ),
    ],
  );
}
