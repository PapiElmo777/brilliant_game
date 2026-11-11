import 'tablero.dart';

Set<String> destinosConAncla(Tablero tablero, int valor, int ancla) {
  if (valor < 1 || valor > 6 || ancla < 1 || ancla > 6) {
    throw ArgumentError('Los valores deben estar entre 1 y 6.');
  }
  return Set.unmodifiable({
    for (final celda in tablero.celdas.values)
      if (celda.valor == ancla)
        for (final vecino in tablero.obtenerVecinos(celda.id).values)
          if (vecino != null &&
              !vecino.estaOcupada &&
              tablero.puedeColocarValor(vecino.id, valor))
            vecino.id,
  });
}

/// Explica el bloqueo solo si ninguna de las dos orientaciones es legal.
String? motivoSinMovimientos(Tablero tablero, int primero, int segundo) {
  if (destinosConAncla(tablero, primero, segundo).isNotEmpty ||
      destinosConAncla(tablero, segundo, primero).isNotEmpty) {
    return null;
  }
  final cells = tablero.celdas.values;
  if (cells.every((cell) => cell.estaOcupada)) {
    return 'El tablero está lleno: no quedan casillas libres.';
  }
  final anchors = cells.where(
    (cell) => cell.valor == primero || cell.valor == segundo,
  );
  if (anchors.isEmpty) return 'No hay anclas con los números de los dados.';
  final emptyNeighbors = anchors.any(
    (anchor) => tablero
        .obtenerVecinos(anchor.id)
        .values
        .any((cell) => cell != null && !cell.estaOcupada),
  );
  if (!emptyNeighbors) return 'Las anclas no tienen casillas vecinas libres.';
  return 'Las casillas junto a las anclas no cumplen las reglas de color.';
}
