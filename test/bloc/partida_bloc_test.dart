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
  test('Tocar una casilla sin número elegido o no válida avisa sin colocar', () async {
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
  });
  test('La jugada se puede mover, retirar o cambiar de dado antes de lanzar', () async {
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
  });
}
