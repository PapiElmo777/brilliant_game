import 'dart:math';
import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalogo = CatalogoTableros.predeterminado();
  const matrices = {
    2: [
      'MMM BVVV',
      'MACCCAV',
      'MRRCCRV',
      'RRRARRR',
      'VRCCRRM',
      'VACCCAM',
      'VVVBMMM',
    ],
    3: [
      'AAMBMAA',
      'BAMMMAB',
      'RRRMRRR',
      'RRRBRRR',
      'VCCCCCV',
      'VVVVVVV',
      'MMMBMMM',
    ],
    4: [
      'NNNNNNN',
      'ARCVCRA',
      'RRMMMRR',
      'AVCMCVA',
      'RRMMMRR',
      'ARCVCRA',
      'NNNNNNN',
    ],
  };
  const iniciales = {
    2: {'f1_c5', 'f3_c1', 'f4_c3', 'f5_c6', 'f6_c2', 'f7_c5'},
    3: {'f2_c3', 'f2_c6', 'f4_c4', 'f5_c2', 'f5_c7', 'f7_c3'},
    4: {'f1_c5', 'f3_c3', 'f3_c6', 'f4_c1', 'f6_c5', 'f7_c2'},
  };
  const puntos = {
    2: {
      'blanco': [3, 2, 1],
      'amarillo': [6, 4, 2],
      'rojo': [6, 4, 2],
      'verde': [4, 3, 2],
      'azul': [7, 6, 3],
      'morado': [6, 4, 2],
    },
    3: {
      'blanco': [8, 6, 4],
      'amarillo': [7, 5, 3],
      'rojo': [6, 4, 2],
      'verde': [6, 5, 4],
      'azul': [7, 5, 3],
      'morado': [7, 5, 3],
    },
    4: {
      'naranja': [6, 4, 3],
      'amarillo': [8, 6, 4],
      'rojo': [6, 4, 2],
      'verde': [3, 2, 1],
      'azul': [8, 6, 4],
      'morado': [7, 5, 3],
    },
  };
  String simbolo(Tipo t) => switch (t) {
    TipoBlanco() => 'B',
    TipoAzul() => 'C',
    TipoAmarillo() => 'A',
    TipoRojo() => 'R',
    TipoVerde() => 'V',
    TipoMorado() => 'M',
    TipoNaranja() => 'N',
    _ => '?',
  };
  for (final n in [2, 3, 4]) {
    test('Nivel $n: matriz, iniciales, agrupaciones y puntos exactos', () {
      final def = catalogo.obtenerDefinicion('tablero_0$n');
      final tablero = def.crearTablero();
      expect(tablero.zonas.length, n == 2 ? 10 : 8);
      expect(tablero.celdas.length, 49);
      expect(
        tablero.celdas.values.where((c) => c.esInicio).map((c) => c.id).toSet(),
        iniciales[n],
      );
      for (var f = 0; f < 7; f++) {
        expect(
          [
            for (var c = 0; c < 7; c++)
              simbolo(tablero.obtenerZonaDeCelda('f${f + 1}_c${c + 1}').tipo),
          ].join(),
          matrices[n]![f].replaceAll(' ', ''),
        );
      }
      for (final zona in def.zonas) {
        final esperados = puntos[n]![zona.id.split('_').first]!;
        expect(puntosDeZona(zona), esperados);
        expect(tablero.obtenerZona(zona.id).puntuaciones.values, esperados);
        final marcador = Marcador(jugadores: 5);
        expect(
          [
            for (var puesto = 1; puesto <= 5; puesto++)
              marcador
                  .reclamar(zona: zona.crearZona(), jugadorId: 'j$puesto')
                  .puntos,
          ],
          [...esperados, 0, 0],
        );
      }
      // Regions that share a color remain independent; split cells stay together.
      expect(tablero.obtenerZona('amarillo').celdas.length, n == 2 ? 5 : 6);
      expect(tablero.obtenerZona('rojo_1').celdas.length, 6);
      expect(tablero.obtenerZona('rojo_2').celdas.length, 6);
      expect(
        tablero.obtenerZona('verde${n == 2 ? '_1' : ''}').celdas.length,
        n == 2
            ? 5
            : n == 3
            ? 9
            : 4,
      );
      expect(
        tablero.obtenerZona('azul${n == 2 ? '_1' : ''}').celdas.length,
        n == 2
            ? 5
            : n == 3
            ? 5
            : 6,
      );
      expect(
        tablero.obtenerZona('morado${n == 4 ? '' : '_1'}').celdas.length,
        n == 2
            ? 5
            : n == 3
            ? 6
            : 7,
      );
      if (n < 4)
        expect(tablero.obtenerZona('blanco').celdas.length, n == 2 ? 2 : 5);
    });
    test(
      'Nivel $n: preparación parcial y copias conservan puntos e independencia',
      () async {
        final def = catalogo.obtenerDefinicion('tablero_0$n');
        final preparacion = PreparacionInicial(def.crearTablero());
        final distribucion = preparacion.distribucionAleatoria(Random(41));
        preparacion.colocarValor(distribucion.first.$1, distribucion.first.$2);
        for (final (celda, valor) in preparacion.distribucionAleatoria(
          Random(8),
        )) {
          preparacion.colocarValor(celda, valor);
        }
        expect(preparacion.estaLista, isTrue);
        final juego = preparacion.crearTableroParaJuego();
        final bloc = PartidaBloc(juego);
        addTearDown(bloc.close);
        for (final zona in def.zonas) {
          expect(juego.obtenerZona(zona.id).puntuaciones, zona.puntuaciones);
        }
        final otra = def.crearTablero();
        expect(otra.celdas.values.every((c) => !c.estaOcupada), isTrue);
        expect(bloc.state.celdas.values.where((c) => c.estaOcupada).length, 6);
      },
    );
  }
  test(
    'Blanco conectado por regla; naranja independiente y con repeticiones',
    () {
      final blanco = catalogo.crearTablero('tablero_03');
      blanco.colocarValor('f1_c4', 2);
      expect(() => blanco.colocarValor('f7_c4', 3), throwsArgumentError);
      blanco.colocarValor('f7_c4', 2);
      expect(blanco.obtenerZona('blanco').estaCompletada, isFalse);
      final naranja = catalogo.crearTablero('tablero_04');
      for (var c = 1; c <= 7; c++) {
        naranja.colocarValor('f1_c$c', 4);
        naranja.colocarValor('f7_c$c', 1);
      }
      expect(naranja.obtenerZona('naranja_1').estaCompletada, isTrue);
      expect(naranja.obtenerZona('naranja_2').estaCompletada, isTrue);
      expect(() => naranja.colocarValor('f1_c1', 3), throwsArgumentError);
      expect(() => naranja.colocarValor('f7_c1', 4), throwsArgumentError);
      final marcador = Marcador(jugadores: 2);
      for (final id in ['naranja_1', 'naranja_2'])
        marcador.reclamar(zona: naranja.obtenerZona(id), jugadorId: 'ana');
      expect(marcador.puntosDe('ana'), 12);
    },
  );
  test(
    'Naranja valida límites; intercambios inválidos y sin solución no mutan',
    () {
      for (final grupo in GrupoNaranja.values) {
        final tipo = TipoNaranja(grupo);
        for (var n = 0; n <= 7; n++)
          expect(
            tipo.esPosibleAgregar([], n),
            grupo == GrupoNaranja.alto ? n >= 4 && n <= 6 : n >= 1 && n <= 3,
          );
      }
      final prep = PreparacionInicial(catalogo.crearTablero('tablero_04'));
      prep.colocarValor('f1_c5', 4);
      prep.colocarValor('f7_c2', 1);
      expect(() => prep.intercambiar('f1_c5', 'f7_c2'), throwsArgumentError);
      expect(prep.celdas['f1_c5']!.valor, 4);
      prep.reiniciar();
      for (final (id, v) in [('f3_c3', 1), ('f3_c6', 2), ('f4_c1', 3)])
        prep.colocarValor(id, v);
      expect(() => prep.distribucionAleatoria(Random(2)), throwsStateError);
      expect(prep.celdas.values.where((c) => c.estaOcupada).length, 3);
    },
  );
  test('Puntuaciones se validan y son inmutables', () {
    final def = catalogo.obtenerDefinicion('tablero_03').zonas.first;
    expect(() => def.puntuaciones[1] = 99, throwsUnsupportedError);
    expect(
      () => Zona(
        id: 'z',
        tipo: const TipoVerde(),
        celdas: def.celdas,
        puntuaciones: {1: 1, 2: 2, 3: 0},
      ),
      throwsArgumentError,
    );
    expect(
      () => Zona(
        id: 'z',
        tipo: const TipoVerde(),
        celdas: def.celdas,
        puntuaciones: {1: 1},
      ),
      throwsArgumentError,
    );
  });
}
