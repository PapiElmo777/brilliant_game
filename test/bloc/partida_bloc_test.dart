import 'dart:math';
import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:brilliant_game/bloc/partida_evento.dart';
import 'package:brilliant_game/bloc/partida_estado.dart';
import 'package:brilliant_game/models/tirada.dart';
import 'package:flutter_test/flutter_test.dart';

class AzarFijo implements Random {
  final List<int> valores;
  int llamadas = 0;
  AzarFijo(this.valores);
  @override
  int nextInt(int max) => valores[llamadas++ % valores.length] - 1;
  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

Tablero tablero({bool lleno = false}) => Tablero(
  id: 't',
  zonas: [
    Zona(
      id: 'v',
      tipo: const TipoVerde(),
      celdas: [
        Celda(id: 'a', fila: 0, columna: 0, valorInicial: 2),
        Celda(id: 'b', fila: 0, columna: 1, valorInicial: lleno ? 1 : null),
        Celda(id: 'c', fila: 0, columna: 2, valorInicial: 5),
        Celda(id: 'd', fila: 1, columna: 2, valorInicial: lleno ? 1 : null),
      ],
    ),
  ],
);
Future<void> enviar(PartidaBloc b, PartidaEvento e) async {
  b.add(e);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('Azar uniforme por dos llamadas independientes y admite dobles', () {
    final azar = AzarFijo([1, 6, 4, 4]);
    final t = Tirada.lanzar(1, azar);
    expect(t.dados.map((d) => d.valor), [1, 6]);
    final doble = Tirada.lanzar(2, azar);
    expect(doble.dados.map((d) => d.valor), [4, 4]);
    expect(doble.dados.map((d) => d.id).toSet().length, 2);
    expect(azar.llamadas, 4);
    expect(() => Tirada(1, 0, 2), throwsArgumentError);
    expect(() => Tirada(1, 2, 7), throwsArgumentError);
  });
  test(
    'Bloqueo, intercambio, colocación única, historial y siguiente tiro manual',
    () async {
      final fuente = tablero();
      final azar = AzarFijo([2, 5]);
      final b = PartidaBloc(fuente, azar: azar);
      addTearDown(b.close);
      expect(azar.llamadas, 2);
      await enviar(b, const MeteorosSolicitados(1));
      await enviar(b, const DadoSeleccionado(1, 1));
      await enviar(b, const TiroOmitido(1));
      expect(b.state.fase, FasePartida.tirando);
      await enviar(b, const ImpactoConfirmado(1));
      expect(b.state.fase, FasePartida.revelandoResultados);
      await enviar(b, const MeteorosCompletados(99));
      await enviar(b, const MeteorosCompletados(1));
      await enviar(b, const DadoSeleccionado(1, 1));
      expect(b.state.ancla!.valor, 2);
      expect(b.state.fase, FasePartida.moviendoDados);
      await enviar(b, const DadoSeleccionado(1, 0));
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      expect(b.state.historial, isEmpty);
      await enviar(b, const MovimientoDadosCompletado(1));
      expect(b.state.destinos, {'b'});
      await enviar(b, const DadoSeleccionado(1, 0));
      expect(b.state.destinos, {'b', 'd'});
      expect(b.state.ancla!.valor, 5);
      await enviar(b, const DestinoSeleccionado(1, 'a'));
      expect(b.state.error, isNotNull);
      expect(b.state.historial, isEmpty);
      await enviar(b, const TiroOmitido(1));
      expect(b.state.historial, isEmpty);
      final anterior = b.state;
      await enviar(b, const DestinoSeleccionado(1, 'd'));
      expect(b.state.historial.single.dadoId, 0);
      expect(b.state.historial.single.celdaId, 'd');
      expect(b.state.celdas['d']!.valor, 2);
      expect(anterior.celdas['d']!.valor, isNull);
      expect(fuente.obtenerCelda('d').valor, isNull);
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      await enviar(b, const MeteorosCompletados(1));
      expect(b.state.historial.length, 1);
      expect(azar.llamadas, 2);
      await enviar(b, const MeteorosSolicitados(1));
      await enviar(b, const MeteorosSolicitados(1));
      expect(azar.llamadas, 4);
      expect(b.state.tirada.id, 2);
      expect(b.state.destinos, isEmpty);
      expect(b.state.dadoSeleccionado, isNull);
      await enviar(b, const MeteorosCompletados(1));
      expect(b.state.fase, FasePartida.tirando);
    },
  );
  test('Omisión solo cuando ambas opciones carecen de destinos', () async {
    final b = PartidaBloc(tablero(lleno: true), azar: AzarFijo([2, 5]));
    addTearDown(b.close);
    final antes = b.state.celdas;
    await enviar(b, const MeteorosCompletados(1));
    expect(b.state.puedeOmitir, isTrue);
    await enviar(b, const TiroOmitido(1));
    await enviar(b, const TiroOmitido(1));
    expect(b.state.historial.single.resultado, ResultadoRonda.omitida);
    expect(b.state.historial.single.dadoId, isNull);
    expect(b.state.celdas, antes);
  });
  test('Dobles conservan identidad del dado escrito', () async {
    final b = PartidaBloc(tablero(), azar: AzarFijo([2, 2]));
    addTearDown(b.close);
    await enviar(b, const MeteorosCompletados(1));
    await enviar(b, const DadoSeleccionado(1, 1));
    await enviar(b, const MovimientoDadosCompletado(1));
    final destinos = b.state.destinos;
    await enviar(b, const DadoSeleccionado(1, 0));
    expect(b.state.destinos, destinos);
    await enviar(b, const DadoSeleccionado(1, 1));
    await enviar(b, const DestinoSeleccionado(1, 'b'));
    expect(b.state.historial.single.dadoId, 1);
    expect(b.state.celdas.values.where((c) => c.valor != null).length, 3);
  });
  test(
    'Sin destinos para selección actual no permite omitir si la otra sirve',
    () async {
      final b = PartidaBloc(tablero(), azar: AzarFijo([2, 6]));
      addTearDown(b.close);
      await enviar(b, const MeteorosCompletados(1));
      await enviar(b, const DadoSeleccionado(1, 0));
      await enviar(b, const MovimientoDadosCompletado(1));
      expect(b.state.destinos, isEmpty);
      expect(b.state.puedeOmitir, isFalse);
      await enviar(b, const TiroOmitido(1));
      expect(b.state.historial, isEmpty);
      await enviar(b, const DadoSeleccionado(1, 1));
      expect(b.state.destinos, {'b'});
    },
  );
  test(
    'Tocar una casilla sin número elegido o no válida avisa sin colocar',
    () async {
      final b = PartidaBloc(tablero(), azar: AzarFijo([2, 5]));
      addTearDown(b.close);
      await enviar(b, const MeteorosCompletados(1));
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      expect(b.state.error, 'Primero elige un número.');
      await enviar(b, const DadoSeleccionado(1, 1));
      await enviar(b, const MovimientoDadosCompletado(1));
      expect(b.state.error, isNull);
      await enviar(b, const DestinoSeleccionado(1, 'd'));
      expect(b.state.error, contains('no es válida'));
      expect(b.state.celdas['d']!.valor, isNull);
      expect(b.state.historial, isEmpty);
    },
  );
  test(
    'La jugada se puede mover, retirar o cambiar de dado antes de lanzar',
    () async {
      final b = PartidaBloc(tablero(), azar: AzarFijo([2, 5]));
      addTearDown(b.close);
      await enviar(b, const MeteorosCompletados(1));
      await enviar(b, const DadoSeleccionado(1, 0));
      await enviar(b, const MovimientoDadosCompletado(1));
      await enviar(b, const DestinoSeleccionado(1, 'd'));
      expect(b.state.fase, FasePartida.rondaResuelta);
      expect(b.state.puedeModificar, isTrue);
      expect(b.state.destinos, {'b', 'd'});
      // Mover a otro destino válido conserva un solo registro.
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      expect(b.state.celdas['b']!.valor, 2);
      expect(b.state.celdas['d']!.valor, isNull);
      expect(b.state.historial.single.celdaId, 'b');
      // Una casilla no válida avisa sin cambiar la jugada.
      await enviar(b, const DestinoSeleccionado(1, 'a'));
      expect(b.state.error, isNotNull);
      expect(b.state.celdas['b']!.valor, 2);
      // Tocar el número escrito lo retira.
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      expect(b.state.fase, FasePartida.eligiendoDestino);
      expect(b.state.celdas['b']!.valor, isNull);
      expect(b.state.historial, isEmpty);
      // Cambiar de dado tras colocar deshace la colocación.
      await enviar(b, const DestinoSeleccionado(1, 'd'));
      await enviar(b, const DadoSeleccionado(1, 1));
      expect(b.state.fase, FasePartida.eligiendoDestino);
      expect(b.state.celdas['d']!.valor, isNull);
      expect(b.state.historial, isEmpty);
      expect(b.state.destinos, {'b'});
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      expect(b.state.historial.single.dadoId, 1);
      await enviar(b, const TiroOmitido(1));
      expect(b.state.historial.length, 1);
      // Al lanzar, la jugada queda fija.
      await enviar(b, const MeteorosSolicitados(1));
      expect(b.state.puedeModificar, isFalse);
      expect(b.state.celdas['b']!.valor, 5);
      await enviar(b, const DestinoSeleccionado(1, 'b'));
      expect(b.state.celdas['b']!.valor, 5);
    },
  );

  test(
    'Completar una zona reclama el primer puesto y suma sus puntos',
    () async {
      // Zona azul de dos casillas: al escribir la segunda queda completa.
      final b = PartidaBloc(
        Tablero(
          id: 't',
          zonas: [
            Zona(
              id: 'azul',
              tipo: const TipoAzul(),
              celdas: [
                Celda(id: 'x', fila: 0, columna: 0, valorInicial: 2),
                Celda(id: 'y', fila: 0, columna: 1),
              ],
            ),
            Zona(
              id: 'verde',
              tipo: const TipoVerde(),
              celdas: [Celda(id: 'z', fila: 1, columna: 0)],
            ),
          ],
        ),
        azar: AzarFijo([2, 2]),
      );
      addTearDown(b.close);
      expect((b.state.puntos, b.state.meta), (0, 26));
      await enviar(b, const MeteorosCompletados(1));
      await enviar(b, const DadoSeleccionado(1, 0));
      await enviar(b, const MovimientoDadosCompletado(1));
      expect(b.state.destinos, {'y', 'z'});
      await enviar(b, const DestinoSeleccionado(1, 'y'));
      expect(b.state.puntos, 7);
      expect(b.state.reclamoRonda!.puesto, 1);
      expect(b.state.puestosReclamados, {'azul': 1});
      // Mover la jugada a otra zona libera el reclamo.
      await enviar(b, const DestinoSeleccionado(1, 'z'));
      expect(b.state.puntos, 4);
      expect(b.state.puestosReclamados, {'verde': 1});
      await enviar(b, const DestinoSeleccionado(1, 'z'));
      expect(b.state.puntos, 0);
      expect(b.state.puestosReclamados, isEmpty);
      await enviar(b, const DestinoSeleccionado(1, 'y'));
      await enviar(b, const MeteorosSolicitados(1));
      // Al lanzar, el reclamo queda fijo.
      expect(b.state.puntos, 7);
      expect(b.state.reclamoRonda, isNull);
    },
  );

  test('Llegar a la meta termina la partida y muestra el ranking', () async {
    // Con cinco jugadores la meta es 20: dos zonas amarillas (8 + 8) y una
    // verde (4), completadas en tres rondas con dobles de 3.
    Zona zona(String id, Tipo tipo, int columna, [int? valor]) => Zona(
      id: id,
      tipo: tipo,
      celdas: [
        Celda(id: 'c$columna', fila: 0, columna: columna, valorInicial: valor),
      ],
    );
    final b = PartidaBloc(
      Tablero(
        id: 't',
        zonas: [
          zona('inicio', const TipoVerde(), 0, 3),
          zona('amarillo_1', const TipoAmarillo(), 1),
          zona('amarillo_2', const TipoAmarillo(), 2),
          zona('verde', const TipoVerde(), 3),
        ],
      ),
      azar: AzarFijo([3]),
      jugadores: 5,
      nombreJugador: 'Babo',
    );
    addTearDown(b.close);
    expect(b.state.meta, 20);
    for (final (ronda, celda) in [(1, 'c1'), (2, 'c2'), (3, 'c3')]) {
      await enviar(b, MeteorosCompletados(ronda));
      await enviar(b, DadoSeleccionado(ronda, 0));
      await enviar(b, MovimientoDadosCompletado(ronda));
      await enviar(b, DestinoSeleccionado(ronda, celda));
      expect(b.state.gano, ronda == 3);
      await enviar(b, MeteorosSolicitados(ronda));
    }
    // Las zonas completas desde el inicio no se reclaman solas.
    expect(b.state.puestosReclamados.keys, [
      'amarillo_1',
      'amarillo_2',
      'verde',
    ]);
    expect(b.state.puntos, 20);
    expect(b.state.fase, FasePartida.celebrandoVictoria);
    expect(b.state.partidaTerminada, isTrue);
    expect(b.state.tirada.id, 3);
    expect(b.state.historial.length, 3);
    // La jugada ganadora es definitiva: no se retira, ni se cambia de dado,
    // ni se omite, ni se lanza otra tirada.
    for (final evento in <PartidaEvento>[
      const DestinoSeleccionado(3, 'c3'),
      const DadoSeleccionado(3, 1),
      const TiroOmitido(3),
      const MeteorosSolicitados(3),
      const CelebracionCompletada(2),
    ]) {
      await enviar(b, evento);
      expect(b.state.fase, FasePartida.celebrandoVictoria);
      expect(b.state.celdas['c3']!.valor, 3);
      expect(b.state.puntos, 20);
    }
    expect(b.state.destinos, isEmpty);
    expect(b.state.puedeSeleccionar, isFalse);
    expect(b.state.resultados, isEmpty);
    // La celebración se confirma una sola vez.
    await enviar(b, const CelebracionCompletada(3));
    expect(b.state.fase, FasePartida.mostrandoResultados);
    final estado = b.state;
    await enviar(b, const CelebracionCompletada(3));
    expect(identical(b.state, estado), isTrue);
    expect(
      b.state.resultados.map(
        (r) => (r.nombre, r.puntos, r.zonasCompletadas, r.posicion, r.esLocal),
      ),
      [('Babo', 20, 3, 1, true)],
    );
  });

  test('Volver a tirar da dos dados nuevos una vez por ronda', () async {
    final azar = AzarFijo([2, 5, 6, 6, 2, 2, 1, 1, 3, 3]);
    final b = PartidaBloc(tablero(), azar: azar);
    addTearDown(b.close);
    // No se puede mientras caen los meteoros.
    await enviar(b, const DadosRelanzados(1));
    expect(azar.llamadas, 2);
    await enviar(b, const MeteorosCompletados(1));
    expect(b.state.puedeRelanzar, isTrue);
    await enviar(b, const DadoSeleccionado(1, 0));
    await enviar(b, const MovimientoDadosCompletado(1));
    await enviar(b, const DadosRelanzados(1));
    // Nueva tirada: vuelven a caer los meteoros y se limpia la selección.
    expect(b.state.fase, FasePartida.tirando);
    expect(b.state.tirada.id, 2);
    expect(b.state.tirada.dados.map((d) => d.valor), [6, 6]);
    expect(b.state.dadoSeleccionado, isNull);
    expect(b.state.relanzamientosRestantes, 0);
    await enviar(b, const MeteorosCompletados(1));
    expect(b.state.fase, FasePartida.tirando);
    await enviar(b, const MeteorosCompletados(2));
    expect(b.state.puedeRelanzar, isFalse);
    await enviar(b, const DadosRelanzados(2));
    expect(azar.llamadas, 4);
    // Tirando 6 y 6 no hay destinos: se omite y la ronda cuenta una vez.
    await enviar(b, const TiroOmitido(2));
    expect(b.state.historial.single.tirada.dados.map((d) => d.valor), [6, 6]);
    // La siguiente ronda vuelve a permitirlo, pero no después de escribir.
    await enviar(b, const MeteorosSolicitados(2));
    await enviar(b, const MeteorosCompletados(3));
    expect(b.state.puedeRelanzar, isTrue);
    await enviar(b, const DadoSeleccionado(3, 0));
    await enviar(b, const MovimientoDadosCompletado(3));
    await enviar(b, const DestinoSeleccionado(3, 'b'));
    expect(b.state.puedeRelanzar, isFalse);
    await enviar(b, const DadosRelanzados(3));
    expect(b.state.fase, FasePartida.rondaResuelta);
    expect(azar.llamadas, 6);
  });
}
