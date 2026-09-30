import 'dart:math';

import 'package:brilliant_game/app/tema_brilliant.dart';
import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/presentation/pages/preparacion_page.dart';
import 'package:brilliant_game/presentation/widgets/disparo_numero_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Bloquea la entrada y coloca sólo al terminar el vuelo, incluso al reconstruir',
    (tester) async {
      final definicion = CatalogoTableros.predeterminado().obtenerDefinicion(
        'tablero_01',
      );
      final bloc = InicioBloc(definicion.crearTablero(), animarEntrada: true);
      addTearDown(bloc.close);
      Widget pantalla() => MaterialApp(
        theme: TemaBrilliant.oscuro,
        home: BlocProvider.value(
          value: bloc,
          child: PreparacionPage(definicion: definicion),
        ),
      );
      await tester.pumpWidget(pantalla());
      expect(bloc.state.faseVisual, FaseVisualInicio.llegandoNave);
      expect(bloc.state.interaccionBloqueada, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      expect(bloc.state.interaccionBloqueada, isTrue);
      await tester.pumpAndSettle();
      expect(bloc.state.interaccionBloqueada, isFalse);
      await tester.tap(find.byKey(const ValueKey('numero_1')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('celda_f1_c2')));
      await tester.tap(find.byKey(const ValueKey('celda_f1_c2')));
      await tester.pump();
      expect(bloc.state.disparoPendiente, isNotNull);
      expect(bloc.state.celdas['f1_c2']!.valor, isNull);
      expect(find.byType(DisparoNumeroOverlay), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(bloc.state.celdas['f1_c2']!.valor, isNull);
      await tester.pumpWidget(pantalla());
      await tester.pumpAndSettle();
      expect(bloc.state.celdas['f1_c2']!.valor, 1);
      expect(bloc.state.disparoPendiente, isNull);
      expect(find.byType(DisparoNumeroOverlay), findsNothing);
      expect(bloc.state.numerosFaltantes.length, 5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Movimiento reducido conserva toda la preparación sin bloqueos', (
    tester,
  ) async {
    final definicion = CatalogoTableros.predeterminado().obtenerDefinicion(
      'tablero_01',
    );
    final bloc = InicioBloc(definicion.crearTablero(), animarEntrada: true);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaBrilliant.oscuro,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BlocProvider.value(
            value: bloc,
            child: PreparacionPage(definicion: definicion),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(bloc.state.interaccionBloqueada, isFalse);
    var numero = 1;
    for (final celda in bloc.state.celdas.values.where((c) => c.esInicio)) {
      final ficha = find.byKey(ValueKey('numero_$numero'));
      await tester.ensureVisible(ficha);
      await tester.tap(ficha);
      await tester.pumpAndSettle();
      final destino = find.byKey(ValueKey('celda_${celda.id}'));
      await tester.ensureVisible(destino);
      await tester.tap(destino);
      await tester.pumpAndSettle();
      expect(bloc.state.celdas[celda.id]!.valor, numero++);
    }
    expect(bloc.state.puedeIniciar, isTrue);
    final inicio = find.byKey(const ValueKey('boton_inicio'));
    await tester.ensureVisible(inicio);
    await tester.tap(inicio);
    await tester.pumpAndSettle();
    expect(bloc.state.fase, FaseInicio.iniciado);
    expect(tester.hasRunningAnimations, isFalse);
  });
  testWidgets(
    'El destino permanece fijo al terminar el vuelo en teléfono pequeño',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final definicion = CatalogoTableros.predeterminado().obtenerDefinicion(
        'tablero_01',
      );
      final bloc = InicioBloc(definicion.crearTablero());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaBrilliant.oscuro,
          home: BlocProvider.value(
            value: bloc,
            child: PreparacionPage(definicion: definicion),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('numero_1')));
      await tester.pumpAndSettle();
      final celda = find.byKey(const ValueKey('celda_f1_c2'));
      await tester.ensureVisible(celda);
      final centro = tester.getCenter(celda);
      await tester.tap(celda);
      await tester.pumpAndSettle();
      expect(tester.getCenter(celda), centro);
      expect(bloc.state.celdas['f1_c2']!.valor, 1);
    },
  );

  testWidgets('El acomodo aleatorio anima cada disparo hasta completar', (
    tester,
  ) async {
    final definicion = CatalogoTableros.predeterminado().obtenerDefinicion(
      'tablero_01',
    );
    final bloc = InicioBloc(
      definicion.crearTablero(),
      animarEntrada: true,
      aleatorio: Random(11),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaBrilliant.oscuro,
        home: BlocProvider.value(
          value: bloc,
          child: PreparacionPage(definicion: definicion),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final aleatorio = find.byKey(const ValueKey('boton_aleatorio'));
    await tester.ensureVisible(aleatorio);
    await tester.tap(aleatorio);
    await tester.pump();
    expect(find.byType(DisparoNumeroOverlay), findsOneWidget);
    expect(bloc.state.numerosFaltantes.length, 6);
    final ids = <int>{};
    while (bloc.state.disparoPendiente != null) {
      ids.add(bloc.state.disparoPendiente!.id);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(ids.length, 6);
    expect(bloc.state.numerosFaltantes, isEmpty);
    expect(bloc.state.puedeIniciar, isTrue);
    expect(find.byType(DisparoNumeroOverlay), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
