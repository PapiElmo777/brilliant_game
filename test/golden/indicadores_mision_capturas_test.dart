@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/catalogo/catalogo_tableros.dart';
import 'package:brilliant_game/core/preparacion_inicial.dart';
import 'package:brilliant_game/core/anclas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../multiplayer/lobby_page_test.dart' show openRooms;
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'fuentes_prueba.dart';

void main() {
  setUpAll(cargarFuentesPrueba);
  for (final (name, level, claims, seconds, size, scale) in [
    ('nivel1', 'tablero_01', 0, 60, const Size(390, 844), 1.0),
    ('nivel2', 'tablero_02', 0, 60, const Size(390, 844), 1.0),
    ('nivel3', 'tablero_03', 0, 60, const Size(390, 844), 1.0),
    ('nivel4', 'tablero_04', 0, 60, const Size(390, 844), 1.0),
    ('premio1', 'tablero_01', 1, 45, const Size(390, 844), 1.0),
    ('premio2', 'tablero_01', 2, 45, const Size(390, 844), 1.0),
    ('premio3', 'tablero_01', 3, 45, const Size(390, 844), 1.0),
    ('tiempo30', 'tablero_01', 0, 30, const Size(390, 844), 1.0),
    ('tiempo10', 'tablero_01', 0, 10, const Size(390, 844), 1.0),
    ('tiempo10_pequeno', 'tablero_04', 2, 10, const Size(320, 568), 2.0),
    ('tiempo10_horizontal', 'tablero_03', 3, 10, const Size(844, 390), 2.0),
  ]) {
    testWidgets('Indicadores de misión: $name', skip: !Platform.isMacOS, (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: scale);
      final definition = CatalogoTableros.predeterminado().obtenerDefinicion(
        level,
      );
      final prep = PreparacionInicial(definition.crearTablero());
      final placements = {
        for (final (id, value) in prep.distribucionAleatoria(Random(19)))
          id: value,
      };
      final snapshot = onlineSnapshot(
        prepared: true,
        playing: true,
        board: placements,
      );
      snapshot['room']['levelId'] = level;
      snapshot['match']['levelId'] = level;
      snapshot['match']['zones'] = [
        for (final zone in definition.zonas)
          {
            'zoneId': zone.id,
            'nextPlace': zone.id == 'verde_1' ? claims + 1 : 1,
            'nextPoints': claims >= 3 ? 0 : 4,
          },
      ];
      snapshot['serverTime'] = DateTime.utc(
        2026,
        11,
        6,
        0,
        0,
        60 - seconds,
      ).toIso8601String();
      final repo = FakeRoomsRepository()..snapshot = snapshot;
      await openRooms(tester, repo);
      await precargarRecursos(tester);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/indicadores_$name.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Transmisión de un reclamo confirmado', skip: !Platform.isMacOS, (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
    await openRooms(tester, repo);
    await tester.pump(const Duration(seconds: 4));
    final update = scoredSnapshot(sequence: 6);
    (update['match']['claims'] as List).add({
      'zoneId': 'azul_1',
      'memberId': 'otro',
      'place': 1,
      'points': 7,
      'sequence': 6,
    });
    (update['match']['zones'] as List).add({
      'zoneId': 'azul_1',
      'nextPlace': 2,
      'nextPoints': 6,
    });
    repo.publish(update, type: 'ZONE_CLAIMED');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BrilliantGameApp),
      matchesGoldenFile('capturas/indicadores_reclamo.png'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Sin movimientos: únicamente omitir y explicación visible',
    skip: !Platform.isMacOS,
    (tester) async {
      pantallaNivel(tester);
      final definition = CatalogoTableros.predeterminado().obtenerDefinicion(
        'tablero_01',
      );
      final board = definition.crearTablero();
      final prep = PreparacionInicial(board);
      for (final (id, value) in prep.distribucionAleatoria(Random(19))) {
        board.colocarValor(id, value);
      }
      while (destinosConAncla(board, 6, 6).isNotEmpty) {
        final id = destinosConAncla(board, 6, 6).first;
        final value = [
          1,
          2,
          3,
          4,
          5,
          6,
        ].firstWhere((n) => board.puedeColocarValor(id, n));
        board.colocarValor(id, value);
      }
      expect(board.celdas.values.any((c) => !c.estaOcupada), isTrue);
      final snapshot = onlineSnapshot(
        prepared: true,
        playing: true,
        board: {
          for (final c in board.celdas.values)
            if (c.valor != null) c.id: c.valor!,
        },
      );
      snapshot['match']['round']['dice'] = [6, 6];
      await openRooms(tester, FakeRoomsRepository()..snapshot = snapshot);
      await precargarRecursos(tester);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('confirmar_jugada_online')),
        findsNothing,
      );
      expect(find.text('Omitir turno'), findsOneWidget);
      await expectLater(
        find.byType(BrilliantGameApp),
        matchesGoldenFile('capturas/indicadores_omitir_unico.png'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
