import '../models/celda.dart';
import '../models/tipo.dart';
import 'definicion_tablero.dart';
import 'recursos_nivel.dart';

final tablero03 = DefinicionTablero(
  id: 'tablero_03',
  nombre: 'Nivel 3',
  recursos: const RecursosNivel(3, 'Anakin'),
  zonas: [
    DefinicionZona(
      id: 'amarillo',
      tipo: const TipoAmarillo(),
      puntuaciones: {1: 7, 2: 5, 3: 3},
      celdas: [
        Celda(id: 'f1_c1', fila: 0, columna: 0, esInicio: false),
        Celda(id: 'f1_c2', fila: 0, columna: 1, esInicio: false),
        Celda(id: 'f1_c6', fila: 0, columna: 5, esInicio: false),
        Celda(id: 'f1_c7', fila: 0, columna: 6, esInicio: false),
        Celda(id: 'f2_c2', fila: 1, columna: 1, esInicio: false),
        Celda(id: 'f2_c6', fila: 1, columna: 5, esInicio: true),
      ],
    ),
    DefinicionZona(
      id: 'morado_1',
      tipo: const TipoMorado(),
      puntuaciones: {1: 7, 2: 5, 3: 3},
      celdas: [
        Celda(id: 'f1_c3', fila: 0, columna: 2, esInicio: false),
        Celda(id: 'f1_c5', fila: 0, columna: 4, esInicio: false),
        Celda(id: 'f2_c3', fila: 1, columna: 2, esInicio: true),
        Celda(id: 'f2_c4', fila: 1, columna: 3, esInicio: false),
        Celda(id: 'f2_c5', fila: 1, columna: 4, esInicio: false),
        Celda(id: 'f3_c4', fila: 2, columna: 3, esInicio: false),
      ],
    ),
    DefinicionZona(
      id: 'blanco',
      tipo: const TipoBlanco(),
      puntuaciones: {1: 8, 2: 6, 3: 4},
      celdas: [
        Celda(id: 'f1_c4', fila: 0, columna: 3, esInicio: false),
        Celda(id: 'f2_c1', fila: 1, columna: 0, esInicio: false),
        Celda(id: 'f2_c7', fila: 1, columna: 6, esInicio: false),
        Celda(id: 'f4_c4', fila: 3, columna: 3, esInicio: true),
        Celda(id: 'f7_c4', fila: 6, columna: 3, esInicio: false),
      ],
    ),
    DefinicionZona(
      id: 'rojo_1',
      tipo: const TipoRojo(),
      puntuaciones: {1: 6, 2: 4, 3: 2},
      celdas: [
        Celda(id: 'f3_c1', fila: 2, columna: 0, esInicio: false),
        Celda(id: 'f3_c2', fila: 2, columna: 1, esInicio: false),
        Celda(id: 'f3_c3', fila: 2, columna: 2, esInicio: false),
        Celda(id: 'f4_c1', fila: 3, columna: 0, esInicio: false),
        Celda(id: 'f4_c2', fila: 3, columna: 1, esInicio: false),
        Celda(id: 'f4_c3', fila: 3, columna: 2, esInicio: false),
      ],
    ),
    DefinicionZona(
      id: 'rojo_2',
      tipo: const TipoRojo(),
      puntuaciones: {1: 6, 2: 4, 3: 2},
      celdas: [
        Celda(id: 'f3_c5', fila: 2, columna: 4, esInicio: false),
        Celda(id: 'f3_c6', fila: 2, columna: 5, esInicio: false),
        Celda(id: 'f3_c7', fila: 2, columna: 6, esInicio: false),
        Celda(id: 'f4_c5', fila: 3, columna: 4, esInicio: false),
        Celda(id: 'f4_c6', fila: 3, columna: 5, esInicio: false),
        Celda(id: 'f4_c7', fila: 3, columna: 6, esInicio: false),
      ],
    ),
    DefinicionZona(
      id: 'verde',
      tipo: const TipoVerde(),
      puntuaciones: {1: 6, 2: 5, 3: 4},
      celdas: [
        Celda(id: 'f5_c1', fila: 4, columna: 0, esInicio: false),
        Celda(id: 'f5_c7', fila: 4, columna: 6, esInicio: true),
        Celda(id: 'f6_c1', fila: 5, columna: 0, esInicio: false),
        Celda(id: 'f6_c2', fila: 5, columna: 1, esInicio: false),
        Celda(id: 'f6_c3', fila: 5, columna: 2, esInicio: false),
        Celda(id: 'f6_c4', fila: 5, columna: 3, esInicio: false),
        Celda(id: 'f6_c5', fila: 5, columna: 4, esInicio: false),
        Celda(id: 'f6_c6', fila: 5, columna: 5, esInicio: false),
        Celda(id: 'f6_c7', fila: 5, columna: 6, esInicio: false),
      ],
    ),
    DefinicionZona(
      id: 'azul',
      tipo: const TipoAzul(),
      puntuaciones: {1: 7, 2: 5, 3: 3},
      celdas: [
        Celda(id: 'f5_c2', fila: 4, columna: 1, esInicio: true),
        Celda(id: 'f5_c3', fila: 4, columna: 2, esInicio: false),
        Celda(id: 'f5_c4', fila: 4, columna: 3, esInicio: false),
        Celda(id: 'f5_c5', fila: 4, columna: 4, esInicio: false),
        Celda(id: 'f5_c6', fila: 4, columna: 5, esInicio: false),
      ],
    ),
    DefinicionZona(
      id: 'morado_2',
      tipo: const TipoMorado(),
      puntuaciones: {1: 7, 2: 5, 3: 3},
      celdas: [
        Celda(id: 'f7_c1', fila: 6, columna: 0, esInicio: false),
        Celda(id: 'f7_c2', fila: 6, columna: 1, esInicio: false),
        Celda(id: 'f7_c3', fila: 6, columna: 2, esInicio: true),
        Celda(id: 'f7_c5', fila: 6, columna: 4, esInicio: false),
        Celda(id: 'f7_c6', fila: 6, columna: 5, esInicio: false),
        Celda(id: 'f7_c7', fila: 6, columna: 6, esInicio: false),
      ],
    ),
  ],
);
