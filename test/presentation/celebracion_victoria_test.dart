import 'dart:math';

import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:brilliant_game/bloc/partida_estado.dart';
import 'package:brilliant_game/bloc/partida_evento.dart';
import 'package:brilliant_game/catalogo/tablero_01.dart';
import 'package:brilliant_game/presentation/pages/partida_page.dart';
import 'package:brilliant_game/presentation/widgets/celebracion_victoria.dart';
import 'package:brilliant_game/presentation/widgets/nave_marciano.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Dados implements Random {
  final List<int> valores;
  int llamadas = 0;
  _Dados(this.valores);
  @override
  int nextInt(int max) => valores[llamadas++] - 1;
  @override
  bool nextBool() => throw UnsupportedError('Sólo dados.');
  @override
  double nextDouble() => throw UnsupportedError('Sólo dados.');
}

/// Abre una partida a cuatro jugadas de la meta y la gana con eventos del
/// BLoC, sin animaciones de por medio.
Future<PartidaBloc> _ganar(WidgetTester tester, {bool reducido = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final tablero = tablero01.crearTablero();
  const iniciales = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];
  for (var i = 0; i < iniciales.length; i++) {
    tablero.colocarValor(iniciales[i], i + 1);
  }
  for (final (zona, hueco, valor) in [
    ('azul_1', 'f1_c3', 1),
    ('azul_2', 'f5_c7', 3),
    ('morado_1', 'f1_c4', 2),
    ('morado_2', 'f4_c3', 5),
  ]) {
    for (final celda in tablero.obtenerZona(zona).celdas.values) {
      if (celda.id != hueco) tablero.colocarValor(celda.id, valor);
    }
  }
  tablero.colocarValor('f4_c7', 4);
  final bloc = PartidaBloc(
    tablero,
    azar: _Dados([1, 1, 3, 4, 2, 1, 5, 3]),
    nombreJugador: 'Babo',
  );
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reducido,
        ),
        child: BlocProvider.value(
          value: bloc,
          child: PartidaPage(
            definicion: tablero01,
            jugador: 'Babo',
            cargarMeteoritos: () async => throw StateError('Sin video'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  const destinos = ['f1_c3', 'f5_c7', 'f1_c4', 'f4_c3'];
  for (var ronda = 1; ronda <= 4; ronda++) {
    for (final evento in <PartidaEvento>[
      MeteorosCompletados(ronda),
      DadoSeleccionado(ronda, 0),
      MovimientoDadosCompletado(ronda),
    ]) {
      bloc.add(evento);
      await tester.pumpAndSettle();
    }
    bloc.add(DestinoSeleccionado(ronda, destinos[ronda - 1]));
    if (ronda < 4) {
      await tester.pumpAndSettle();
      bloc.add(MeteorosSolicitados(ronda));
      await tester.pumpAndSettle();
    }
  }
  await tester.pump();
  await tester.pump();
  return bloc;
}

double _opacidadDe(WidgetTester tester, Finder finder) => tester
    .widgetList<Opacity>(
      find.ancestor(of: finder, matching: find.byType(Opacity)),
    )
    .fold(1.0, (total, opacidad) => total * opacidad.opacity);

void main() {
  testWidgets('La secuencia completa termina una sola vez en los resultados', (
    tester,
  ) async {
    final bloc = await _ganar(tester);
    final estados = <FasePartida>[];
    final suscripcion = bloc.stream.listen((e) => estados.add(e.fase));
    addTearDown(suscripcion.cancel);
    expect(bloc.state.fase, FasePartida.celebrandoVictoria);
    expect(find.byType(CelebracionVictoria), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    // La nave original se oculta: la celebración dibuja su propia copia.
    final naves = find.byType(NaveMarciano);
    expect(naves, findsNWidgets(2));
    expect(
      [for (var i = 0; i < 2; i++) _opacidadDe(tester, naves.at(i))]..sort(),
      [0, 1],
    );
    // Durante la explosión, la nave sigue en pantalla y aparecen fragmentos.
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Toca para continuar'), findsOneWidget);
    // Reconstruir la página no reinicia la celebración.
    bloc.add(const MeteorosSolicitados(4));
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('¡Buen trabajo, has ganado!'), findsOneWidget);
    expect(find.text('26 puntos'), findsOneWidget);
    expect(estados, isEmpty);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
    expect(estados, [FasePartida.mostrandoResultados]);
    expect(find.text('RESULTADOS'), findsOneWidget);
    expect(find.byType(CelebracionVictoria), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tocar la pantalla omite la celebración', (tester) async {
    final bloc = await _ganar(tester);
    // Un toque inmediato, como un doble toque en la casilla, se ignora.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey('saltar_celebracion')));
    await tester.pump();
    await tester.pump();
    expect(bloc.state.fase, FasePartida.celebrandoVictoria);
    expect(find.text('Toca para continuar'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1750));
    expect(find.text('Toca para continuar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saltar_celebracion')));
    await tester.pump();
    await tester.pump();
    expect(bloc.state.fase, FasePartida.mostrandoResultados);
    await tester.pumpAndSettle();
    expect(find.text('RESULTADOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Con movimiento reducido sólo felicita y continúa', (
    tester,
  ) async {
    final bloc = await _ganar(tester, reducido: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('¡Buen trabajo, has ganado!'), findsOneWidget);
    expect(find.text('Toca para continuar'), findsNothing);
    expect(bloc.state.fase, FasePartida.celebrandoVictoria);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    expect(bloc.state.fase, FasePartida.mostrandoResultados);
    expect(tester.takeException(), isNull);
  });
}
