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
  void close();
}

/// Reutiliza las restricciones de origen, TLS, tamaño, timeout y redirecciones.
class HttpRoomsRepository implements RoomsRepository {
  final HttpAuthRepository _http;
  HttpRoomsRepository({required Uri baseUrl})
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
  final List<RoomMember> members;
  final Map<String, dynamic>? match;
  LobbySnapshot.fromJson(Map<String, dynamic> json)
    : id = json['roomId'] as String,
      name = (json['room'] as Map)['name'] as String,
      state = (json['room'] as Map)['state'] as String,
      hostId = (json['room'] as Map)['hostMemberId'] as String?,
      levelId = (json['room'] as Map)['levelId'] as String?,
      capacity = (json['room'] as Map)['capacity'] as int,
      revision = (json['room'] as Map)['revision'] as int,
      sequence = json['sequence'] as int,
      match = json['match'] as Map<String, dynamic>?,
      members = List.unmodifiable([
        for (final m in (json['room'] as Map)['members'] as List)
          RoomMember.fromJson(Map<String, dynamic>.from(m as Map)),
      ]);
}

String roomsError(AuthFailure error) => switch (error.code) {
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
