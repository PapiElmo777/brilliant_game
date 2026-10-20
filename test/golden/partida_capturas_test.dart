@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math';

import 'package:brilliant_game/app/tema_brilliant.dart';
import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:brilliant_game/bloc/partida_estado.dart';
import 'package:brilliant_game/catalogo/tablero_01.dart';
import 'package:brilliant_game/presentation/pages/partida_page.dart';
import 'package:brilliant_game/presentation/widgets/fondo_espacial.dart';
import 'package:brilliant_game/presentation/widgets/resultados_partida.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fuentes_prueba.dart';

class _TiradaDosCinco implements Random {
  int _indice = 0;
  @override
  int nextInt(int max) => [2, 5][_indice++] - 1;
  @override
  bool nextBool() => throw UnsupportedError('Sólo dados');
  @override
  double nextDouble() => throw UnsupportedError('Sólo dados');
}

void main() {
  setUpAll(cargarFuentesPrueba);

  for (final estado in ['resultados', 'destinos', 'historial']) {
    testWidgets('Partida: $estado', skip: !Platform.isMacOS, (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final tablero = tablero01.crearTablero();
      const iniciales = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];
      for (var i = 0; i < iniciales.length; i++) {
        tablero.colocarValor(iniciales[i], i + 1);
      }
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TemaBrilliant.oscuro,
          home: BlocProvider(
            create: (_) => PartidaBloc(tablero, azar: _TiradaDosCinco()),
            child: PartidaPage(definicion: tablero01, jugador: 'Ana'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (estado != 'resultados') {
        await tester.tap(find.byKey(const ValueKey('dado_1')));
        await tester.pumpAndSettle();
      }
      if (estado == 'historial') {
        await tester.tap(find.byKey(const ValueKey('celda_f2_c7')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiradas · 1  (2 · 5)'));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('capturas/partida_$estado.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Victoria: menú de resultados', skip: !Platform.isMacOS, (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TemaBrilliant.oscuro,
        home: Scaffold(
          body: FondoEspacial(
            child: SafeArea(
              child: ResultadosPartida(
                resultados: const [
                  ResultadoJugador(
                    jugadorId: 'jugador_1',
                    nombre: 'Ana',
                    puntos: 26,
                    zonasCompletadas: 4,
                    posicion: 1,
                    esLocal: true,
                  ),
                ],
                meta: 26,
                onEmpezarDeNuevo: () {},
                onSalirAlMenu: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('capturas/partida_victoria.png'),
    );
  });
}
