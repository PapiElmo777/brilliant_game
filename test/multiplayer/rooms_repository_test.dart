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
  test(
    'WebSocket envía Bearer solo en cabecera y recibe la instantánea',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final repo = HttpRoomsRepository(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}/api/v1'),
      );
      addTearDown(() async {
        repo.close();
        await server.close(force: true);
      });
      server.listen((request) async {
        expect(request.uri.path, '/api/v1/rooms/sala-1/events');
        expect(request.uri.query, isEmpty);
        expect(request.headers.value('authorization'), 'Bearer secreto');
        final socket = await WebSocketTransformer.upgrade(request);
        socket.add(jsonEncode({'type': 'SNAPSHOT', 'data': lobbyJson()}));
      });
      final channel = await repo.connect('secreto', 'sala-1');
      final frame = await channel.frames.first;
      expect(frame['type'], 'SNAPSHOT');
      await channel.close();
    },
  );
  test('WebSocket rechaza redirección sin reenviar Bearer', () async {
    final source = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final repo = HttpRoomsRepository(
      baseUrl: Uri.parse('http://127.0.0.1:${source.port}/api/v1'),
    );
    var forwarded = 0;
    addTearDown(() async {
      repo.close();
      await source.close(force: true);
      await target.close(force: true);
    });
    target.listen((request) async {
      forwarded++;
      await request.response.close();
    });
    source.listen((request) async {
      request.response.statusCode = 307;
      request.response.headers.set(
        'location',
        'http://127.0.0.1:${target.port}/events',
      );
      await request.response.close();
    });
    await expectLater(
      repo.connect('secreto', 'sala-1'),
      throwsA(isA<AuthFailure>()),
    );
    expect(forwarded, 0);
  });
}
