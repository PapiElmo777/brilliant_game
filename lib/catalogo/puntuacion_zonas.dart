import '../models/celda.dart';
import 'definicion_tablero.dart';

/// Puntos de la zona ordenados por puesto: primero, segundo y tercero.
List<int> puntosDeZona(DefinicionZona zona) {
  final puestos = zona.tipo.puntuaciones.keys.toList()..sort();
  return [for (final puesto in puestos) zona.tipo.puntuaciones[puesto]!];
}

/// Puntuación provisional: suma los puntos del primer puesto de cada zona
/// completa.
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
