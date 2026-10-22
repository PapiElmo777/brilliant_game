import 'definicion_tablero.dart';

/// Puntos de la zona ordenados por puesto: primero, segundo y tercero.
List<int> puntosDeZona(DefinicionZona zona) {
  final puestos = zona.puntuaciones.keys.toList()..sort();
  return [for (final puesto in puestos) zona.puntuaciones[puesto]!];
}
