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
