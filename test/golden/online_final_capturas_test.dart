@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../multiplayer/lobby_page_test.dart' show openRooms;
import '../multiplayer/final_rematch_page_test.dart' show losingSnapshot;
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final (name, size) in [
    ('pequeno', const Size(320, 568)),
    ('grande', const Size(390, 844)),
    ('horizontal', const Size(844, 390)),
  ]) {
    testWidgets('Ranking de derrota: $name', skip: !Platform.isMacOS, (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: 1.5);
      final repo = FakeRoomsRepository()..snapshot = losingSnapshot();
      await openRooms(tester, repo);
      await precargarRecursos(tester);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/online_derrota_ranking_$name.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final won in [true, false]) {
    testWidgets(
      'Animación final: ${won ? 'victoria' : 'derrota'}',
      skip: !Platform.isMacOS,
      (tester) async {
        pantallaNivel(tester);
        final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
        await openRooms(tester, repo);
        await precargarRecursos(tester);
        await tester.pumpAndSettle();
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: false);
        repo.publish(
          won ? scoredSnapshot(finished: true, sequence: 6) : losingSnapshot(),
          type: 'MATCH_FINISHED',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(Duration(milliseconds: won ? 2100 : 1100));
        await expectLater(
          find.byType(BrilliantGameApp),
          matchesGoldenFile(
            'capturas/online_animacion_${won ? 'victoria' : 'derrota'}.png',
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
