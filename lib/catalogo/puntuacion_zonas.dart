import 'definicion_tablero.dart';

/// Puntos de la zona ordenados por puesto: primero, segundo y tercero.
List<int> puntosDeZona(DefinicionZona zona) {
  final puestos = zona.tipo.puntuaciones.keys.toList()..sort();
  return [for (final puesto in puestos) zona.tipo.puntuaciones[puesto]!];
}
