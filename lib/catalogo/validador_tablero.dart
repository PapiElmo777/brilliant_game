import '../core/preparacion_inicial.dart';
import '../core/tablero.dart';

void validarTablero7x7(Tablero tablero) {
  final celdas = tablero.celdas.values;
  if (celdas.length != 49) {
    throw ArgumentError('El tablero jugable debe contener 49 celdas.');
  }
  if (celdas.any(
    (celda) =>
        celda.fila < 0 ||
        celda.fila > 6 ||
        celda.columna < 0 ||
        celda.columna > 6,
  )) {
    throw ArgumentError('Las filas y columnas deben estar entre 0 y 6.');
  }
  // Tablero garantiza IDs y posiciones únicos; 49 posiciones en rango cubren 7×7.
  PreparacionInicial(tablero);
}
