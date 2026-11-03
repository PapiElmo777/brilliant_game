@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final screen in [
    'login',
    'registro',
    'cuenta',
    'cuenta_red',
    'borrado',
  ]) {
    testWidgets('Cuenta: $screen', skip: !Platform.isMacOS, (tester) async {
      pantallaNivel(tester);
      if (['borrado', 'cuenta', 'cuenta_red'].contains(screen)) {
        final repository = FakeAuthRepository();
        await iniciarApp(tester, repository: repository);
        await pulsarNivel(tester, find.byKey(const ValueKey('account_menu')));
        if (screen == 'borrado') {
          await pulsarNivel(
            tester,
            find.byKey(const ValueKey('delete_account')),
          );
        } else if (screen == 'cuenta_red') {
          repository.failure = const AuthFailure('NETWORK_ERROR');
          await pulsarNivel(
            tester,
            find.byKey(const ValueKey('logout_account')),
          );
        }
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
