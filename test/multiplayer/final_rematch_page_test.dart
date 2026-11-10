import 'package:brilliant_game/presentation/widgets/celebracion_victoria.dart';
import 'package:brilliant_game/presentation/widgets/final_partida_online.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

Map<String, dynamic> losingSnapshot({int sequence = 6}) {
  final snapshot = scoredSnapshot(finished: true, sequence: sequence);
  final result = snapshot['match']['result'] as Map;
  result['winnerMemberId'] = 'otro';
  result['reason'] = 'TARGET';
  final ranking = result['ranking'] as List;
  result['ranking'] = [
    {...ranking[1] as Map, 'position': 1, 'points': 28},
    {...ranking[0] as Map, 'position': 2},
  ];
  return snapshot;
}

Future<void> revealFinal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Solo ganador celebra; omitir y recibir otro evento no repite animación',
    (tester) async {
      pantallaNivel(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
      await openRooms(tester, repo);
      repo.publish(
        scoredSnapshot(finished: true, sequence: 6),
        type: 'MATCH_FINISHED',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CelebracionVictoria), findsOneWidget);
      expect(find.byType(DerrotaOnline), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ver_ranking_online')));
      await tester.pumpAndSettle();
      expect(find.text('Ana ganó'), findsOneWidget);
      repo.publish(
        scoredSnapshot(finished: true, sequence: 7),
        type: 'MEMBER_CONNECTION_CHANGED',
      );
      await tester.pump();
      expect(find.byType(CelebracionVictoria), findsNothing);
      expect(repo.commands, isEmpty);
    },
  );
  testWidgets(
    'Derrota muestra puesto fijo y se puede saltar sin enviar comandos',
    (tester) async {
      pantallaNivel(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
      await openRooms(tester, repo);
      repo.publish(losingSnapshot(), type: 'MATCH_FINISHED');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(DerrotaOnline), findsOneWidget);
      expect(find.byType(CelebracionVictoria), findsNothing);
      expect(find.text('Tu puesto: 2.º'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ver_ranking_online')));
      await tester.pumpAndSettle();
      expect(find.text('Beto ganó'), findsOneWidget);
      expect(find.byKey(const ValueKey('puesto_online')), findsOneWidget);
      expect(repo.commands, isEmpty);
    },
  );
  testWidgets('Movimiento reducido abre ranking sin láser ni celebración', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = losingSnapshot();
    await openRooms(tester, repo);
    expect(find.byType(CelebracionVictoria), findsNothing);
    expect(find.byType(DerrotaOnline), findsNothing);
    expect(find.text('Tu puesto: 2.º'), findsOneWidget);
  });
  testWidgets(
    'Revancha incierta reintenta el mismo comando y limpia tablero al abrir lobby',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()
        ..snapshot = scoredSnapshot(finished: true)
        ..loseNextResponse = true;
      await openRooms(tester, repo);
      final button = find.byKey(const ValueKey('revancha_online'));
      await revealFinal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repo.paths.single, 'POST matches/partida-1/rematch');
      await tester.tap(find.text('Reintentar operación'));
      await tester.pumpAndSettle();
      expect(repo.commands[0], repo.commands[1]);
      expect(find.byKey(const ValueKey('iniciar_sala')), findsOneWidget);
      expect(find.text('Ana ganó'), findsNothing);
      expect(repo.snapshot!['match'], isNull);
      expect(repo.snapshot!['room']['levelId'], isNull);
    },
  );
  testWidgets('Salir al menú confirma salida y vuelve al menú principal', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = scoredSnapshot(finished: true);
    await openRooms(tester, repo);
    final button = find.byKey(const ValueKey('salir_menu_online'));
    await revealFinal(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirmar_salida_sala')));
    await tester.pumpAndSettle();
    expect(repo.paths.single, 'POST rooms/sala-1/leave');
    expect(find.byKey(const ValueKey('multijugador_menu')), findsOneWidget);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Ranking y revancha accesibles a texto 2× en $size', (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: 2);
      final repo = FakeRoomsRepository()..snapshot = losingSnapshot();
      await openRooms(tester, repo);
      await revealFinal(tester, find.byKey(const ValueKey('revancha_online')));
      expect(
        find.byKey(const ValueKey('revancha_online')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('abrir_chat')).hitTestable(),
        findsOneWidget,
      );
    });
  }
}
