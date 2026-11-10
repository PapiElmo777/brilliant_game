import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_repository.dart';
import 'rooms_repository.dart';

class RoomsState {
  final LobbySnapshot? lobby;
  final List<Map<String, dynamic>> rooms;
  final bool loading,
      busy,
      uncertain,
      channelConnected,
      connecting,
      loadingHistory;
  final List<RoomMessage> messages;
  final int unread, chatCooldown;
  final int? secondsRemaining;
  final String chatDraft;
  final bool hasMoreHistory;
  final String? error;
  const RoomsState({
    this.lobby,
    this.rooms = const [],
    this.loading = false,
    this.busy = false,
    this.uncertain = false,
    this.error,
    this.channelConnected = false,
    this.connecting = false,
    this.messages = const [],
    this.unread = 0,
    this.loadingHistory = false,
    this.hasMoreHistory = true,
    this.chatDraft = '',
    this.chatCooldown = 0,
    this.secondsRemaining,
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
  final DateTime Function() now;
  final Random _random = Random.secure();
  Timer? _poll, _heartbeat, _reconnect, _cooldownTimer;
  Timer? _roundTicker;
  final _serverWatch = Stopwatch();
  DateTime? _serverBase;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Map<String, dynamic>>? _frames;
  RoomChannel? _channel;
  Future<void>? _opening;
  String? _channelToken;
  int _generation = 0,
      _socketGeneration = 0,
      _attempt = 0,
      _readSequence = 0,
      _unread = 0,
      _cooldown = 0;
  bool _reading = false,
      _active = true,
      _ready = false,
      _connecting = false,
      _superseded = false,
      _chatOpen = false,
      _loadingHistory = false,
      _hasMore = true;
  DateTime _lastFrame = DateTime.now();
  _Command? _pending;
  String _draft = '';
  final Map<String, RoomMessage> _messages = {};
  final Set<String> _shownResults = {};
  bool resultWasShown(String id) => _shownResults.contains(id);
  void markResultShown(String id) => _shownResults.add(id);
  RoomsCubit(this.repository, this.auth, {DateTime Function()? now})
    : now = now ?? DateTime.now,
      super(const RoomsState()) {
    _authSubscription = auth.stream.listen((s) {
      if (s.session == null) {
        _stopChannel();
        return;
      }
      if (state.lobby != null &&
          _active &&
          s.session!.accessToken != _channelToken) {
        _reconnect?.cancel();
        _stopChannel();
        _openChannel();
      }
    });
  }
  void _publish(RoomsState update) {
    if (isClosed) return;
    final messages = _messages.values.toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    super.emit(
      RoomsState(
        lobby: update.lobby,
        rooms: update.rooms,
        loading: update.loading,
        busy: update.busy,
        uncertain: update.uncertain,
        error: update.error,
        channelConnected: _ready,
        connecting: _connecting,
        messages: List.unmodifiable(messages),
        unread: _unread,
        loadingHistory: _loadingHistory,
        hasMoreHistory: _hasMore,
        chatDraft: _draft,
        chatCooldown: _cooldown,
        secondsRemaining: _remaining(update.lobby),
      ),
    );
  }

  int? _remaining(LobbySnapshot? snapshot) {
    if (snapshot?.match == null) return null;
    final game = OnlineMatch.fromJson(snapshot!.match!);
    final deadline = game.state == 'END_VOTE'
        ? DateTime.parse(game.endVote!['deadline'] as String)
        : game.state == 'ROUND_ACTIVE'
        ? game.round?.deadline
        : null;
    if (deadline == null || _serverBase == null) return null;
    final remaining = deadline.difference(
      _serverBase!.add(_serverWatch.elapsed),
    );
    return ((remaining.inMilliseconds + 999) ~/ 1000).clamp(0, 60);
  }

  void _status({String? error}) => _publish(
    RoomsState(
      lobby: state.lobby,
      rooms: state.rooms,
      busy: state.busy,
      uncertain: state.uncertain,
      error: error ?? state.error,
    ),
  );
  void startPolling() {
    _active = true;
    _roundTicker?.cancel();
    _roundTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.lobby?.match != null) _status();
    });
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (state.lobby == null) {
        refresh();
      } else {
        _ensureChannel();
      }
    });
    _ensureChannel();
  }

  void pausePolling() {
    _active = false;
    _roundTicker?.cancel();
    _poll?.cancel();
    _reconnect?.cancel();
    _stopChannel();
    _status();
  }

  String _id() {
    final bytes = List.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<String> _token() async {
    final s = auth.state.session;
    if (s == null) throw const AuthFailure('SESSION_INVALID', status: 401);
    if (s.expiresAt.difference(DateTime.now()) <= const Duration(seconds: 60)) {
      await auth.renewSession();
    }
    final token = auth.state.session?.accessToken;
    if (token == null) throw const AuthFailure('SESSION_INVALID', status: 401);
    return token;
  }

  void _unauthorized(AuthFailure error, String? token) {
    if (error.connectionFailure && auth.state.session?.accessToken == token) {
      auth.checkSession();
    } else if (error.status == 401 && auth.state.session?.accessToken == token) {
      auth.invalidate();
    }
  }

  void _merge(Iterable<RoomMessage> messages) {
    for (final m in messages) {
      _messages[m.id] = m;
    }
    if (_messages.length > 200) {
      final ordered = _messages.values.toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      for (final m in ordered.take(_messages.length - 200)) {
        _messages.remove(m.id);
      }
      _hasMore = false;
    }
  }

  LobbySnapshot _accept(LobbySnapshot incoming) {
    final old = state.lobby;
    if (old != null &&
        old.id == incoming.id &&
        incoming.sequence < old.sequence) {
      return old;
    }
    final estimated = _serverBase?.add(_serverWatch.elapsed);
    if (estimated == null ||
        incoming.serverTime.isAfter(estimated) ||
        old?.id != incoming.id) {
      _serverBase = incoming.serverTime;
      _serverWatch
        ..reset()
        ..start();
    }
    if (old?.id != incoming.id) {
      _messages.clear();
      _unread = 0;
      _hasMore = true;
      _draft = '';
      _readSequence = incoming.messages.fold(0, (v, m) => max(v, m.sequence));
    }
    _merge(incoming.messages);
    final own = incoming.members
        .where((m) => m.userId == auth.state.session?.user.id)
        .firstOrNull;
    if (_chatOpen) {
      _readSequence = _messages.values.fold(
        _readSequence,
        (v, m) => max(v, m.sequence),
      );
    }
    _unread = _messages.values
        .where((m) => m.sequence > _readSequence && m.authorId != own?.id)
        .length;
    return incoming;
  }

  void _clearLobby() {
    ++_generation;
    _pending = null;
    _stopChannel();
    _reconnect?.cancel();
    _messages.clear();
    _unread = 0;
    _draft = '';
    _readSequence = 0;
    _hasMore = true;
    _superseded = false;
  }

  Future<void> refresh({bool resync = false}) async {
    if (isClosed || _reading || (!resync && (state.busy || _pending != null))) {
      return;
    }
    _reading = true;
    final generation = _generation;
    String? token;
    if (state.lobby == null && state.rooms.isEmpty) {
      _publish(RoomsState(loading: true, error: state.error));
    }
    try {
      token = await _token();
      LobbySnapshot? lobby = state.lobby;
      var rooms = state.rooms;
      if (lobby == null) {
        final result = await repository.list(token);
        rooms = [
          for (final r in result['rooms'] as List)
            Map<String, dynamic>.from(r as Map),
        ];
        if (result['currentRoomId'] case final String id) {
          lobby = LobbySnapshot.fromJson(await repository.get(token, id));
        }
      } else {
        lobby = LobbySnapshot.fromJson(await repository.get(token, lobby.id));
      }
      if (isClosed || generation != _generation) return;
      if (lobby != null) lobby = _accept(lobby);
      _publish(
        RoomsState(
          lobby: lobby,
          rooms: rooms,
          busy: state.busy,
          uncertain: state.uncertain,
        ),
      );
      _superseded = false;
      _ensureChannel();
    } on AuthFailure catch (e) {
      _unauthorized(e, token);
      if (isClosed || generation != _generation) return;
      final gone = e.code == 'NOT_ROOM_MEMBER' || e.code == 'ROOM_NOT_FOUND';
      if (gone) _clearLobby();
      _publish(
        RoomsState(
          lobby: gone ? null : state.lobby,
          rooms: state.rooms,
          busy: !gone && state.busy,
          uncertain: !gone && state.uncertain,
          error: roomsError(e),
        ),
      );
    } on Object catch (_) {
      if (!isClosed && generation == _generation) {
        _status(error: 'Respuesta de sala inválida.');
      }
    } finally {
      _reading = false;
    }
  }

  void _ensureChannel() {
    if (_active &&
        state.lobby != null &&
        !_superseded &&
        _channel == null &&
        !_connecting &&
        !(_reconnect?.isActive ?? false)) {
      _openChannel();
    }
  }

  void _stopChannel() {
    ++_socketGeneration;
    _heartbeat?.cancel();
    _frames?.cancel();
    _frames = null;
    final old = _channel;
    _channel = null;
    _channelToken = null;
    _ready = false;
    _connecting = false;
    old?.close();
  }

  Future<void> _openChannel() async {
    final previous = _opening;
    if (previous != null) {
      await previous;
      _ensureChannel();
      return;
    }
    final operation = _connectAttempt();
    _opening = operation;
    try {
      await operation;
    } finally {
      if (identical(_opening, operation)) _opening = null;
    }
  }

  Future<void> _connectAttempt() async {
    final lobby = state.lobby;
    if (!_active || lobby == null || isClosed || _connecting) return;
    _stopChannel();
    final generation = _socketGeneration;
    _connecting = true;
    _status();
    String? token;
    try {
      token = await _token();
      final channel = await repository.connect(token, lobby.id);
      if (isClosed ||
          generation != _socketGeneration ||
          !_active ||
          state.lobby?.id != lobby.id) {
        await channel.close();
        return;
      }
      _channel = channel;
      _channelToken = token;
      _lastFrame = now();
      _frames = channel.frames.listen(
        (frame) => _frame(frame, generation),
        onError: (Object error) => _lost(generation),
        onDone: () => _lost(generation, code: channel.closeCode),
      );
      _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
        if (now().difference(_lastFrame) > const Duration(seconds: 25)) {
          _lost(generation);
          return;
        }
        try {
          channel.ping();
        } on Object {
          _lost(generation);
        }
      });
    } on AuthFailure catch (e) {
      _unauthorized(e, token);
      _lost(generation, code: e.status == 403 ? 4003 : null);
    } on Object {
      _lost(generation);
    }
  }

  void _frame(Map<String, dynamic> frame, int generation) {
    if (isClosed || generation != _socketGeneration) return;
    _lastFrame = now();
    if (frame['type'] == 'PONG') return;
    try {
      if (frame['protocolVersion'] != 1 ||
          frame['roomId'] != state.lobby?.id ||
          frame['sequence'] is! int) {
        throw const FormatException();
      }
      final sequence = frame['sequence'] as int;
      final snapshot = frame['type'] == 'SNAPSHOT';
      if (!snapshot && !_ready) return;
      if (!snapshot && sequence <= state.lobby!.sequence) return;
      if (!snapshot && sequence != state.lobby!.sequence + 1) {
        _stopChannel();
        _status();
        refresh(resync: true).whenComplete(_ensureChannel);
        return;
      }
      final lobby = LobbySnapshot.fromJson(
        frame['data'] as Map<String, dynamic>,
      );
      if (lobby.id != frame['roomId'] || lobby.sequence != sequence) {
        throw const FormatException();
      }
      _ready = true;
      _connecting = false;
      _attempt = 0;
      _publish(
        RoomsState(
          lobby: _accept(lobby),
          rooms: state.rooms,
          busy: state.busy,
          uncertain: state.uncertain,
          error: state.uncertain ? state.error : null,
        ),
      );
    } on Object {
      _lost(generation);
    }
  }

  void _lost(int generation, {int? code}) {
    if (isClosed || generation != _socketGeneration) return;
    _stopChannel();
    if (code == 4009) {
      _superseded = true;
      _status(
        error:
            'La sala se abrió en otra conexión. Pulsa Actualizar para retomarla.',
      );
      return;
    }
    if (code == 4003) {
      refresh(resync: true);
    }
    // Un canal caído también verifica HTTP: si el servidor no responde,
    // AuthCubit cierra la sesión y muestra el aviso en login.
    if (_active) auth.checkSession();
    if (!_active || state.lobby == null) return;
    _status(error: 'Reconectando con la sala…');
    final delay = 1 << min(_attempt++, 3);
    _reconnect?.cancel();
    _reconnect = Timer(Duration(seconds: delay), _ensureChannel);
  }

  Future<void> _send(
    String method,
    String path,
    Map<String, Object?> fields, {
    bool leave = false,
  }) async {
    if (state.busy || _pending != null || isClosed) return;
    if (state.lobby != null && !leave && !_ready) return;
    _pending = _Command(method, path, {'commandId': _id(), ...fields}, leave);
    await retry();
  }

  Future<void> retry() async {
    final command = _pending;
    if (command == null || state.busy || isClosed) return;
    if (state.lobby != null && !command.leave && !_ready) return;
    final generation = ++_generation;
    _publish(RoomsState(lobby: state.lobby, rooms: state.rooms, busy: true));
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
      if (command.leave) {
        _clearLobby();
      }
      if (command.path.endsWith('/messages') &&
          _draft.trim() == command.body['text']) {
        _draft = '';
      }
      _publish(RoomsState(lobby: command.leave ? null : _accept(snapshot)));
      if (command.leave) {
        await refresh();
      } else {
        _ensureChannel();
      }
    } on AuthFailure catch (e) {
      _unauthorized(e, token);
      if (isClosed || generation != _generation) return;
      final uncertain = e.status == null || (e.status ?? 0) >= 500;
      if (!uncertain) _pending = null;
      if (e.status == 429 && command.path.endsWith('/messages')) {
        _cooldown = e.retryAfter > 0 ? e.retryAfter : 10;
        _cooldownTimer?.cancel();
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (isClosed) {
            timer.cancel();
            return;
          }
          _cooldown--;
          _status();
          if (_cooldown <= 0) timer.cancel();
        });
      }
      _publish(
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
        _clearLobby();
        _publish(RoomsState(error: roomsError(e)));
      }
    } on Object catch (_) {
      if (!isClosed && generation == _generation) {
        _publish(
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

  void setDraft(String value) {
    _draft = value;
  }

  void setChatOpen(bool value) {
    _chatOpen = value;
    if (value) {
      _readSequence = _messages.values.fold(
        _readSequence,
        (v, m) => max(v, m.sequence),
      );
      _unread = 0;
    }
    _status();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || text.runes.length > 300 || _cooldown > 0) return;
    final l = state.lobby;
    if (l != null) {
      await _send('POST', 'rooms/${l.id}/messages', {'text': text.trim()});
    }
  }

  Future<void> loadHistory() async {
    final lobby = state.lobby;
    if (lobby == null || _loadingHistory || !_hasMore) return;
    _loadingHistory = true;
    _status();
    final generation = _generation;
    String? token;
    try {
      token = await _token();
      final before = _messages.isEmpty
          ? null
          : _messages.values.map((m) => m.sequence).reduce(min);
      final result = await repository.history(token, lobby.id, before);
      if (isClosed ||
          generation != _generation ||
          state.lobby?.id != lobby.id) {
        return;
      }
      final messages = [
        for (final m in result['messages'] as List)
          RoomMessage.fromJson(Map<String, dynamic>.from(m as Map)),
      ];
      if (messages.length < 20) _hasMore = false;
      _merge(messages);
    } on AuthFailure catch (e) {
      _unauthorized(e, token);
      if (!isClosed) _status(error: roomsError(e));
    } on Object {
      if (!isClosed) _status(error: 'No se pudo cargar el historial.');
    } finally {
      _loadingHistory = false;
      if (!isClosed) _status();
    }
  }

  Future<void> confirmPreparation(
    String matchId,
    Map<String, int> placements,
  ) => _send('PUT', 'matches/$matchId/preparation', {
    'placements': Map<String, int>.unmodifiable(placements),
  });
  Future<void> confirmAction(
    String matchId,
    String roundId, {
    int? dieIndex,
    String? cellId,
  }) {
    if (state.secondsRemaining == 0) return Future.value();
    return _send('POST', 'matches/$matchId/rounds/$roundId/actions', {
      'kind': dieIndex == null ? 'SKIP' : 'PLACE',
      'dieIndex': ?dieIndex,
      if (dieIndex != null) 'cellId': cellId,
    });
  }

  Future<void> acceptRematch(String matchId) =>
      _send('POST', 'matches/$matchId/rematch', {});

  Future<void> castBallot(String matchId, String voteId, bool approve) {
    if (state.secondsRemaining == 0) return Future.value();
    return _send('PUT', 'matches/$matchId/end-vote/ballot', {
      'voteId': voteId,
      'approve': approve,
    });
  }

  Future<void> create(String name, int capacity) =>
      _send('POST', 'rooms', {'name': name, 'capacity': capacity});
  Future<void> join(String id) =>
      _send('POST', 'rooms/${Uri.encodeComponent(id)}/join', {});
  Future<void> leave() async {
    final l = state.lobby;
    if (l != null) await _send('POST', 'rooms/${l.id}/leave', {}, leave: true);
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
    _active = false;
    _roundTicker?.cancel();
    _poll?.cancel();
    _reconnect?.cancel();
    _cooldownTimer?.cancel();
    _authSubscription?.cancel();
    _stopChannel();
    return super.close();
  }
}
