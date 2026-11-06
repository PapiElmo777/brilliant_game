import 'dart:convert';
import 'dart:io';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';

void main() {
  test(
    'HTTP de salas envía Bearer, enteros y commandId; no sigue redirecciones',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final repo = HttpRoomsRepository(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}/api/v1'),
      );
      addTearDown(() async {
        repo.close();
        await server.close(force: true);
      });
      final paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        expect(request.headers.value('authorization'), 'Bearer acceso');
        expect(request.uri.query, isEmpty);
        if (request.method == 'POST') {
          final body = jsonDecode(await utf8.decoder.bind(request).join());
          expect(body, {
            'commandId': 'id-del-comando',
            'name': 'Escuadrón',
            'capacity': 6,
          });
          request.response.write(jsonEncode({'data': lobbyJson()}));
        } else {
          request.response.statusCode = 307;
          request.response.headers.set('location', '/destino');
        }
        await request.response.close();
      });
      final result = await repo.command('acceso', 'POST', 'rooms', {
        'commandId': 'id-del-comando',
        'name': 'Escuadrón',
        'capacity': 6,
      });
      expect((result['data'] as Map)['roomId'], 'sala-1');
      await expectLater(repo.list('acceso'), throwsA(isA<AuthFailure>()));
      expect(paths, ['/api/v1/rooms', '/api/v1/rooms']);
    },
  );
}
