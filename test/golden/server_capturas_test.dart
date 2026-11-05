@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/server/server_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/server_support.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final screen in ['inicio', 'direccion', 'error']) {
    testWidgets('Servidor: $screen', skip: !Platform.isMacOS, (tester) async {
      pantallaNivel(tester);
      final store = MemoryServerSettingsStore();
      final probe = FakeServerProbe();
      await tester.pumpWidget(
        BrilliantGameApp(
          serverStore: store,
          serverProbe: probe,
          authRepositoryFactory: (_) => FakeAuthRepository(),
        ),
      );
      await precargarRecursos(tester);
      if (screen != 'inicio') {
        await pulsarNivel(
          tester,
          find.byKey(const ValueKey('server_settings')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('server_address')),
          '192.168.0.31:8080',
        );
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        if (screen == 'error') {
          probe.failure = const ServerConfigurationException(
            'No se pudo conectar. Revisa la dirección, el puerto y la red Wi-Fi.',
          );
          await pulsarNivel(tester, find.byKey(const ValueKey('server_save')));
        }
      }
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/server_$screen.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
