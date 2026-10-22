@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('Selector en $size', skip: !Platform.isMacOS, (tester) async {
      pantallaNivel(tester, size: size);
      await selectorNivel(tester);
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/selector_${size.width.toInt()}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final nivel in [1, 2, 3, 4]) {
    testWidgets(
      'Recursos y tablero del Nivel $nivel',
      skip: !Platform.isMacOS,
      (tester) async {
        pantallaNivel(tester);
        await selectorNivel(tester, dados: DadosNivel([1, 1]));
        await escogerNivel(tester, nivel);
        await expectLater(
          find.byType(BrilliantGameApp),
          matchesGoldenFile('capturas/nivel_${nivel}_preparacion.png'),
        );
        await prepararNivel(tester, nivel);
        await pulsarNivel(tester, find.byKey(const ValueKey('boton_inicio')));
        await tester.ensureVisible(find.byType(TableroView));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(BrilliantGameApp),
          matchesGoldenFile('capturas/nivel_${nivel}_partida.png'),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
