import 'dart:async';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';

Map<String, dynamic> lobbyJson({
  bool guest = false,
  String state = 'LOBBY',
  int revision = 0,
  String? levelId,
  int sequence = 1,
  bool guestReady = false,
}) => {
  'protocolVersion': 1,
  'rulesVersion': 1,
  'roomId': 'sala-1',
  'sequence': sequence,
  'serverTime': '2026-11-05T00:00:00Z',
  'room': {
    'id': 'sala-1',
    'name': 'Escuadrón Brilliant',
    'state': state,
    'capacity': 6,
    'hostMemberId': guest ? 'otro' : 'propio',
    'levelId': levelId,
    'revision': revision,
    'members': [
      {
        'memberId': 'propio',
        'userId': 'uuid-de-prueba',
        'username': 'Ana',
        'joinOrder': 1,
        'ready': guestReady,
        'connected': true,
      },
      {
        'memberId': 'otro',
        'userId': 'otro-usuario',
        'username': 'Beto',
        'joinOrder': 2,
        'ready': guestReady,
        'connected': true,
      },
    ],
  },
  'messages': [],
  'match': state == 'LOBBY'
      ? null
      : {
          'id': 'partida-1',
          'target': 26,
          'state': 'PREPARING',
          'levelId': levelId,
        },
};

class FakeRoomsRepository implements RoomsRepository {
  Map<String, dynamic>? snapshot;
  AuthFailure? failure;
  bool loseNextResponse = false;
  Completer<Map<String, dynamic>>? pendingList;
  final commands = <Map<String, Object?>>[];
  final paths = <String>[];
  final receipts = <String, Map<String, dynamic>>{};
  final bool guest;
  int reads = 0;
  FakeRoomsRepository({this.guest = false});
  @override
  Future<Map<String, dynamic>> list(String token) async {
    reads++;
    if (failure != null) throw failure!;
    if (pendingList != null) return pendingList!.future;
    return {'rooms': [], 'currentRoomId': snapshot?['roomId']};
  }

  @override
  Future<Map<String, dynamic>> get(String token, String roomId) async {
    reads++;
    if (failure != null) throw failure!;
    return snapshot!;
  }

  @override
  Future<Map<String, dynamic>> command(
    String token,
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    commands.add(Map.from(body));
    paths.add('$method $path');
    if (failure != null) throw failure!;
    final id = body['commandId'] as String;
    if (receipts[id] case final Map<String, dynamic> receipt) return receipt;
    snapshot ??= lobbyJson(guest: guest);
    final room = snapshot!['room'] as Map;
    final updated = Map<String, dynamic>.from(room);
    if (path.endsWith('/settings')) {
      updated['capacity'] = body['capacity'];
      updated['levelId'] = body['levelId'];
      updated['revision'] = (room['revision'] as int) + 1;
    }
    if (path.endsWith('/random-level')) {
      updated['levelId'] = 'tablero_03';
      updated['revision'] = (room['revision'] as int) + 1;
    }
    if (path.endsWith('/ready')) {
      updated['members'] = [
        for (final m in room['members'] as List)
          {...m as Map, if (m['memberId'] == 'propio') 'ready': body['ready']},
      ];
    }
    if (path.endsWith('/start')) {
      updated['state'] = 'PREPARING';
    }
    snapshot = {
      ...snapshot!,
      'room': updated,
      'sequence': (snapshot!['sequence'] as int) + 1,
      if (path.endsWith('/start'))
        'match': {
          'id': 'partida-1',
          'target': 26,
          'state': 'PREPARING',
          'levelId': updated['levelId'],
        },
    };
    final response = <String, dynamic>{
      'commandId': id,
      'roomId': 'sala-1',
      'sequence': snapshot!['sequence'],
      'data': snapshot,
    };
    receipts[id] = response;
    if (path.endsWith('/leave')) snapshot = null;
    if (loseNextResponse) {
      loseNextResponse = false;
      throw const AuthFailure('NETWORK_ERROR');
    }
    return response;
  }

  @override
  void close() {}
}
