import 'dart:async';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/rooms_support.dart';

class HeldActionRepository extends FakeRoomsRepository {
  final response = Completer<void>();
  @override
  Future<Map<String, dynamic>> command(
    String token,
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final accepted = await super.command(token, method, path, body);
    if (path.endsWith('/actions')) await response.future;
    return accepted;
  }
}

void main() {
  testWidgets(
    'Preparación incierta se reintenta con la misma distribución e ID',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()..snapshot = onlineSnapshot();
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      repo.loseNextResponse = true;
      final proposal = onlinePreparation();
      await rooms.confirmPreparation('partida-1', proposal);
      proposal.clear();
      expect(rooms.state.uncertain, isTrue);
      await rooms.retry();
      expect(repo.commands.first, repo.commands.last);
      expect((repo.commands.last['placements'] as Map).length, 6);
      expect(rooms.state.lobby!.match!['ownPreparationConfirmed'], isTrue);
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets(
    'Una ronda nueva nunca recibe automáticamente la propuesta anterior',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()
        ..snapshot = onlineSnapshot(prepared: true, playing: true);
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      repo.publish(
        onlineSnapshot(
          prepared: true,
          playing: true,
          roundNumber: 2,
          sequence: 6,
        ),
        type: 'ROUND_STARTED',
      );
      await tester.pump();
      expect(repo.commands, isEmpty);
      expect(rooms.state.lobby!.match!['round']['id'], 'ronda-2');
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets('Reintentar una acción conserva el ID de la ronda original', (
    tester,
  ) async {
    final auth = AuthCubit(FakeAuthRepository());
    await auth.authenticate('Ana', 'a!2', register: false);
    final repo = FakeRoomsRepository()
      ..snapshot = onlineSnapshot(prepared: true, playing: true);
    final rooms = RoomsCubit(repo, auth);
    await rooms.refresh();
    await tester.pump();
    repo.loseNextResponse = true;
    await rooms.confirmAction('partida-1', 'ronda-1');
    repo.publish(
      onlineSnapshot(
        prepared: true,
        playing: true,
        roundNumber: 2,
        sequence: 7,
      ),
      type: 'ROUND_STARTED',
    );
    await tester.pump();
    await rooms.retry();
    expect(repo.paths, hasLength(2));
    expect(
      repo.paths.every((p) => p.endsWith('/rounds/ronda-1/actions')),
      isTrue,
    );
    expect(repo.commands.first, repo.commands.last);
    expect(rooms.state.lobby!.match!['round']['id'], 'ronda-2');
    await rooms.close();
    await auth.close();
  });
  testWidgets(
    'El plazo usa el reloj del servidor y a cero no envía una confirmación',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()
        ..snapshot = onlineSnapshot(prepared: true, playing: true);
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      expect(rooms.state.secondsRemaining, 60);
      repo.publish({
        ...onlineSnapshot(prepared: true, playing: true, sequence: 6),
        'serverTime': '2026-11-06T00:01:01Z',
      }, type: 'MESSAGE_CREATED');
      await tester.pump();
      expect(rooms.state.secondsRemaining, 0);
      await rooms.confirmAction('partida-1', 'ronda-1');
      expect(repo.commands, isEmpty);
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets(
    'Una respuesta tardía no restaura la partida después de perder pertenencia',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = HeldActionRepository()
        ..snapshot = onlineSnapshot(prepared: true, playing: true);
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      final action = rooms.confirmAction('partida-1', 'ronda-1');
      await tester.pump();
      repo.failure = const AuthFailure('NOT_ROOM_MEMBER', status: 403);
      repo.channels.single.disconnect(4003);
      await tester.pump();
      expect(rooms.state.lobby, isNull);
      expect(rooms.state.busy, isFalse);
      repo.response.complete();
      await action;
      expect(rooms.state.lobby, isNull);
      await rooms.close();
      await auth.close();
    },
  );
}
