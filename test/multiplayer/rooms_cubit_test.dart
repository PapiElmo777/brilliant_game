import 'dart:async';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/rooms_support.dart';

void main() {
  late AuthCubit auth;
  late FakeRoomsRepository repository;
  late RoomsCubit rooms;
  setUp(() async {
    auth = AuthCubit(FakeAuthRepository());
    await auth.authenticate('Ana', 'a!2', register: false);
    repository = FakeRoomsRepository();
    rooms = RoomsCubit(repository, auth);
  });
  tearDown(() async {
    await rooms.close();
    await auth.close();
  });
  test('Recupera la pertenencia existente al entrar al multijugador', () async {
    repository.snapshot = lobbyJson(levelId: 'tablero_02');
    await rooms.refresh();
    expect(rooms.state.lobby!.levelId, 'tablero_02');
    expect(rooms.state.lobby!.members.length, 2);
    expect(repository.commands, isEmpty);
  });
  test(
    'Respuesta perdida mantiene ID y contenido; bloquea otras mutaciones',
    () async {
      repository.loseNextResponse = true;
      await rooms.create('Escuadrón', 6);
      expect(rooms.state.uncertain, isTrue);
      await rooms.create('Otra', 2);
      await rooms.refresh();
      expect(repository.commands.length, 1);
      await rooms.retry();
      expect(repository.commands[0], repository.commands[1]);
      expect(
        repository.commands[0]['commandId'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(rooms.state.lobby!.id, 'sala-1');
      expect(rooms.state.uncertain, isFalse);
    },
  );
  test(
    'Una lectura anterior a crear no reemplaza el lobby confirmado',
    () async {
      repository.pendingList = Completer<Map<String, dynamic>>();
      final reading = rooms.refresh();
      await Future<void>.delayed(Duration.zero);
      await rooms.create('Escuadrón', 6);
      repository.pendingList!.complete({'rooms': [], 'currentRoomId': null});
      await reading;
      expect(rooms.state.lobby, isNotNull);
    },
  );
  test('Salir se confirma antes de abandonar el lobby local', () async {
    await rooms.create('Escuadrón', 6);
    repository.loseNextResponse = true;
    await rooms.leave();
    expect(rooms.state.lobby, isNotNull);
    expect(rooms.state.uncertain, isTrue);
    await rooms.retry();
    expect(rooms.state.lobby, isNull);
    expect(repository.snapshot, isNull);
  });
  test('401 elimina la identidad y 403 de sala conserva la cuenta', () async {
    repository.failure = const AuthFailure('NOT_ROOM_MEMBER', status: 403);
    await rooms.refresh();
    expect(auth.state.session, isNotNull);
    repository.failure = const AuthFailure('SESSION_INVALID', status: 401);
    await rooms.refresh();
    expect(auth.state.session, isNull);
  });
}
