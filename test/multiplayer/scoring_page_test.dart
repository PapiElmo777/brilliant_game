import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

void main() {
  testWidgets('Marcador y puestos de zona vienen del servidor', (tester) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
    await openRooms(tester, repo);
    await tester.tap(find.byKey(const ValueKey('ranking_online')));
    await tester.pumpAndSettle();
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('7 pts'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cerrar_ranking')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TableroView>(find.byType(TableroView))
          .puestosReclamados['verde_1'],
      2,
    );
    repo.publish(
      scoredSnapshot(sequence: 6)..['match']['scores'][1]['points'] = 13,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ranking_online')));
    await tester.pumpAndSettle();
    expect(find.text('13 pts'), findsOneWidget);
    expect(repo.commands, isEmpty);
  });
  testWidgets(
    'Votar es definitivo y conserva comando al reintentar una respuesta incierta',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()
        ..snapshot = scoredSnapshot(vote: true)
        ..loseNextResponse = true;
      await openRooms(tester, repo);
      expect(find.text('Votación · 60 s'), findsOneWidget);
      expect(find.byKey(const ValueKey('omitir_ronda_online')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('votar_finalizar_online')));
      await tester.pumpAndSettle();
      expect(repo.paths.single, 'PUT matches/partida-1/end-vote/ballot');
      expect(repo.commands.single['voteId'], 'votacion-1');
      await tester.tap(find.text('Reintentar operación'));
      await tester.pumpAndSettle();
      expect(repo.commands[0], repo.commands[1]);
      expect(find.text('Tu voto: finalizar'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('votar_finalizar_online')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'Final de partida retira dados y acciones y muestra resultado fijo',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
      await openRooms(tester, repo);
      repo.publish(
        scoredSnapshot(finished: true, sequence: 6),
        type: 'MATCH_FINISHED',
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana ganó'), findsOneWidget);
      expect(find.text('Finalizada por votación'), findsOneWidget);
      expect(find.byKey(const ValueKey('reloj_online')), findsNothing);
      expect(
        find.byKey(const ValueKey('confirmar_jugada_online')),
        findsNothing,
      );
      expect(find.text('11 pts'), findsOneWidget);
      expect(repo.commands, isEmpty);
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final vote in [false, true]) {
      testWidgets('Marcador/votación $vote accesibles con texto 2× en $size', (
        tester,
      ) async {
        pantallaNivel(tester, size: size, escala: 2);
        final repo = FakeRoomsRepository()
          ..snapshot = scoredSnapshot(vote: vote);
        await openRooms(tester, repo);
        expect(tester.takeException(), isNull);
        final target = find.byKey(
          ValueKey(vote ? 'votar_continuar_online' : 'omitir_ronda_online'),
        );
        if (vote) {
          await tester.scrollUntilVisible(
            target,
            150,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        expect(
          find.byKey(const ValueKey('abrir_chat')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
