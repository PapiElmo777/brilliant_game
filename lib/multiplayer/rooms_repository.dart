import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../auth/auth_repository.dart';

abstract interface class RoomsRepository {
  Future<Map<String, dynamic>> list(String token);
  Future<Map<String, dynamic>> get(String token, String roomId);
  Future<Map<String, dynamic>> command(
    String token,
    String method,
    String path,
    Map<String, Object?> body,
  );
  Future<RoomChannel> connect(String token, String roomId);
  Future<Map<String, dynamic>> history(
    String token,
    String roomId,
    int? before,
  );
  void close();
}

/// Reutiliza las restricciones de origen, TLS, tamaño, timeout y redirecciones.
class HttpRoomsRepository implements RoomsRepository {
  final HttpAuthRepository _http;
  final Uri baseUrl;
  HttpRoomsRepository({required this.baseUrl})
    : _http = HttpAuthRepository(baseUrl: baseUrl);
  @override
  Future<Map<String, dynamic>> list(String token) async =>
      (await _http.sendJson('GET', 'rooms', 200, token: token))!;
  @override
  Future<Map<String, dynamic>> get(String token, String roomId) async =>
      (await _http.sendJson(
        'GET',
        'rooms/${Uri.encodeComponent(roomId)}',
        200,
        token: token,
      ))!;
  @override
  Future<Map<String, dynamic>> command(
    String token,
    String method,
    String path,
    Map<String, Object?> body,
  ) async =>
      (await _http.sendJson(method, path, 200, token: token, body: body))!;
  @override
  Future<Map<String, dynamic>> history(
    String token,
    String roomId,
    int? before,
  ) async => (await _http.sendJson(
    'GET',
    'rooms/${Uri.encodeComponent(roomId)}/messages',
    200,
    token: token,
    query: {if (before != null) 'before': '$before'},
  ))!;

  @override
  Future<RoomChannel> connect(String token, String roomId) async {
    if (!baseUrl.hasAuthority ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        !baseUrl.path.replaceFirst(RegExp(r'/+$'), '').endsWith('/api/v1') ||
        !(baseUrl.scheme == 'https' ||
            (kDebugMode && baseUrl.scheme == 'http'))) {
      throw const AuthFailure('CONFIGURATION_ERROR');
    }
    final uri = baseUrl.replace(
      scheme: baseUrl.scheme == 'https' ? 'wss' : 'ws',
      path:
          '${baseUrl.path.replaceFirst(RegExp(r'/+$'), '')}/rooms/${Uri.encodeComponent(roomId)}/events',
    );
    final client = _ChannelHttpClient(baseUrl);
    var cancelled = false;
    try {
      final socket =
          await WebSocket.connect(
                uri.toString(),
                customClient: client,
                headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
                compression: CompressionOptions.compressionOff,
              )
              .then((socket) async {
                if (cancelled) {
                  await socket.close();
                  throw const AuthFailure('NETWORK_ERROR');
                }
                return socket;
              })
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  cancelled = true;
                  client.close(force: true);
                  throw const AuthFailure('NETWORK_ERROR');
                },
              );
      return IoRoomChannel(socket, client);
    } on WebSocketException catch (error) {
      client.close(force: true);
      throw AuthFailure(
        error.httpStatusCode == 401
            ? 'SESSION_INVALID'
            : error.httpStatusCode == 403
            ? 'NOT_ROOM_MEMBER'
            : 'NETWORK_ERROR',
        status: error.httpStatusCode,
      );
    } on IOException {
      client.close(force: true);
      throw const AuthFailure('NETWORK_ERROR');
    }
  }

  @override
  void close() => _http.close();
}

class RoomMember {
  final String id, userId, name;
  final bool ready, connected;
  RoomMember.fromJson(Map<String, dynamic> json)
    : id = json['memberId'] as String,
      userId = json['userId'] as String,
      name = json['username'] as String,
      ready = json['ready'] as bool,
      connected = json['connected'] as bool;
}

