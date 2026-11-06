import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:brilliant_game/catalogo/catalogo_tableros.dart';
import 'package:brilliant_game/core/preparacion_inicial.dart';
import 'package:brilliant_game/core/anclas.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Siete clientes Dart contra JAR: preparación privada y rondas comunes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'brilliant-rooms-e2e-',
      );
      Process? process;
      final auth = <HttpAuthRepository>[];
      final rooms = <HttpRoomsRepository>[];
      final channels = <RoomChannel>[];
      final inboxes = <StreamIterator<Map<String, dynamic>>>[];
      try {
        final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = socket.port;
        await socket.close();
        final base = Uri.parse('http://127.0.0.1:$port/api/v1');
        process = await Process.start(
          const String.fromEnvironment(
            'ROOMS_SERVER_JAVA',
            defaultValue:
                '/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java',
          ),
          [
            '-jar',
            File(
              const String.fromEnvironment(
                'ROOMS_SERVER_JAR',
                defaultValue: '../brilliant_server/target/brilliant-server.jar',
              ),
            ).absolute.path,
            '--server.address=127.0.0.1',
            '--server.port=$port',
          ],
          workingDirectory: directory.path,
          environment: {
            'DATA_DIR': '${directory.path}/data',
            'BIND_ADDRESS': '127.0.0.1',
            'PORT': '$port',
            'RECORD_TEST_ACCOUNTS': 'false',
            'REGISTER_IP_LIMIT': '100',
          },
        );
        process.stdout.drain<void>();
        process.stderr.drain<void>();
        final health = HttpClient()
          ..connectionTimeout = const Duration(seconds: 1);
        bool ready = false;
        try {
          for (var attempt = 0; attempt < 150; attempt++) {
            try {
              final response = await (await health.getUrl(
                base.resolve('/api/v1/health/ready'),
              )).close();
              await response.drain<void>();
              if (response.statusCode == 200) {
                ready = true;
                break;
              }
            } on IOException {
              /* Arranque aún en curso. */
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        } finally {
          health.close(force: true);
        }
        expect(
          ready,
          isTrue,
          reason: 'El JAR debe arrancar con datos temporales.',
        );
        final sessions = <AuthSession>[];
        for (var i = 0; i < 7; i++) {
          auth.add(HttpAuthRepository(baseUrl: base));
          rooms.add(HttpRoomsRepository(baseUrl: base));
          sessions.add(await auth.last.register('Piloto$i', 'a!2'));
        }
        var sequence = 0;
        Future<Map<String, dynamic>> send(
          int user,
          String method,
          String path, [
          Map<String, Object?> fields = const {},
        ]) => rooms[user].command(sessions[user].accessToken, method, path, {
          'commandId':
              '00000000-0000-4000-8000-${(++sequence).toString().padLeft(12, '0')}',
          ...fields,
        });
        final created = await send(0, 'POST', 'rooms', {
          'name': 'Seis desde Dart',
          'capacity': 6,
        });
        final id = created['roomId'] as String;
        for (var i = 1; i < 6; i++) {
          await send(i, 'POST', 'rooms/$id/join');
        }
        await expectLater(
          send(6, 'POST', 'rooms/$id/join'),
          throwsA(
            isA<AuthFailure>().having((e) => e.code, 'code', 'ROOM_FULL'),
          ),
        );
        final selected = await send(0, 'PATCH', 'rooms/$id/settings', {
          'expectedRevision': 0,
          'capacity': 6,
          'levelId': 'tablero_02',
        });
        final expected = (selected['data'] as Map)['room'];
        for (var i = 0; i < 6; i++) {
          final snapshot = await rooms[i].get(sessions[i].accessToken, id);
          expect(snapshot['room'], expected);
        }
        await expectLater(
          send(1, 'PATCH', 'rooms/$id/settings', {
            'expectedRevision': 1,
            'capacity': 6,
            'levelId': 'tablero_03',
          }),
          throwsA(
            isA<AuthFailure>().having((e) => e.code, 'code', 'HOST_ONLY'),
          ),
        );
        for (var i = 1; i < 6; i++) {
          await send(i, 'PUT', 'rooms/$id/ready', {
            'expectedRevision': 1,
            'ready': true,
          });
        }
        Future<Map<String, dynamic>> next(int index, String type) async {
          final inbox = inboxes[index];
          while (await inbox.moveNext().timeout(const Duration(seconds: 10))) {
            if (inbox.current['type'] == type) return inbox.current;
          }
          throw StateError('El canal terminó antes de $type');
        }

        for (var i = 0; i < 6; i++) {
          final channel = await rooms[i].connect(sessions[i].accessToken, id);
          channels.add(channel);
          inboxes.add(StreamIterator(channel.frames));
          expect((await next(i, 'SNAPSHOT'))['roomId'], id);
        }
        final chat = await send(1, 'POST', 'rooms/$id/messages', {
          'text': 'Saludos desde Dart 🚀',
        });
        for (var i = 0; i < 6; i++) {
          final frame = await next(i, 'MESSAGE_CREATED');
          expect(frame['sequence'], chat['sequence']);
          expect(
            ((frame['data'] as Map)['messages'] as List).last['text'],
            'Saludos desde Dart 🚀',
          );
        }
        final member =
            ((await rooms[2].get(sessions[2].accessToken, id))['room']
                as Map)['members'][2]['memberId'];
        await channels[2].close();
        await inboxes[2].cancel();
        final rotated = await auth[2].refresh(sessions[2].refreshToken!);
        sessions[2] = rotated;
        final reconnected = await rooms[2].connect(rotated.accessToken, id);
        channels[2] = reconnected;
        inboxes[2] = StreamIterator(reconnected.frames);
        final restored = await next(2, 'SNAPSHOT');
        expect(
          (restored['data'] as Map)['room']['members'][2]['memberId'],
          member,
        );
        expect(
          (restored['data'] as Map)['room']['members'][2]['ready'],
          isTrue,
        );
        expect((restored['data'] as Map)['room']['levelId'], 'tablero_02');
        expect(
          ((restored['data'] as Map)['messages'] as List).last['text'],
          'Saludos desde Dart 🚀',
        );
        channels[0].ping();
        await next(0, 'PONG');
        final other = await send(6, 'POST', 'rooms', {
          'name': 'Sala aislada',
          'capacity': 2,
        });
        await expectLater(
          rooms[0].get(sessions[0].accessToken, other['roomId'] as String),
          throwsA(
            isA<AuthFailure>().having((e) => e.code, 'code', 'NOT_ROOM_MEMBER'),
          ),
        );
        final otherFrames = <Map<String, dynamic>>[];
        final isolated = await rooms[6].connect(
          sessions[6].accessToken,
          other['roomId'] as String,
        );
        channels.add(isolated);
        final isolatedReady = Completer<void>();
        final otherSubscription = isolated.frames.listen((frame) {
          otherFrames.add(frame);
          if (!isolatedReady.isCompleted) isolatedReady.complete();
        });
        await isolatedReady.future.timeout(const Duration(seconds: 10));
        final started = await send(0, 'POST', 'rooms/$id/start', {
          'expectedRevision': 1,
        });
        expect((started['data'] as Map)['match']['target'], 20);
        expect((started['data'] as Map)['match']['participants'], hasLength(6));
        for (var i = 0; i < 6; i++) {
          final frame = await next(i, 'MATCH_STARTED');
          final snapshot = frame['data'] as Map;
          expect((snapshot['room'] as Map)['state'], 'PREPARING');
          expect(
            (snapshot['match'] as Map)['id'],
            (started['data'] as Map)['match']['id'],
          );
        }
        await send(3, 'POST', 'rooms/$id/messages', {
          'text': 'Chat durante preparación',
        });
        for (var i = 0; i < 6; i++) {
          await next(i, 'MESSAGE_CREATED');
        }
        expect(
          otherFrames.where((f) => f['type'] == 'MESSAGE_CREATED'),
          isEmpty,
        );
        await isolated.close();
        await otherSubscription.cancel();
        final preparedBoards = <Map<String, int>>[];
        for (var i = 0; i < 6; i++) {
          final preparation = PreparacionInicial(
            CatalogoTableros.predeterminado().crearTablero('tablero_02'),
          );
          for (final (cell, value) in preparation.distribucionAleatoria(
            Random(i + 17),
          )) {
            preparation.colocarValor(cell, value);
          }
          preparedBoards.add({
            for (final c in preparation.celdas.values)
              if (c.valor != null) c.id: c.valor!,
          });
        }
        for (var actor = 0; actor < 6; actor++) {
          final accepted = await send(
            actor,
            'PUT',
            'matches/${(started['data'] as Map)['match']['id']}/preparation',
            {'placements': preparedBoards[actor]},
          );
          expect(
            (accepted['data'] as Map)['match']['ownBoard'],
            preparedBoards[actor],
          );
          for (var viewer = 0; viewer < 6; viewer++) {
            final event = await next(viewer, 'PREPARATION_CONFIRMED');
            expect(
              (event['data'] as Map)['match']['ownBoard'],
              viewer <= actor ? preparedBoards[viewer] : <String, int>{},
            );
          }
        }
        Map<String, dynamic>? commonRound;
        for (var viewer = 0; viewer < 6; viewer++) {
          final event = await next(viewer, 'ROUND_STARTED');
          final game = (event['data'] as Map)['match'] as Map;
          expect(game['ownBoard'], preparedBoards[viewer]);
          final round = Map<String, dynamic>.from(game['round'] as Map);
          if (commonRound == null) {
            commonRound = round;
          } else {
            expect(round, commonRound);
          }
          expect(
            DateTime.parse(
              round['deadline'] as String,
            ).difference(DateTime.parse(round['startedAt'] as String)),
            const Duration(seconds: 60),
          );
        }
        final matchId = (started['data'] as Map)['match']['id'] as String;
        final roundId = commonRound!['id'] as String;
        final dice = (commonRound['dice'] as List).cast<int>();
        int? placingPlayer, selectedDie;
        String? destination;
        for (var player = 0; player < 6 && placingPlayer == null; player++) {
          final board = CatalogoTableros.predeterminado().crearTablero(
            'tablero_02',
          );
          for (final e in preparedBoards[player].entries) {
            board.colocarValor(e.key, e.value);
          }
          for (var die = 0; die < 2; die++) {
            final legal = destinosConAncla(board, dice[die], dice[1 - die]);
            if (legal.isNotEmpty) {
              placingPlayer = player;
              selectedDie = die;
              destination = legal.first;
              break;
            }
          }
        }
        expect(placingPlayer, isNotNull);
        final order = [
          placingPlayer!,
          for (var i = 0; i < 6; i++)
            if (i != placingPlayer) i,
        ];
        for (final player in order) {
          await send(
            player,
            'POST',
            'matches/$matchId/rounds/$roundId/actions',
            player == placingPlayer
                ? {
                    'kind': 'PLACE',
                    'dieIndex': selectedDie,
                    'cellId': destination,
                  }
                : {'kind': 'SKIP'},
          );
          if (player == placingPlayer) {
            preparedBoards[player][destination!] = dice[selectedDie!];
          }
          for (var viewer = 0; viewer < 6; viewer++) {
            final event = await next(viewer, 'ACTION_RESOLVED');
            expect(
              (event['data'] as Map)['match']['ownBoard'],
              preparedBoards[viewer],
            );
          }
        }
        Map<String, dynamic>? secondRound;
        for (var viewer = 0; viewer < 6; viewer++) {
          final event = await next(viewer, 'ROUND_STARTED');
          final game = (event['data'] as Map)['match'] as Map;
          expect(game['ownBoard'], preparedBoards[viewer]);
          final round = Map<String, dynamic>.from(game['round'] as Map);
          expect(round['number'], 2);
          expect(round['id'], isNot(roundId));
          if (secondRound == null) {
            secondRound = round;
          } else {
            expect(round, secondRound);
          }
        }
        await expectLater(
          send(0, 'POST', 'matches/$matchId/rounds/$roundId/actions', {
            'kind': 'SKIP',
          }),
          throwsA(
            isA<AuthFailure>().having((e) => e.code, 'code', 'ROUND_EXPIRED'),
          ),
        );
        await channels[placingPlayer].close();
        await inboxes[placingPlayer].cancel();
        final recovered = await rooms[placingPlayer].connect(
          sessions[placingPlayer].accessToken,
          id,
        );
        channels[placingPlayer] = recovered;
        inboxes[placingPlayer] = StreamIterator(recovered.frames);
        final recoveredFrame = await next(placingPlayer, 'SNAPSHOT');
        expect(
          (recoveredFrame['data'] as Map)['match']['ownBoard'],
          preparedBoards[placingPlayer],
        );
        expect(
          (recoveredFrame['data'] as Map)['match']['round']['id'],
          secondRound!['id'],
        );
        await auth[0].logout(sessions[0].accessToken);
        final transferred = await rooms[1].get(sessions[1].accessToken, id);
        expect((transferred['room'] as Map)['members'], hasLength(5));
        expect((transferred['match'] as Map)['target'], 20);
      } finally {
        for (final channel in channels) {
          await channel.close();
        }
        for (final inbox in inboxes) {
          await inbox.cancel();
        }
        for (final repo in rooms) {
          repo.close();
        }
        for (final repo in auth) {
          repo.close();
        }
        if (process != null) {
          process.kill();
          try {
            await process.exitCode.timeout(const Duration(seconds: 10));
          } on Object {
            process.kill(ProcessSignal.sigkill);
            await process.exitCode;
          }
        }
        await directory.delete(recursive: true);
      }
    },
    skip: !const bool.fromEnvironment('RUN_ROOMS_API_E2E'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
