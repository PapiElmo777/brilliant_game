import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/rooms_support.dart';

Map<String, dynamic> message(int n, {String author = 'otro'}) => {
  'id': 'mensaje-$n',
  'sequence': n,
  'kind': 'PLAYER',
  'authorMemberId': author,
  'authorName': 'Beto',
  'text': 'Mensaje $n',
  'serverTime': '2026-11-06T00:00:00Z',
};

class RotatingAuth extends FakeAuthRepository {
  AuthSession make(String token) => AuthSession(
    user: const Account(id: 'uuid-de-prueba', username: 'Ana'),
    accessToken: token,
    refreshToken: 'refresh-$token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  @override
  Future<AuthSession> login(String username, String password) async =>
      make('initial');
  @override
  Future<AuthSession> refresh(String token) async => make('renewed');
}

void main() {
  testWidgets(
    'El lobby deja de consultar GET periódicamente y procesa eventos sin duplicar',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()..snapshot = lobbyJson(sequence: 1);
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      rooms.startPolling();
      await tester.pump();
      expect(rooms.state.channelConnected, isTrue);
      final reads = repo.reads;
      await tester.pump(const Duration(seconds: 12));
      expect(repo.reads, reads);
      final next = {
        ...lobbyJson(sequence: 2),
        'messages': [message(2)],
      };
      repo.publish(next, type: 'MESSAGE_CREATED');
      await tester.pump();
      expect(rooms.state.messages, hasLength(1));
      expect(rooms.state.unread, 1);
      repo.publish(next, type: 'MESSAGE_CREATED');
      await tester.pump();
      expect(rooms.state.messages, hasLength(1));
      expect(rooms.state.unread, 1);
      rooms.setChatOpen(true);
      expect(rooms.state.unread, 0);
      repo.publish({
        ...lobbyJson(sequence: 3),
        'messages': [message(2), message(3)],
      }, type: 'MESSAGE_CREATED');
      await tester.pump();
      expect(rooms.state.unread, 0);
      expect(rooms.state.messages, hasLength(2));
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets(
    'Un salto de secuencia obtiene instantánea y restablece el canal',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()..snapshot = lobbyJson(sequence: 1);
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      final reads = repo.reads;
      repo.publish(
        lobbyJson(sequence: 4, levelId: 'tablero_04', guestReady: true),
      );
      await tester.pump();
      await tester.pump();
      expect(repo.reads, greaterThan(reads));
      expect(repo.channels, hasLength(2));
      expect(rooms.state.lobby!.levelId, 'tablero_04');
      expect(rooms.state.lobby!.members.last.ready, isTrue);
      expect(rooms.state.channelConnected, isTrue);
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets('Reconectar conserva participante, selección, Listo y mensajes', (
    tester,
  ) async {
    final auth = AuthCubit(FakeAuthRepository());
    await auth.authenticate('Ana', 'a!2', register: false);
    final repo = FakeRoomsRepository()
      ..snapshot = {
        ...lobbyJson(sequence: 2, levelId: 'tablero_02', guestReady: true),
        'messages': [message(2)],
      };
    final rooms = RoomsCubit(repo, auth);
    await rooms.refresh();
    await tester.pump();
    repo.channels.single.disconnect();
    await tester.pump();
    expect(rooms.state.channelConnected, isFalse);
    await rooms.ready(false);
    expect(repo.commands, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(repo.channels, hasLength(2));
    expect(rooms.state.channelConnected, isTrue);
    expect(rooms.state.lobby!.members.first.id, 'propio');
    expect(rooms.state.lobby!.members.last.ready, isTrue);
    expect(rooms.state.messages, hasLength(1));
    expect(repo.commands, isEmpty);
    await rooms.close();
    await auth.close();
  });
  testWidgets('Renovar token sustituye el canal sin duplicar la identidad', (
    tester,
  ) async {
    final auth = AuthCubit(RotatingAuth());
    await auth.authenticate('Ana', 'a!2', register: false);
    final repo = FakeRoomsRepository()
      ..snapshot = lobbyJson(levelId: 'tablero_03');
    final rooms = RoomsCubit(repo, auth);
    await rooms.refresh();
    await tester.pump();
    await auth.renewSession();
    await tester.pump();
    expect(repo.channelTokens, ['initial', 'renewed']);
    expect(repo.channels.first.closed, isTrue);
    expect(rooms.state.channelConnected, isTrue);
    expect(rooms.state.lobby!.members.first.userId, 'uuid-de-prueba');
    await rooms.close();
    await auth.close();
  });
  testWidgets('Un canal sustituido no entra en un ciclo de reconexiones', (
    tester,
  ) async {
    final auth = AuthCubit(FakeAuthRepository());
    await auth.authenticate('Ana', 'a!2', register: false);
    final repo = FakeRoomsRepository()..snapshot = lobbyJson();
    final rooms = RoomsCubit(repo, auth);
    await rooms.refresh();
    rooms.startPolling();
    await tester.pump();
    repo.channels.single.disconnect(4009);
    await tester.pump();
    await tester.pump(const Duration(seconds: 15));
    expect(repo.channels, hasLength(1));
    expect(rooms.state.channelConnected, isFalse);
    await rooms.refresh();
    await tester.pump();
    expect(repo.channels, hasLength(2));
    await rooms.close();
    await auth.close();
  });
  testWidgets(
    'El chat reintenta el mismo comando y limpia el borrador solo al confirmar',
    (tester) async {
      final auth = AuthCubit(FakeAuthRepository());
      await auth.authenticate('Ana', 'a!2', register: false);
      final repo = FakeRoomsRepository()..snapshot = lobbyJson();
      final rooms = RoomsCubit(repo, auth);
      await rooms.refresh();
      await tester.pump();
      rooms.setDraft('Hola');
      repo.loseNextResponse = true;
      await rooms.sendMessage('Hola');
      expect(rooms.state.chatDraft, 'Hola');
      expect(rooms.state.uncertain, isTrue);
      await rooms.retry();
      expect(repo.commands.first, repo.commands.last);
      expect(rooms.state.chatDraft, '');
      expect(rooms.state.messages.where((m) => m.text == 'Hola'), hasLength(1));
      await rooms.close();
      await auth.close();
    },
  );
  testWidgets('La falta de respuesta al latido inicia reconexión', (
    tester,
  ) async {
    final auth = AuthCubit(FakeAuthRepository());
    await auth.authenticate('Ana', 'a!2', register: false);
    var now = DateTime.now();
    final repo = FakeRoomsRepository()..snapshot = lobbyJson();
    final rooms = RoomsCubit(repo, auth, now: () => now);
    await rooms.refresh();
    await tester.pump();
    repo.channels.single.respondToPings = false;
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 10));
    expect(repo.channels.first.closed, isTrue);
    expect(rooms.state.channelConnected, isFalse);
    await rooms.close();
    await auth.close();
  });
}
