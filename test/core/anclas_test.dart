import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/core/anclas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vecinos ortogonales vacíos, sin diagonales ni duplicados', () {
    final tablero = Tablero(
      id: 't',
      zonas: [
        Zona(
          id: 'v',
          tipo: const TipoVerde(),
          celdas: [
            Celda(id: 'a', fila: 1, columna: 1, valorInicial: 2),
            Celda(id: 'b', fila: 1, columna: 3, valorInicial: 2),
            Celda(id: 'medio', fila: 1, columna: 2),
            Celda(id: 'arriba', fila: 0, columna: 1),
            Celda(id: 'abajo', fila: 2, columna: 1),
            Celda(id: 'izquierda', fila: 1, columna: 0),
            Celda(id: 'diagonal', fila: 0, columna: 0),
            Celda(id: 'ocupada', fila: 2, columna: 3, valorInicial: 5),
          ],
        ),
      ],
    );
    expect(destinosConAncla(tablero, 5, 2), {
      'medio',
      'arriba',
      'abajo',
      'izquierda',
    });
    expect(destinosConAncla(tablero, 2, 5), <String>{});
    expect(() => destinosConAncla(tablero, 7, 2), throwsArgumentError);
  });

  for (final caso in <(Tipo, List<int>, int, bool)>[
    (const TipoAzul(), [2], 2, true),
    (const TipoAzul(), [2], 5, false),
    (const TipoAmarillo(), [2], 2, false),
    (const TipoAmarillo(), [2], 5, true),
    (const TipoRojo(), [2], 2, false),
    (const TipoRojo(), [2], 5, true),
    (const TipoVerde(), [2], 2, true),
    (const TipoVerde(), [2], 5, true),
    (const TipoMorado(), [2, 3], 5, false),
    (const TipoMorado(), [2, 3], 3, true),
  ]) {
    test(
      'Adyacencia entre zonas y regla ${caso.$1.runtimeType} ${caso.$3}',
      () {
        final t = Tablero(
          id: 't',
          zonas: [
            Zona(
              id: 'ancla',
              tipo: const TipoVerde(),
              celdas: [Celda(id: 'a', fila: 0, columna: 0, valorInicial: 6)],
            ),
            Zona(
              id: 'destino',
              tipo: caso.$1,
              celdas: [
                Celda(id: 'd', fila: 0, columna: 1),
                for (var i = 0; i < caso.$2.length; i++)
                  Celda(
                    id: 'x$i',
                    fila: 4,
                    columna: i,
                    valorInicial: caso.$2[i],
                  ),
              ],
            ),
          ],
        );
        expect(destinosConAncla(t, caso.$3, 6).contains('d'), caso.$4);
      },
    );
  }
}
