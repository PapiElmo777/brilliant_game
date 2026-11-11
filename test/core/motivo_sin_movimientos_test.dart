import 'package:brilliant_game/core/anclas.dart';
import 'package:brilliant_game/core/tablero.dart';
import 'package:brilliant_game/models/celda.dart';
import 'package:brilliant_game/models/zona.dart';
import 'package:brilliant_game/models/tipo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Tablero green(List<Celda> cells) => Tablero(
    id: 'test',
    zonas: [Zona(id: 'verde', tipo: const TipoVerde(), celdas: cells)],
  );
  test('Distingue un tablero lleno de un tablero sin anclas de los dados', () {
    final full = green([Celda(id: 'a', fila: 0, columna: 0, valorInicial: 1)]);
    expect(motivoSinMovimientos(full, 1, 2), contains('tablero está lleno'));
    final missing = green([
      Celda(id: 'a', fila: 0, columna: 0, valorInicial: 3),
      Celda(id: 'b', fila: 0, columna: 1),
    ]);
    expect(motivoSinMovimientos(missing, 1, 2), contains('No hay anclas'));
  });
  test('Explica cuando hay anclas pero ninguna tiene vecinos vacíos', () {
    final board = green([
      Celda(id: 'a', fila: 0, columna: 0, valorInicial: 1),
      Celda(id: 'b', fila: 0, columna: 1, valorInicial: 2),
      Celda(id: 'libre', fila: 5, columna: 5),
    ]);
    expect(
      motivoSinMovimientos(board, 1, 2),
      contains('no tienen casillas vecinas libres'),
    );
  });
  test(
    'Reconoce el bloqueo por color y permite la otra orientación si es legal',
    () {
      Tablero board(int seed) => Tablero(
        id: 'test',
        zonas: [
          Zona(
            id: 'verde',
            tipo: const TipoVerde(),
            celdas: [Celda(id: 'a', fila: 0, columna: 0, valorInicial: 1)],
          ),
          Zona(
            id: 'azul',
            tipo: const TipoAzul(),
            celdas: [
              Celda(id: 'libre', fila: 0, columna: 1),
              Celda(id: 'semilla', fila: 0, columna: 2, valorInicial: seed),
            ],
          ),
        ],
      );
      expect(motivoSinMovimientos(board(3), 2, 1), contains('reglas de color'));
      expect(motivoSinMovimientos(board(2), 2, 1), isNull);
    },
  );
}
