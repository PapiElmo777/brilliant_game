@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final screen in ['login', 'registro', 'borrado']) {
    testWidgets('Cuenta: $screen', skip: !Platform.isMacOS, (tester) async {
      pantallaNivel(tester);
      if (screen == 'borrado') {
        await iniciarApp(tester);
        await pulsarNivel(tester, find.byKey(const ValueKey('account_menu')));
        await pulsarNivel(tester, find.byKey(const ValueKey('delete_account')));
      } else {
        await tester.pumpWidget(
          BrilliantGameApp(authRepository: FakeAuthRepository()),
        );
        await precargarRecursos(tester);
        if (screen == 'registro') {
          await pulsarNivel(tester, find.byKey(const ValueKey('auth_switch')));
        }
      }
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/auth_$screen.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
