import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

void main() {
  testWidgets(
    'Anuncia ronda y plazo, y un reclamo nuevo sin repetirlo al actualizar',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()..snapshot = scoredSnapshot();
      await openRooms(tester, repo);
      expect(find.textContaining('¡Ronda 1! Tienes'), findsOneWidget);
      final update = scoredSnapshot(sequence: 6);
      (update['match']['claims'] as List).add({
        'zoneId': 'azul_1',
        'memberId': 'otro',
        'place': 1,
        'points': 7,
        'sequence': 6,
      });
      repo.publish(update, type: 'ZONE_CLAIMED');
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Beto reclamó Zona Azul 1: 1.º lugar, +7 puntos'),
        findsOneWidget,
      );
      final duplicate = {...update, 'sequence': 7};
      repo.publish(duplicate);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.textContaining('Beto reclamó'), findsNothing);
    },
  );
  testWidgets('La ronda nueva sustituye un aviso de ronda viejo', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = onlineSnapshot(prepared: true, playing: true);
    await openRooms(tester, repo);
    repo.publish(
      onlineSnapshot(
        prepared: true,
        playing: true,
        roundNumber: 2,
        sequence: 6,
      ),
      type: 'ROUND_STARTED',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('¡Ronda 2! Tienes'), findsOneWidget);
    expect(find.textContaining('¡Ronda 1!'), findsNothing);
  });
}
