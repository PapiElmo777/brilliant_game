import 'dart:collection';

import '../models/celda.dart';
import '../models/zona.dart';

/// Un tablero contiene zonas; cada celda pertenece a una sola zona del tablero.
class Tablero {
  final String id;
  final Map<String, Zona> _zonas = {};
  final Map<String, Zona> _zonaPorCelda = {};
  final Map<(int, int), String> _celdaPorPosicion = {};

  Tablero({required this.id, required Iterable<Zona> zonas}) {
    if (id.trim().isEmpty)
      throw ArgumentError('El ID de tablero no puede estar vacío.');
    for (final zona in zonas) {
      if (_zonas.containsKey(zona.id)) {
        throw ArgumentError(
          'La zona ${zona.id} está duplicada en el tablero $id.',
        );
      }
      _zonas[zona.id] = zona;
      for (final celda in zona.celdas.values) {
        if (_zonaPorCelda.containsKey(celda.id)) {
          throw ArgumentError(
            'La celda ${celda.id} pertenece a más de una zona.',
          );
        }
        final posicion = (celda.fila, celda.columna);
        if (_celdaPorPosicion.containsKey(posicion)) {
          throw ArgumentError('Dos celdas ocupan la posición $posicion.');
        }
        _zonaPorCelda[celda.id] = zona;
        _celdaPorPosicion[posicion] = celda.id;
      }
    }
    if (_zonas.isEmpty)
      throw ArgumentError('El tablero $id debe contener zonas.');
  }

  Map<String, Zona> get zonas => UnmodifiableMapView(_zonas);

  /// Vista de consulta derivada de las zonas, sin duplicar su estado.
  Map<String, Celda> get celdas =>
      Map.unmodifiable({for (final zona in _zonas.values) ...zona.celdas});

  Zona obtenerZona(String zonaId) {
    final zona = _zonas[zonaId];
    if (zona == null)
      throw ArgumentError('La zona $zonaId no existe en el tablero $id.');
    return zona;
  }

  Zona obtenerZonaDeCelda(String celdaId) {
    final zona = _zonaPorCelda[celdaId];
    if (zona == null)
      throw ArgumentError('La celda $celdaId no existe en el tablero $id.');
    return zona;
  }

  Celda obtenerCelda(String celdaId) =>
      obtenerZonaDeCelda(celdaId).celdas[celdaId]!;

  Celda? obtenerCeldaEn(int fila, int columna) {
    final celdaId = _celdaPorPosicion[(fila, columna)];
    return celdaId == null ? null : obtenerCelda(celdaId);
  }

  Map<String, Celda?> obtenerVecinos(String celdaId) {
    final celda = obtenerCelda(celdaId);
    return {
      'arriba': obtenerCeldaEn(celda.fila - 1, celda.columna),
      'abajo': obtenerCeldaEn(celda.fila + 1, celda.columna),
      'izquierda': obtenerCeldaEn(celda.fila, celda.columna - 1),
      'derecha': obtenerCeldaEn(celda.fila, celda.columna + 1),
    };
  }

  List<int> extraerValoresDeZona(String zonaId) => obtenerZona(zonaId).valores;

  bool puedeColocarValor(String celdaId, int valor) =>
      obtenerZonaDeCelda(celdaId).puedeColocarValor(celdaId, valor);

  void colocarValor(String celdaId, int valor) =>
      obtenerZonaDeCelda(celdaId).colocarValor(celdaId, valor);

  void vaciarCelda(String celdaId) =>
      obtenerZonaDeCelda(celdaId).vaciarCelda(celdaId);
}
