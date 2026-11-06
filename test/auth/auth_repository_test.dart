import 'dart:convert';
import 'dart:io';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late HttpAuthRepository repository;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    repository = HttpAuthRepository(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
    );
  });
  tearDown(() async {
    repository.close();
    await server.close(force: true);
  });

  test(
    'Contrato real HTTP: registro, login y DELETE JSON con Bearer',
    () async {
      final requests = <String>[];
      server.listen((request) async {
        requests.add('${request.method} ${request.uri.path}');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body.values, contains(' contraseña sin recortar '));
        expect(request.uri.query, isEmpty);
        if (request.method == 'DELETE') {
          expect(request.headers.value('authorization'), 'Bearer token');
          expect(body.keys, ['currentPassword']);
          request.response.statusCode = 204;
        } else {
          expect(body.keys, ['username', 'password']);
          expect(body['username'], 'Piloto');
          expect(request.headers.value('authorization'), isNull);
          request.response.statusCode = request.uri.path.endsWith('register')
              ? 201
              : 200;
          request.response.write(
            jsonEncode({
              'user': {'id': 'uuid', 'username': 'Piloto'},
              'accessToken': 'token',
              'tokenType': 'Bearer',
              'expiresIn': 600,
              'refreshToken': 'refresh-in-memory',
            }),
          );
        }
        await request.response.close();
      });
      final registered = await repository.register(
        ' Piloto ',
        ' contraseña sin recortar ',
      );
      final logged = await repository.login(
        'Piloto',
        ' contraseña sin recortar ',
      );
      expect(registered.user.id, logged.user.id);
      await repository.deleteAccount(
        logged.accessToken,
        ' contraseña sin recortar ',
      );
      expect(requests, [
        'POST /api/v1/auth/register',
        'POST /api/v1/auth/login',
        'DELETE /api/v1/users/me',
      ]);
    },
  );

  test('Refresh usa cuerpo JSON sin Bearer ni secreto en URL', () async {
    server.listen((request) async {
      expect(request.uri.path, '/api/v1/auth/refresh');
      expect(request.uri.query, isEmpty);
      expect(request.headers.value('authorization'), isNull);
      expect(jsonDecode(await utf8.decoder.bind(request).join()), {
        'refreshToken': 'old-secret',
      });
      request.response.write(
        jsonEncode({
          'user': {'id': 'uuid', 'username': 'Piloto'},
          'accessToken': 'new-access',
          'refreshToken': 'new-secret',
          'tokenType': 'Bearer',
          'expiresIn': 600,
        }),
      );
      await request.response.close();
    });
    final session = await repository.refresh('old-secret');
    expect(session.accessToken, 'new-access');
    expect(session.refreshToken, 'new-secret');
  });

  for (final path in ['/api/v1+', '/api/v1/health/ready', '']) {
    test(
      'URL inválida se rechaza antes de enviar credenciales: $path',
      () async {
        repository.close();
        repository = HttpAuthRepository(
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}$path'),
        );
        await expectLater(
          repository.login('Piloto', 'a!2'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.code,
              'code',
              'CONFIGURATION_ERROR',
            ),
          ),
        );
        await expectLater(
          repository.register('Piloto', 'a!2'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.code,
              'code',
              'CONFIGURATION_ERROR',
            ),
          ),
        );
      },
    );
  }

  test('Logout envía POST sin cuerpo, con Bearer y espera 204', () async {
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/auth/logout');
      expect(request.headers.value('authorization'), 'Bearer token');
      expect(await utf8.decoder.bind(request).join(), isEmpty);
      request.response.statusCode = 204;
      await request.response.close();
    });
    await repository.logout('token');
  });

  test('Logout no confirma éxito con respuesta distinta de 204', () async {
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 200;
      await request.response.close();
    });
    await expectLater(repository.logout('token'), throwsA(isA<AuthFailure>()));
  });

  test('Errores estructurados y Retry-After', () async {
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 429;
      request.response.headers.set('retry-after', '4');
      request.response.write('{"error":{"code":"RATE_LIMITED"}}');
      await request.response.close();
    });
    await expectLater(
      repository.login('Piloto', 'contraseña de pruebas'),
      throwsA(
        isA<AuthFailure>()
            .having((e) => e.code, 'code', 'RATE_LIMITED')
            .having((e) => e.retryAfter, 'espera', 4),
      ),
    );
  });

  test('No sigue redirecciones con credenciales', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      request.response.statusCode = 307;
      request.response.headers.set('location', '/destino');
      await request.response.close();
    });
    await expectLater(
      repository.deleteAccount('token', 'contraseña'),
      throwsA(isA<AuthFailure>()),
    );
    expect(requests, 1);
  });

  test('Timeout de mutación no reintenta', () async {
    repository.close();
    repository = HttpAuthRepository(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}/api/v1'),
      timeout: const Duration(milliseconds: 100),
    );
    var requests = 0;
    server.listen((request) async {
      requests++;
      await request.drain<void>();
    });
    await expectLater(
      repository.deleteAccount('token', 'contraseña'),
      throwsA(
        isA<AuthFailure>().having((e) => e.code, 'code', 'NETWORK_ERROR'),
      ),
    );
    expect(requests, 1);
  });

  test('Respuesta de sesión inválida no autentica', () async {
    server.listen((request) async {
      await request.drain<void>();
      request.response.write('{"accessToken":"token"}');
      await request.response.close();
    });
    await expectLater(
      repository.login('Piloto', 'contraseña'),
      throwsA(isA<AuthFailure>()),
    );
  });
}