class LobbySnapshot {
  final String id, name, state;
  final String? hostId, levelId;
  final int capacity, revision, sequence;
  final DateTime serverTime;
  final List<RoomMember> members;
  final Map<String, dynamic>? match;
  final List<RoomMessage> messages;
  LobbySnapshot.fromJson(Map<String, dynamic> json)
    : id = json['roomId'] as String,
      name = (json['room'] as Map)['name'] as String,
      state = (json['room'] as Map)['state'] as String,
      hostId = (json['room'] as Map)['hostMemberId'] as String?,
      levelId = (json['room'] as Map)['levelId'] as String?,
      capacity = (json['room'] as Map)['capacity'] as int,
      revision = (json['room'] as Map)['revision'] as int,
      sequence = json['sequence'] as int,
      serverTime = DateTime.parse(json['serverTime'] as String),
      match = json['match'] as Map<String, dynamic>?,
      messages = List.unmodifiable([
        for (final m in json['messages'] as List)
          RoomMessage.fromJson(Map<String, dynamic>.from(m as Map)),
      ]),
      members = List.unmodifiable([
        for (final m in (json['room'] as Map)['members'] as List)
          RoomMember.fromJson(Map<String, dynamic>.from(m as Map)),
      ]);
}

class OnlineMatch {
  final String id, levelId, state;
  final int target;
  final Map<String, int> board;
  final bool prepared;
  final Set<String> preparedIds;
  final OnlineRound? round;
  final List<Map<String, dynamic>> scores, claims, zones;
  final Map<String, dynamic>? endVote, result;
  OnlineMatch.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      levelId = json['levelId'] as String,
      state = json['state'] as String,
      target = json['target'] as int,
      board = Map.unmodifiable(
        (json['ownBoard'] as Map? ?? {}).map(
          (key, value) => MapEntry(key as String, value as int),
        ),
      ),
      prepared = json['ownPreparationConfirmed'] == true,
      preparedIds = Set.unmodifiable(
        (json['preparedMemberIds'] as List? ?? []).cast<String>(),
      ),
      scores = _objects(json['scores']),
      claims = _objects(json['claims']),
      zones = _objects(json['zones']),
      endVote = json['endVote'] == null
          ? null
          : Map<String, dynamic>.from(json['endVote'] as Map),
      result = json['result'] == null
          ? null
          : Map<String, dynamic>.from(json['result'] as Map),
      round = json['round'] == null
          ? null
          : OnlineRound.fromJson(
              Map<String, dynamic>.from(json['round'] as Map),
            );
}

List<Map<String, dynamic>> _objects(Object? value) => List.unmodifiable([
  for (final item in value as List? ?? [])
    Map<String, dynamic>.from(item as Map),
]);

class OnlineRound {
  final String id;
  final int number;
  final List<int> dice;
  final DateTime deadline;
  final Set<String> resolvedIds;
  final Map<String, dynamic>? ownAction;
  OnlineRound.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      number = json['number'] as int,
      dice = List.unmodifiable((json['dice'] as List).cast<int>()),
      deadline = DateTime.parse(json['deadline'] as String),
      resolvedIds = Set.unmodifiable(
        (json['resolvedMemberIds'] as List).cast<String>(),
      ),
      ownAction = json['ownAction'] == null
          ? null
          : Map<String, dynamic>.from(json['ownAction'] as Map);
}

