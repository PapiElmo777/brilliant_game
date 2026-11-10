import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

void main() {
  testWidgets(
    'Historial restaurado muestra los dados y la decisión de rondas anteriores',
    (tester) async {
      pantallaNivel(tester);
      final snapshot = onlineSnapshot(
        prepared: true,
        playing: true,
        roundNumber: 3,
      );
      snapshot['match']['ownHistory'] = [
        {
          'number': 1,
          'dice': [5, 2],
          'kind': 'SKIP',
          'dieIndex': null,
          'cellId': null,
        },
        {
          'number': 2,
          'dice': [3, 6],
          'kind': 'PLACE',
          'dieIndex': 0,
          'cellId': 'f1_c6',
        },
      ];
      final repo = FakeRoomsRepository()..snapshot = snapshot;
      await openRooms(tester, repo);
      await tester.tap(find.textContaining('Tiradas · 2'));
      await tester.pumpAndSettle();
      expect(find.text('1:'), findsOneWidget);
      expect(find.text('2:'), findsOneWidget);
      expect(find.text('Omitida'), findsOneWidget);
      expect(repo.commands, isEmpty);
    },
  );
}
