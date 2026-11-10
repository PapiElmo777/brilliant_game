import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:brilliant_game/presentation/widgets/ranking_online.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;
import 'final_rematch_page_test.dart' show losingSnapshot;

void main() {
  test('Top respeta puntos, zonas, secuencia, ingreso y abandonos', () {
    final json = scoredSnapshot()['match'] as Map<String, dynamic>;
    final rows = json['scores'] as List;
    List<String> order() => rankingDePartida(
      OnlineMatch.fromJson(json),
    ).map((r) => r['memberId'] as String).toList();
    expect(order(), ['propio', 'otro']);
    rows[1]['points'] = 13;
    expect(order(), ['otro', 'propio']);
    rows[1]['points'] = 11;
    rows[1]['completedZones'] = 2;
    rows[1]['scoreSequence'] = 2;
    expect(order(), ['otro', 'propio']);
    rows[1]['scoreSequence'] = 3;
    expect(order(), ['propio', 'otro']);
    rows[0]['abandoned'] = 1;
    rows[0]['points'] = 100;
    expect(order(), ['otro', 'propio']);
  });
  test(
    'El final conserva los puestos confirmados aunque cambie el marcador',
    () {
      final json = losingSnapshot()['match'] as Map<String, dynamic>;
      (json['scores'] as List)[0]['points'] = 100;
      expect(
        rankingDePartida(OnlineMatch.fromJson(json)).first['memberId'],
        'otro',
      );
    },
  );
  testWidgets(
    'Ranking abierto actualiza el top y muestra zona, puesto y premio',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
      await openRooms(tester, repo);
      await tester.tap(find.byKey(const ValueKey('ranking_online')));
      await tester.pumpAndSettle();
      expect(find.text('Verde 1 · 1.º · +4'), findsOneWidget);
      expect(
        tester
            .widgetList<TarjetaRanking>(find.byType(TarjetaRanking))
            .first
            .row['memberId'],
        'propio',
      );
      repo.publish(
        scoredSnapshot(sequence: 6)..['match']['scores'][1]['points'] = 13,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<TarjetaRanking>(find.byType(TarjetaRanking))
            .first
            .row['memberId'],
        'otro',
      );
      expect(find.text('13 pts'), findsOneWidget);
      expect(repo.commands, isEmpty);
    },
  );
}
