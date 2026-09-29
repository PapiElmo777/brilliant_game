import '../models/celda.dart';
import '../models/tipo.dart';
import 'definicion_tablero.dart';

final tablero01 = DefinicionTablero(
  id: 'tablero_01',
  nombre: 'Tablero 1',
  zonas: [
    _zona('amarillo_1', const TipoAmarillo(), [(0, 0)]),
    _zona('verde_1', const TipoVerde(), [
      (0, 1),
      (1, 0),
      (1, 1),
      (2, 0),
      (3, 0),
      (4, 0),
    ]),
    _zona('azul_1', const TipoAzul(), [(0, 2), (1, 2), (1, 3), (2, 3)]),
    _zona('morado_1', const TipoMorado(), [
      (0, 3),
      (0, 4),
      (0, 5),
      (1, 4),
      (1, 5),
      (2, 4),
    ]),
    _zona('amarillo_2', const TipoAmarillo(), [(0, 6)]),
    _zona('verde_2', const TipoVerde(), [
      (1, 6),
      (2, 5),
      (2, 6),
      (3, 4),
      (3, 5),
      (3, 6),
    ]),
    _zona('rojo_1', const TipoRojo(), [
      (2, 1),
      (2, 2),
      (3, 1),
      (4, 1),
      (5, 0),
      (5, 1),
    ]),
    _zona('morado_2', const TipoMorado(), [
      (3, 2),
      (4, 2),
      (5, 2),
      (6, 1),
      (6, 2),
    ]),
    _zona('amarillo_3', const TipoAmarillo(), [(3, 3)]),
    _zona('rojo_2', const TipoRojo(), [
      (4, 3),
      (4, 4),
      (4, 5),
      (5, 3),
      (5, 4),
      (6, 3),
      (6, 4),
    ]),
    _zona('azul_2', const TipoAzul(), [(4, 6), (5, 5), (5, 6), (6, 5)]),
    _zona('amarillo_4', const TipoAmarillo(), [(6, 0)]),
    _zona('amarillo_5', const TipoAmarillo(), [(6, 6)]),
  ],
);

const _iniciales = {(0, 1), (1, 5), (3, 1), (3, 4), (5, 2), (6, 4)};

DefinicionZona _zona(String id, Tipo tipo, List<(int, int)> posiciones) {
  return DefinicionZona(
    id: id,
    tipo: tipo,
    celdas: [
      for (final (fila, columna) in posiciones)
        Celda(
          id: 'f${fila + 1}_c${columna + 1}',
          fila: fila,
          columna: columna,
          esInicio: _iniciales.contains((fila, columna)),
        ),
    ],
  );
}
