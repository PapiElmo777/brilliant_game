import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:brilliant_game/audio/audio_events.dart';
import 'package:brilliant_game/audio/game_audio.dart';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/multiplayer/rooms_cubit.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/auth_support.dart';
import '../support/rooms_support.dart';
import 'audio_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAudioBackend backend;
  late GameAudio audio;
  late AudioEvents events;
  late AuthCubit auth;
  late RoomsCubit rooms;
  late DateTime time;
  RoomsState state({
    int seconds = 60,
    bool resolved = false,
    int round = 1,
    bool connected = true,
    List<Map<String, dynamic>> claims = const [],
    List<RoomMessage> messages = const [],
    int unread = 0,
    bool history = false,
  }) {
    final json = onlineSnapshot(
      prepared: true,
      playing: true,
      resolved: resolved,
      roundNumber: round,
    );
    (json['match'] as Map)['claims'] = claims;
    return RoomsState(
      lobby: LobbySnapshot.fromJson(json),
      secondsRemaining: seconds,
      channelConnected: connected,
      messages: messages,
      unread: unread,
      loadingHistory: history,
    );
  }

  Future<void> change(RoomsState a, RoomsState b) async {
    time = time.add(const Duration(seconds: 3));
    events.onChange(rooms, Change(currentState: a, nextState: b));
    await flushAudio();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    time = DateTime(2026);
    backend = FakeAudioBackend();
    audio = GameAudio(backend: backend, now: () => time);
    await audio.start();
    await flushAudio();
    events = AudioEvents(audio);
    auth = AuthCubit(FakeAuthRepository());
    await auth.authenticate('Ana', 'a!2', register: false);
    rooms = RoomsCubit(FakeRoomsRepository(), auth);
    await change(const RoomsState(), state());
    backend.played.clear();
  });
  tearDown(() async {
    await rooms.close();
    await auth.close();
    await audio.shutdown();
  });
  test('Countdown warns at 30, emphasizes last three, and ends once', () async {
    var previous = state();
    for (final second in [31, 30, 29, 10, 9, 3, 2, 1, 0]) {
      final next = state(seconds: second);
      await change(previous, next);
      previous = next;
    }
    expect(backend.effects, [
      'thirty.wav',
      'tick.wav',
      'tick.wav',
      'tick_final.wav',
      'tick_final.wav',
      'tick_final.wav',
      'timeout.wav',
    ]);
  });
  test('Resolved moves stay silent throughout the countdown', () async {
    await change(state(), state(seconds: 31, resolved: true));
    backend.played.clear();
    await change(
      state(seconds: 31, resolved: true),
      state(seconds: 30, resolved: true),
    );
    await change(
      state(seconds: 30, resolved: true),
      state(seconds: 10, resolved: true),
    );
    expect(backend.effects, isEmpty);
  });
  test('Clock corrections cannot repeat a countdown second', () async {
    await change(state(), state(seconds: 10));
    await change(state(seconds: 10), state(seconds: 11));
    await change(state(seconds: 11), state(seconds: 10));
    expect(backend.effects, ['tick.wav']);
  });
  test('Background time is consumed without replay on resume', () async {
    audio.setForeground(false);
    await change(state(), state(seconds: 30));
    audio.setForeground(true);
    await change(state(seconds: 30), state(seconds: 29));
    expect(backend.effects, isEmpty);
  });
  test('New round resets the countdown baseline', () async {
    await change(state(), state(seconds: 0));
    backend.played.clear();
    await change(state(seconds: 0), state(round: 2));
    await change(state(round: 2), state(round: 2, seconds: 30));
    expect(backend.effects, ['thirty.wav']);
  });
  test('Snapshot refresh never replays a zone claim', () async {
    final claim = <String, dynamic>{
      'memberId': 'propio',
      'zoneId': 'z1',
      'place': 1,
      'points': 4,
    };
    final next = state(claims: [claim]);
    await change(state(), next);
    await change(
      next,
      state(
        claims: [
          Map<String, dynamic>.from(jsonDecode(jsonEncode(claim)) as Map),
        ],
      ),
    );
    expect(backend.effects, ['zone_1.wav']);
  });
  test(
    'Other player claims distinguish a paid slot from exhausted zone',
    () async {
      final first = <String, dynamic>{
        'memberId': 'otro',
        'zoneId': 'z1',
        'place': 1,
        'points': 4,
      };
      final last = <String, dynamic>{
        'memberId': 'otro',
        'zoneId': 'z2',
        'place': 3,
        'points': 1,
      };
      final next = state(claims: [first]);
      await change(state(), next);
      await change(next, state(claims: [first, last]));
      expect(backend.effects, ['zone_other.wav', 'zone_exhausted.wav']);
    },
  );
  RoomMessage message(int seq, {String author = 'otro'}) =>
      RoomMessage.fromJson({
        'id': 'm$seq',
        'kind': 'PLAYER',
        'text': 'hola',
        'authorMemberId': author,
        'authorName': 'Beto',
        'sequence': seq,
        'serverTime': '2026-11-06T00:00:00Z',
      });
  test(
    'Chat sounds once for a fresh message; old history stays silent',
    () async {
      final next = state(messages: [message(5)], unread: 1);
      await change(state(), next);
      await change(
        next,
        state(messages: [message(1), message(5)], unread: 1, history: true),
      );
      await change(next, state(messages: [message(5)], unread: 1));
      expect(backend.effects, ['chat.wav']);
    },
  );
  test(
    'Open chat and reconnect backlog do not emit received notices',
    () async {
      await change(state(), state(messages: [message(5)]));
      await change(
        state(connected: false),
        state(messages: [message(6)], unread: 1),
      );
      expect(backend.effects, isEmpty);
    },
  );
  test('Own message has a distinct transmission sound', () async {
    await change(state(), state(messages: [message(6, author: 'propio')]));
    expect(backend.effects, ['sent.wav']);
  });
  test('Server-confirmed omission sounds once', () async {
    final next = state(resolved: true);
    await change(state(), next);
    await change(next, state(resolved: true));
    expect(backend.effects, ['skip.wav']);
  });
  test(
    'Leaving a room preserves its exit cue across the music change',
    () async {
      await change(state(), const RoomsState());
      expect(backend.effects, ['disconnect.wav']);
      expect(audio.scene, AudioScene.menu);
    },
  );
  test('Connection loss overrides existing celebration', () async {
    audio.play(GameSound.victory);
    await flushAudio();
    backend.played.clear();
    events.onChange(
      auth,
      Change(
        currentState: auth.state,
        nextState: const AuthState(connectionLost: true),
      ),
    );
    await flushAudio();
    expect(backend.effects, ['alert.wav']);
    expect(audio.scene, AudioScene.menu);
  });
}
