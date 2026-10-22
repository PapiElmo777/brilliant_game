import 'package:brilliant_game/catalogo/catalogo_tableros.dart';
import 'dart:math';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/presentation/widgets/nave_marciano.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'recorridos_niveles.dart';

class DadosNivel implements Random {
  final List<int> valores;
  int llamadas = 0;
  DadosNivel(this.valores);
  @override
  int nextInt(int max) {
    expect(max, 6);
    return valores[llamadas++] - 1;
  }

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

void pantallaNivel(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double escala = 1,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> pulsarNivel(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Future<void> precargarRecursos(WidgetTester tester) async {
  final context = tester.element(find.byType(Navigator).first);
  await tester.runAsync(
    () => Future.wait([
      for (final nivel in CatalogoTableros.predeterminado().definiciones.values)
        for (final ruta in [
          nivel.recursos!.miniatura,
          nivel.recursos!.fondo,
          nivel.recursos!.nave,
        ])
          precacheImage(AssetImage(ruta), context),
    ]),
  );
  await tester.pumpAndSettle();
}

Future<void> selectorNivel(WidgetTester tester, {Random? dados}) async {
  await tester.pumpWidget(BrilliantGameApp(azarPartida: dados));
  await precargarRecursos(tester);
  await pulsarNivel(tester, find.text('NUEVA PARTIDA'));
  expect(find.byType(TextField), findsNothing);
}

Future<void> escogerNivel(WidgetTester tester, int nivel) async {
  final tarjeta = find.byKey(ValueKey('elegir_tablero_0$nivel'));
  if (tarjeta.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      tarjeta,
      250,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await pulsarNivel(tester, tarjeta);
  expect(find.text('Nivel $nivel · ¿Cómo te llamas?'), findsOneWidget);
  await tester.enterText(find.byKey(const ValueKey('campo_nombre')), 'Ana');
  await tester.pump();
  await pulsarNivel(tester, find.byKey(const ValueKey('confirmar_nombre')));
}

Future<void> prepararNivel(WidgetTester tester, int nivel) async {
  for (final (id, valor) in preparacionesNiveles[nivel]!) {
    await pulsarNivel(tester, find.byKey(ValueKey('numero_$valor')));
    await pulsarNivel(tester, find.byKey(ValueKey('celda_$id')));
  }
}

void naveDelNivel(WidgetTester tester, int nivel) {
  final naves = tester.widgetList<NaveMarciano>(find.byType(NaveMarciano));
  expect(naves, isNotEmpty);
  expect(naves.every((n) => n.recursos?.numero == nivel), isTrue);
}
