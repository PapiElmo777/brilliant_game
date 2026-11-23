import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/multiplayer/rooms_cubit.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

Map<String, dynamic> untimedSnapshot() {
  final snapshot = onlineSnapshot(prepared: true, playing: true);
  snapshot['room']['roundTimerEnabled'] = false;
  snapshot['match']['roundTimerEnabled'] = false;
  snapshot['match']['round']['deadline'] = null;
  return snapshot;
}

void main() {
  test('Old snapshots default to enabled; untimed rounds have no deadline', () {
    expect(LobbySnapshot.fromJson(lobbyJson()).roundTimerEnabled, isTrue);
    expect(
      OnlineMatch.fromJson(onlineSnapshot()['match']).roundTimerEnabled,
      isTrue,
    );
    final match = OnlineMatch.fromJson(untimedSnapshot()['match']);
    expect(match.roundTimerEnabled, isFalse);
    expect(match.round!.deadline, isNull);
  });
  testWidgets('Host disables timer and map changes preserve the choice', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = lobbyJson(levelId: 'tablero_01');
    await openRooms(tester, repo);
    final toggle = find.byKey(const ValueKey('timer_ronda_sala'));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(repo.commands.last['roundTimerEnabled'], isFalse);
    final map = find.byKey(const ValueKey('sala_tablero_02'));
    await tester.ensureVisible(map);
    await tester.tap(map);
    await tester.pumpAndSettle();
    expect(repo.commands.last['levelId'], 'tablero_02');
    expect(repo.commands.last['roundTimerEnabled'], isFalse);
  });
  testWidgets('Guest sees the timer setting but cannot change it', (
    tester,
  ) async {
    pantallaNivel(tester);
    final snapshot = lobbyJson(guest: true, levelId: 'tablero_01');
    snapshot['room']['roundTimerEnabled'] = false;
    await openRooms(
      tester,
      FakeRoomsRepository(guest: true)..snapshot = snapshot,
    );
    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('timer_ronda_sala')),
    );
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNull);
  });
  testWidgets(
    'Untimed rounds stay playable without countdown after three minutes',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()..snapshot = untimedSnapshot();
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      expect(rooms.state.secondsRemaining, isNull);
      final late = untimedSnapshot();
      late['serverTime'] = '2026-11-06T00:03:00Z';
      repo.publish(late, type: 'MESSAGE_CREATED');
      await tester.pump();
      expect(rooms.state.secondsRemaining, isNull);
      await rooms.confirmAction('partida-1', 'ronda-1');
      expect(repo.commands.last['kind'], 'SKIP');
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets('Untimed mission hides alerts and keeps skip enabled', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = untimedSnapshot();
    await openRooms(tester, repo);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin límite'), findsWidgets);
    expect(find.byKey(const ValueKey('contador_urgente')), findsNothing);
    expect(find.byKey(const ValueKey('aviso_30_segundos')), findsNothing);
    final skip = find.byKey(const ValueKey('omitir_ronda_online'));
    final button = tester.widget<IconButton>(skip);
    expect(button.onPressed, isNotNull);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(repo.commands.last['kind'], 'SKIP');
    expect(tester.takeException(), isNull);
  });
}
