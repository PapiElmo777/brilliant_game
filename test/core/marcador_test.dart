import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

Zona zonaPrueba(String id, Tipo tipo) => Zona(
  id: id,
  tipo: tipo,
  celdas: [Celda(id: 'c', fila: 0, columna: 0)],
);

void main() {
  test('La meta depende del número de jugadores', () {
    expect(metaDePuntos(2), 26);
    expect(metaDePuntos(3), 24);
    expect(metaDePuntos(4), 22);
    expect(metaDePuntos(5), 20);
    expect(() => metaDePuntos(1), throwsArgumentError);
    expect(() => metaDePuntos(6), throwsArgumentError);
    expect(Marcador(jugadores: 2).meta, 26);
  });

  test('Cada puesto de una zona se reclama una vez y en orden', () {
    final marcador = Marcador(jugadores: 4);
    const azul = TipoAzul();
    final primero = marcador.reclamar(
      zona: zonaPrueba('azul_1', azul),
      jugadorId: 'ana',
    );
    expect((primero.puesto, primero.puntos), (1, 7));
    expect(
      () =>
          marcador.reclamar(zona: zonaPrueba('azul_1', azul), jugadorId: 'ana'),
      throwsStateError,
    );
    final segundo = marcador.reclamar(
      zona: zonaPrueba('azul_1', azul),
      jugadorId: 'beto',
    );
    final tercero = marcador.reclamar(
      zona: zonaPrueba('azul_1', azul),
      jugadorId: 'caro',
    );
    final cuarto = marcador.reclamar(
      zona: zonaPrueba('azul_1', azul),
      jugadorId: 'dani',
    );
    expect([segundo.puntos, tercero.puntos, cuarto.puntos], [6, 3, 0]);
    expect(marcador.puestosReclamados('azul_1'), 4);
    expect(marcador.puestosReclamados('verde_1'), 0);
    // Las zonas son independientes entre sí.
    final verde = marcador.reclamar(
      zona: zonaPrueba('verde_1', const TipoVerde()),
      jugadorId: 'beto',
    );
    expect(verde.puntos, 4);
    expect(marcador.puntosDe('beto'), 6 + 4);
    expect(marcador.reclamos['azul_1']!.map((r) => r.jugadorId), [
      'ana',
      'beto',
      'caro',
      'dani',
    ]);
    expect(() => marcador.reclamos.clear(), throwsUnsupportedError);
  });

  test('Liberar el último reclamo devuelve el puesto', () {
    final marcador = Marcador(jugadores: 2);
    final reclamo = marcador.reclamar(
      zona: zonaPrueba('amarillo', const TipoAmarillo()),
      jugadorId: 'ana',
    );
    final otro = marcador.reclamar(
      zona: zonaPrueba('amarillo', const TipoAmarillo()),
      jugadorId: 'beto',
    );
    expect(() => marcador.liberar(reclamo), throwsStateError);
    marcador.liberar(otro);
    marcador.liberar(reclamo);
    expect(marcador.puestosReclamados('amarillo'), 0);
    expect(marcador.puntosDe('ana'), 0);
    expect(
      marcador
          .reclamar(
            zona: zonaPrueba('amarillo', const TipoAmarillo()),
            jugadorId: 'beto',
          )
          .puntos,
      8,
    );
  });

  test('Gana quien alcanza la meta', () {
    final marcador = Marcador(jugadores: 2);
    for (final (zona, tipo) in [
      ('amarillo', const TipoAmarillo()),
      ('azul_1', const TipoAzul()),
      ('azul_2', const TipoAzul()),
    ]) {
      marcador.reclamar(zona: zonaPrueba(zona, tipo), jugadorId: 'ana');
    }
    expect(marcador.puntosDe('ana'), 22);
    expect(marcador.haGanado('ana'), isFalse);
    marcador.reclamar(
      zona: zonaPrueba('verde_1', const TipoVerde()),
      jugadorId: 'ana',
    );
    expect(marcador.puntosDe('ana'), 26);
    expect(marcador.haGanado('ana'), isTrue);
    expect(marcador.haGanado('beto'), isFalse);
  });

  test('El ranking ordena por puntos e incluye a quien no tiene', () {
    final marcador = Marcador(jugadores: 3);
    marcador.reclamar(
      zona: zonaPrueba('azul_1', const TipoAzul()),
      jugadorId: 'beto',
    );
    marcador.reclamar(
      zona: zonaPrueba('verde_1', const TipoVerde()),
      jugadorId: 'beto',
    );
    marcador.reclamar(
      zona: zonaPrueba('azul_1', const TipoAzul()),
      jugadorId: 'ana',
    );
    marcador.reclamar(
      zona: zonaPrueba('verde_2', const TipoVerde()),
      jugadorId: 'caro',
    );
    marcador.reclamar(
      zona: zonaPrueba('rojo_1', const TipoRojo()),
      jugadorId: 'caro',
    );
    final ranking = marcador.ranking(['ana', 'beto', 'caro', 'dani']);
    expect(ranking.map((p) => (p.jugadorId, p.puntos, p.posicion)), [
      ('beto', 11, 1),
      ('caro', 10, 2),
      ('ana', 6, 3),
      ('dani', 0, 4),
    ]);
    expect(ranking.first.zonasCompletadas, 2);
    expect(ranking.last.zonasCompletadas, 0);
    expect(() => ranking.clear(), throwsUnsupportedError);
  });

  test('Los empates comparten posición por ahora', () {
    final marcador = Marcador(jugadores: 3);
    marcador.reclamar(
      zona: zonaPrueba('verde_1', const TipoVerde()),
      jugadorId: 'ana',
    );
    marcador.reclamar(
      zona: zonaPrueba('verde_2', const TipoVerde()),
      jugadorId: 'beto',
    );
    expect(marcador.ranking(['ana', 'beto', 'caro']).map((p) => p.posicion), [
      1,
      1,
      3,
    ]);
  });
}
