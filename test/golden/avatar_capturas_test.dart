@Tags(['golden'])
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import '../support/auth_support.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final scene in ['bienvenida', 'avatar', 'selector']) {
    testWidgets('Cuenta: $scene', skip: !Platform.isMacOS, (tester) async {
      pantallaNivel(tester, size: const Size(390, 844), escala: 1.5);
      final repo = FakeAuthRepository(name: 'Pepe');
      if (scene == 'avatar') repo.avatarId = 'tablero_03';
      await iniciarApp(tester, repository: repo);
      if (scene != 'bienvenida') {
        await tester.tap(find.byKey(const ValueKey('account_menu')));
        await tester.pumpAndSettle();
      }
      if (scene == 'selector') {
        await tester.tap(find.byKey(const ValueKey('seleccionar_avatar')));
        await tester.pumpAndSettle();
      }
      await precargarRecursos(tester);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/cuenta_$scene.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