String roomsError(AuthFailure error) => switch (error.code) {
  'INVALID_PREPARATION' =>
    'Coloca una vez cada número del 1 al 6 en las casillas iniciales.',
  'PREPARATION_ALREADY_CONFIRMED' ||
  'PREPARATION_CLOSED' => 'La preparación ya fue confirmada.',
  'INVALID_MOVE' =>
    'Esa colocación no cumple las reglas de la zona o del ancla.',
  'MATCH_FINISHED' => 'La partida ya terminó.',
  'VOTE_ACTIVE' => 'Las rondas están en pausa durante la votación.',
  'VOTE_NOT_ACTIVE' => 'Esta votación terminó. Revisa el estado actualizado.',
  'BALLOT_ALREADY_CAST' => 'Tu voto ya quedó confirmado.',
  'ROUND_EXPIRED' => 'La ronda terminó. Espera el estado actualizado.',
  'ACTION_ALREADY_RESOLVED' => 'Ya confirmaste u omitiste esta ronda.',
  'PREPARATION_PENDING' => 'Aún faltan preparaciones por confirmar.',
  'NOT_MATCH_PARTICIPANT' => 'No perteneces a esta partida.',
  'ROOM_FULL' => 'La sala está llena.',
  'ROOM_ALREADY_STARTED' => 'La partida ya comenzó.',
  'ALREADY_IN_ROOM' =>
    'Ya perteneces a una sala. Actualiza para volver a ella.',
  'HOST_ONLY' => 'Solo el anfitrión puede cambiar la configuración.',
  'CAPACITY_BELOW_OCCUPANCY' =>
    'La capacidad no puede ser menor que los jugadores presentes.',
  'STALE_SETTINGS' =>
    'La configuración cambió. Actualiza e inténtalo de nuevo.',
  'NOT_ENOUGH_PLAYERS' => 'Se necesitan al menos dos jugadores.',
  'LEVEL_REQUIRED' => 'Elige un nivel antes de iniciar.',
  'PLAYERS_NOT_READY' =>
    'Faltan jugadores por marcar Listo o recuperar conexión.',
  'ROOM_NOT_FOUND' ||
  'NOT_ROOM_MEMBER' => 'La sala ya no está disponible para tu cuenta.',
  'COMMAND_CONFLICT' => 'No se pudo repetir la operación. Actualiza la sala.',
  'VALIDATION_ERROR' => 'Revisa el nombre de la sala y la capacidad.',
  _ => error.message,
};

class RoomMessage {
  final String id, kind, text;
  final String? authorId, authorName;
  final int sequence;
  final DateTime time;
  RoomMessage.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      text = json['text'] as String,
      authorId = json['authorMemberId'] as String?,
      authorName = json['authorName'] as String?,
      sequence = json['sequence'] as int,
      time = DateTime.parse(json['serverTime'] as String);
}

abstract interface class RoomChannel {
  Stream<Map<String, dynamic>> get frames;
  int? get closeCode;
  void ping();
  Future<void> close();
}

class IoRoomChannel implements RoomChannel {
  final WebSocket socket;
  final HttpClient client;
  IoRoomChannel(this.socket, this.client);
  @override
  int? get closeCode => socket.closeCode;
  @override
  late final Stream<Map<String, dynamic>> frames = socket.map((frame) {
    if (frame is! String || utf8.encode(frame).length > 65536) {
      close();
      throw const FormatException('Mensaje de canal inválido');
    }
    final value = jsonDecode(frame);
    if (value is! Map<String, dynamic>) {
      close();
      throw const FormatException('Mensaje de canal inválido');
    }
    return value;
  });
  @override
  void ping() => socket.add('{"type":"PING"}');
  @override
  Future<void> close() async {
    try {
      await socket.close().timeout(const Duration(seconds: 2));
    } on Object {
      // El cierre no debe bloquear la sustitución de un canal sin respuesta.
    } finally {
      client.close(force: true);
    }
  }
}

/// WebSocket.connect usa openUrl: impedir redirecciones conserva Bearer en el origen elegido.
class _ChannelHttpClient implements HttpClient {
  final HttpClient _client = HttpClient();
  final Uri origin;
  _ChannelHttpClient(this.origin);
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (url.origin != origin.origin || method != 'GET') {
      throw const AuthFailure('CONFIGURATION_ERROR');
    }
    final request = await _client.openUrl(method, url);
    request.followRedirects = false;
    return request;
  }

  @override
  void close({bool force = false}) => _client.close(force: force);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
