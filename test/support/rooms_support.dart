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
      if (path.endsWith('/messages'))
        'messages': [
          ...snapshot!['messages'] as List,
          {
            'id': id,
            'sequence': (snapshot!['sequence'] as int) + 1,
            'kind': 'PLAYER',
            'text': body['text'],
            'authorMemberId': 'propio',
            'authorName': 'Ana',
            'serverTime': '2026-11-06T00:00:00Z',
          },
        ],
      if (path.endsWith('/start'))
        'match': {
          'id': 'partida-1',
          'target': 26,
          'state': 'PREPARING',
          'levelId': updated['levelId'],
        },
    };
    if (path.endsWith('/preparation')) {
      final game = Map<String, dynamic>.from(snapshot!['match'] as Map);
      game['ownBoard'] = Map<String, Object?>.from(body['placements'] as Map);
      game['ownPreparationConfirmed'] = true;
      game['preparedMemberIds'] = [
        ...game['preparedMemberIds'] as List? ?? [],
        'propio',
      ];
      snapshot = {...snapshot!, 'match': game};
    }
    if (path.endsWith('/actions')) {
      final game = Map<String, dynamic>.from(snapshot!['match'] as Map);
      final round = Map<String, dynamic>.from(game['round'] as Map);
      round['ownAction'] = {
        'kind': body['kind'],
        'dieIndex': body['dieIndex'],
        'cellId': body['cellId'],
        'reason': 'PLAYER',
      };
      round['resolvedMemberIds'] = [
        ...round['resolvedMemberIds'] as List,
        'propio',
      ];
      if (body['kind'] == 'PLACE') {
        game['ownBoard'] = {
          ...game['ownBoard'] as Map,
          body['cellId']: (round['dice'] as List)[body['dieIndex'] as int],
        };
      }
      game['round'] = round;
      snapshot = {...snapshot!, 'match': game};
    }
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

  final channels = <FakeRoomChannel>[];
  final channelTokens = <String>[];
  @override
  Future<RoomChannel> connect(String token, String roomId) async {
    channelTokens.add(token);
    final channel = FakeRoomChannel(snapshot!);
    channels.add(channel);
    return channel;
  }

  void publish(Map<String, dynamic> value, {String type = 'READY_CHANGED'}) {
    snapshot = value;
    for (final channel in channels.where((c) => !c.closed)) {
      channel.add(type, value);
    }
  }

  @override
  Future<Map<String, dynamic>> history(
    String token,
    String roomId,
    int? before,
  ) async => {'messages': [], 'nextBefore': null};
  @override
  void close() {}
}

class FakeRoomChannel implements RoomChannel {
  late final StreamController<Map<String, dynamic>> controller;
  bool closed = false;
  int? code;
  int pings = 0;
  bool respondToPings = true;
  FakeRoomChannel(Map<String, dynamic> initial) {
    controller = StreamController(
      onListen: () => scheduleMicrotask(() => add('SNAPSHOT', initial)),
    );
  }
  void add(String type, Map<String, dynamic> data) {
    if (!closed) {
      controller.add({
        'protocolVersion': 1,
        'roomId': data['roomId'],
        'sequence': data['sequence'],
        'type': type,
        'data': data,
      });
    }
  }

  @override
  Stream<Map<String, dynamic>> get frames => controller.stream;
  @override
  int? get closeCode => code;
  @override
  void ping() {
    pings++;
    if (!closed && respondToPings) controller.add({'type': 'PONG'});
  }

  @override
  Future<void> close() async {
    closed = true;
    controller.close();
  }

  void disconnect([int? closeCode]) {
    code = closeCode;
    close();
  }
}

Map<String, int> onlinePreparation() => {
  'f1_c2': 1,
  'f2_c6': 2,
  'f4_c2': 3,
  'f4_c5': 4,
  'f6_c3': 5,
  'f7_c5': 6,
};
Map<String, dynamic> onlineSnapshot({
  bool prepared = false,
  bool playing = false,
  bool resolved = false,
  int roundNumber = 1,
  Map<String, int>? board,
  int sequence = 5,
}) => {
  ...lobbyJson(
    state: playing ? 'PLAYING' : 'PREPARING',
    levelId: 'tablero_01',
    sequence: sequence,
  ),
  'serverTime': '2026-11-06T00:00:00Z',
  'match': {
    'id': 'partida-1',
    'state': playing ? 'ROUND_ACTIVE' : 'PREPARING',
    'levelId': 'tablero_01',
    'target': 26,
    'participants': [],
    'preparedMemberIds': prepared ? ['propio', 'otro'] : [],
    'ownBoard': board ?? (prepared ? onlinePreparation() : <String, int>{}),
    'ownPreparationConfirmed': prepared,
    'round': !playing
        ? null
        : {
            'id': 'ronda-$roundNumber',
            'number': roundNumber,
            'dice': [1, 2],
            'startedAt': '2026-11-06T00:00:00Z',
            'deadline': '2026-11-06T00:01:00Z',
            'resolvedMemberIds': resolved ? ['propio'] : [],
            'ownAction': resolved
                ? {
                    'kind': 'SKIP',
                    'reason': 'PLAYER',
                    'dieIndex': null,
                    'cellId': null,
                  }
                : null,
          },
    'result': null,
  },
};
