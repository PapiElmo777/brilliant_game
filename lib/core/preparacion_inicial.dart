import 'dart:math' as math;

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
      throw ArgumentError(
        'El valor $valor incumple la regla o el rango de la zona.',
      );
    }
  }

  /// Propone al azar una colocación válida de los números faltantes en las
  /// casillas iniciales vacías, ordenada del número menor al mayor. No
  /// modifica la preparación: las reglas se comprueban sobre una copia.
  List<(String celdaId, int valor)> distribucionAleatoria(math.Random random) {
    final prueba = _copiar(_tablero);
    final vacias = [
      for (final celda in celdas.values)
        if (celda.esInicio && !celda.estaOcupada) celda.id,
    ]..shuffle(random);
    final numeros = numerosFaltantes.toList()..shuffle(random);
    final resultado = <(String, int)>[];
    bool asignar(int indice) {
      if (indice == vacias.length) return true;
      final celdaId = vacias[indice];
      for (final valor in numeros) {
        if (resultado.any((asignado) => asignado.$2 == valor) ||
            !prueba.puedeColocarValor(celdaId, valor)) {
          continue;
        }
        prueba.colocarValor(celdaId, valor);
        resultado.add((celdaId, valor));
        if (asignar(indice + 1)) return true;
        prueba.vaciarCelda(celdaId);
        resultado.removeLast();
      }
      return false;
    }

    if (!asignar(0)) {
      throw StateError(
        'No existe una distribución válida para los números restantes.',
      );
    }
    return resultado..sort((a, b) => a.$2.compareTo(b.$2));
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
