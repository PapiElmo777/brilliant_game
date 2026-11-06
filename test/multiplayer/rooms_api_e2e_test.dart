import 'dart:io';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Siete clientes Dart contra JAR: lobby de seis, aislamiento y preparación',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'brilliant-rooms-e2e-',
      );
      Process? process;
      final auth = <HttpAuthRepository>[];
      final rooms = <HttpRoomsRepository>[];
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
        final started = await send(0, 'POST', 'rooms/$id/start', {
          'expectedRevision': 1,
        });
        expect((started['data'] as Map)['match']['target'], 20);
        expect((started['data'] as Map)['match']['participants'], hasLength(6));
        for (var i = 0; i < 6; i++) {
          final snapshot = await rooms[i].get(sessions[i].accessToken, id);
          expect((snapshot['room'] as Map)['state'], 'PREPARING');
          expect(
            (snapshot['match'] as Map)['id'],
            (started['data'] as Map)['match']['id'],
          );
        }
        await auth[0].logout(sessions[0].accessToken);
        final transferred = await rooms[1].get(sessions[1].accessToken, id);
        expect((transferred['room'] as Map)['members'], hasLength(5));
        expect((transferred['match'] as Map)['target'], 20);
      } finally {
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
