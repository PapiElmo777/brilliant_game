@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../multiplayer/lobby_page_test.dart' show openRooms;
import '../multiplayer/chat_page_test.dart' show chatLobby;
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
    testWidgets('Chat: $name', skip: !Platform.isMacOS, (tester) async {
      pantallaNivel(tester, size: size, escala: 1.5);
      final repo = FakeRoomsRepository()..snapshot = chatLobby();
      await openRooms(tester, repo);
      await precargarRecursos(tester);
      await tester.tap(find.byKey(const ValueKey('abrir_chat')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/chat_$name.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
