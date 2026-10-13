import '../models/celda.dart';
import 'definicion_tablero.dart';

/// Puntos representativos al completar una zona, según su número de casillas.
/// Cada lista va de la puntuación mayor a la menor.
const puntosPorTamano = <int, List<int>>{
  1: [2, 1, 0],
  4: [5, 3, 1],
  5: [6, 4, 2],
  6: [7, 5, 3],
  7: [8, 6, 4],
};

List<int> puntosDeZona(DefinicionZona zona) =>
    puntosPorTamano[zona.celdas.length] ?? const [];

/// Puntuación provisional: suma la mayor puntuación de cada zona completa.
int puntuacionRepresentativa(
  DefinicionTablero definicion,
  Map<String, Celda> celdas,
) {
  var total = 0;
  for (final zona in definicion.zonas) {
    final puntos = puntosDeZona(zona);
    final completa = zona.celdas.every(
      (celda) => celdas[celda.id]?.estaOcupada ?? false,
    );
    if (completa && puntos.isNotEmpty) total += puntos.first;
  }
  return total;
}
