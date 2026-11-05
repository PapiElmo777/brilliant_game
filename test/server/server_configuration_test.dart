import 'dart:io';
import 'package:brilliant_game/server/server_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (input, expected) in [
    ('192.168.0.31', 'http://192.168.0.31:8080/api/v1'),
    ('192.168.0.31:8090', 'http://192.168.0.31:8090/api/v1'),
    (' http://192.168.0.31:8080/ ', 'http://192.168.0.31:8080/api/v1'),
    ('http://10.0.2.2:8080/api/v1/', 'http://10.0.2.2:8080/api/v1'),
    ('https://brilliant.example', 'https://brilliant.example/api/v1'),
    ('http://[::1]:8080', 'http://[::1]:8080/api/v1'),
  ]) {
    test(
      'Normaliza $input',
      () => expect(ServerAddress.parse(input).toString(), expected),
    );
  }
  for (final input in [
    '',
    'http://',
    'http://host:0',
    'http://host:99999',
    'http://host:8080/api/v1+',
    'http://host/health/ready',
    'http://user:password@host',
    'http://host?token=abc',
    'http://host/#fragment',
    'ftp://host',
    'http://bad host',
  ]) {
    test(
      'Rechaza $input',
      () => expect(
        () => ServerAddress.parse(input),
        throwsA(isA<ServerConfigurationException>()),
      ),
    );
  }

  test('Comprueba salud sin credenciales y rechaza otras respuestas', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var responseBody = '{"status":"UP"}';
    var status = 200;
    var requests = 0;
    server.listen((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/v1/health/ready');
      expect(request.headers.value('authorization'), isNull);
      request.response.statusCode = status;
      request.response.write(responseBody);
      await request.response.close();
    });
    final address = Uri.parse('http://127.0.0.1:${server.port}/api/v1');
    final probe = HttpServerProbe();
    await probe.check(address);
    responseBody = '{"status":"DOWN"}';
    await expectLater(
      probe.check(address),
      throwsA(isA<ServerConfigurationException>()),
    );
    responseBody = 'HTML inesperado';
    await expectLater(
      probe.check(address),
      throwsA(isA<ServerConfigurationException>()),
    );
    status = 302;
    await expectLater(
      probe.check(address),
      throwsA(isA<ServerConfigurationException>()),
    );
    expect(requests, 4);
  });

  test('Timeout de comprobación informa conexión fallida', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await request.drain<void>();
    });
    await expectLater(
      HttpServerProbe(
        timeout: const Duration(milliseconds: 100),
      ).check(Uri.parse('http://127.0.0.1:${server.port}/api/v1')),
      throwsA(isA<ServerConfigurationException>()),
    );
  });
}
