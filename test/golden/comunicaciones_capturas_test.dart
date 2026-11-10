@Tags(['golden'])
library;

import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../multiplayer/chat_page_test.dart' show chatLobby;
import '../multiplayer/lobby_page_test.dart' show openRooms;
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
    for (final chat in [false, true]) {
      testWidgets(
        '${chat ? 'Chat' : 'Top'} galáctico: $name',
        skip: !Platform.isMacOS,
        (tester) async {
          pantallaNivel(tester, size: size, escala: 1.2);
          final snapshot = scoredSnapshot();
          snapshot['match']['scores'][1]['points'] = 14;
          snapshot['match']['scores'][1]['completedZones'] = 2;
          snapshot['match']['claims'] = [
            {
              'zoneId': 'verde_1',
              'memberId': 'propio',
              'place': 1,
              'points': 4,
              'sequence': 3,
            },
            {
              'zoneId': 'azul_1',
              'memberId': 'propio',
              'place': 1,
              'points': 7,
              'sequence': 4,
            },
            {
              'zoneId': 'rojo_1',
              'memberId': 'otro',
              'place': 1,
              'points': 6,
              'sequence': 5,
            },
            {
              'zoneId': 'amarillo',
              'memberId': 'otro',
              'place': 1,
              'points': 8,
              'sequence': 6,
            },
          ];
          snapshot['messages'] = [
            ...chatLobby()['messages'],
            {
              'id': 'propio-mensaje',
              'sequence': 4,
              'kind': 'PLAYER',
              'text': 'Que la Fuerza acompañe esta tirada.',
              'authorMemberId': 'propio',
              'authorName': 'Ana',
              'serverTime': '2026-11-06T00:00:10Z',
            },
          ];
          final repo = FakeRoomsRepository()..snapshot = snapshot;
          await openRooms(tester, repo);
          await precargarRecursos(tester);
          await tester.tap(
            find.byKey(ValueKey(chat ? 'abrir_chat' : 'ranking_online')),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(BrilliantGameApp),
            matchesGoldenFile(
              'capturas/${chat ? 'chat_galactico' : 'top_galactico'}_$name.png',
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
