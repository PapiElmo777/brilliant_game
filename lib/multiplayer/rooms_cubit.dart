import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_repository.dart';
import 'rooms_repository.dart';

class RoomsState {
  final LobbySnapshot? lobby;
  final List<Map<String, dynamic>> rooms;
  final bool loading, busy, uncertain;
  final String? error;
  const RoomsState({
    this.lobby,
    this.rooms = const [],
    this.loading = false,
    this.busy = false,
    this.uncertain = false,
    this.error,
  });
}

class _Command {
  final String method, path;
  final Map<String, Object?> body;
  final bool leave;
  _Command(this.method, this.path, this.body, this.leave);
}

class RoomsCubit extends Cubit<RoomsState> {
  final RoomsRepository repository;
  final AuthCubit auth;
  Timer? _poll;
  bool _reading = false;
  int _generation = 0;
  _Command? _pending;
  final Random _random = Random.secure();
  RoomsCubit(this.repository, this.auth) : super(const RoomsState());

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  void pausePolling() {
    _poll?.cancel();
  }

  String _id() {
    final bytes = List.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<String> _token() async {
    final session = auth.state.session;
    if (session == null) {
      throw const AuthFailure('SESSION_INVALID', status: 401);
    }
    if (session.expiresAt.difference(DateTime.now()) <=
        const Duration(seconds: 60)) {
      await auth.renewSession();
    }
    final token = auth.state.session?.accessToken;
    if (token == null) throw const AuthFailure('SESSION_INVALID', status: 401);
    return token;
  }

  void _unauthorized(AuthFailure error, String? token) {
    if (error.status == 401 && auth.state.session?.accessToken == token) {
      auth.invalidate();
    }
  }

  Future<void> refresh() async {
    if (isClosed || state.busy || _reading || _pending != null) return;
    _reading = true;
    final generation = _generation;
    String? token;
    if (state.lobby == null && state.rooms.isEmpty) {
      emit(RoomsState(loading: true, error: state.error));
    }
    try {
      token = await _token();
      LobbySnapshot? lobby = state.lobby;
      List<Map<String, dynamic>> rooms = state.rooms;
      if (lobby == null) {
        final result = await repository.list(token);
        rooms = [
          for (final room in result['rooms'] as List)
            Map<String, dynamic>.from(room as Map),
        ];
        if (result['currentRoomId'] case final String id) {
          lobby = LobbySnapshot.fromJson(await repository.get(token, id));
        }
      } else {
        lobby = LobbySnapshot.fromJson(await repository.get(token, lobby.id));
      }
      if (isClosed || generation != _generation) return;
      emit(RoomsState(lobby: lobby, rooms: rooms));
    } on AuthFailure catch (e) {
      _unauthorized(e, token);
      if (isClosed || generation != _generation) return;
      final gone = e.code == 'ROOM_NOT_FOUND' || e.code == 'NOT_ROOM_MEMBER';
      emit(
        RoomsState(
          lobby: gone ? null : state.lobby,
          rooms: state.rooms,
          error: roomsError(e),
        ),
      );
    } on FormatException catch (_) {
      if (!isClosed && generation == _generation) {
        emit(
          RoomsState(
            lobby: state.lobby,
            rooms: state.rooms,
            error: 'Respuesta de sala inválida.',
          ),
        );
      }
    } on TypeError catch (_) {
      if (!isClosed && generation == _generation) {
        emit(
          RoomsState(
            lobby: state.lobby,
            rooms: state.rooms,
            error: 'Respuesta de sala inválida.',
          ),
        );
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _send(
    String method,
    String path,
    Map<String, Object?> fields, {
    bool leave = false,
  }) async {
    if (state.busy || _pending != null || isClosed) return;
    _pending = _Command(method, path, {'commandId': _id(), ...fields}, leave);
    await retry();
  }

  Future<void> retry() async {
    final command = _pending;
    if (command == null || state.busy || isClosed) return;
    final generation = ++_generation;
    emit(RoomsState(lobby: state.lobby, rooms: state.rooms, busy: true));
    String? token;
    try {
      token = await _token();
      final result = await repository.command(
        token,
        command.method,
        command.path,
        command.body,
      );
      final snapshot = LobbySnapshot.fromJson(
        result['data'] as Map<String, dynamic>,
      );
      if (isClosed || generation != _generation) return;
      _pending = null;
      emit(RoomsState(lobby: command.leave ? null : snapshot));
      if (command.leave) await refresh();
    } on AuthFailure catch (e) {
      _unauthorized(e, token);
      if (isClosed || generation != _generation) return;
      final uncertain = e.status == null || (e.status ?? 0) >= 500;
      if (!uncertain) _pending = null;
      emit(
        RoomsState(
          lobby: state.lobby,
          rooms: state.rooms,
          uncertain: uncertain,
          error: uncertain
              ? 'No se pudo confirmar la operación. Reintenta para recuperar el mismo resultado.'
              : roomsError(e),
        ),
      );
      if (!uncertain &&
          (e.code == 'STALE_SETTINGS' || e.code == 'ALREADY_IN_ROOM')) {
        await refresh();
      }
      if (!uncertain &&
          (e.code == 'NOT_ROOM_MEMBER' || e.code == 'ROOM_NOT_FOUND')) {
        emit(RoomsState(error: roomsError(e)));
      }
    } on Object catch (_) {
      if (!isClosed && generation == _generation) {
        emit(
          RoomsState(
            lobby: state.lobby,
            rooms: state.rooms,
            uncertain: true,
            error:
                'No se pudo confirmar la operación. Reintenta para recuperar el mismo resultado.',
          ),
        );
      }
    }
  }

  Future<void> create(String name, int capacity) =>
      _send('POST', 'rooms', {'name': name, 'capacity': capacity});
  Future<void> join(String id) =>
      _send('POST', 'rooms/${Uri.encodeComponent(id)}/join', {});
  Future<void> leave() async {
    final lobby = state.lobby;
    if (lobby != null) {
      await _send('POST', 'rooms/${lobby.id}/leave', {}, leave: true);
    }
  }

  Future<void> settings(int capacity, String? levelId) async {
    final l = state.lobby;
    if (l != null) {
      await _send('PATCH', 'rooms/${l.id}/settings', {
        'expectedRevision': l.revision,
        'capacity': capacity,
        'levelId': levelId,
      });
    }
  }

  Future<void> capacity(int value) async {
    final l = state.lobby;
    if (l != null) await settings(value, l.levelId);
  }

  Future<void> randomLevel() async {
    final l = state.lobby;
    if (l != null) {
      await _send('POST', 'rooms/${l.id}/random-level', {
        'expectedRevision': l.revision,
      });
    }
  }

  Future<void> ready(bool value) async {
    final l = state.lobby;
    if (l != null) {
      await _send('PUT', 'rooms/${l.id}/ready', {
        'expectedRevision': l.revision,
        'ready': value,
      });
    }
  }

  Future<void> startMatch() async {
    final l = state.lobby;
    if (l != null) {
      await _send('POST', 'rooms/${l.id}/start', {
        'expectedRevision': l.revision,
      });
    }
  }

  @override
  Future<void> close() {
    ++_generation;
    _poll?.cancel();
    return super.close();
  }
}
