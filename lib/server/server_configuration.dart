import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfigurationException implements Exception {
  final String message;
  const ServerConfigurationException(this.message);
}

abstract final class ServerAddress {
  static Uri parse(String input) {
    final value = input.trim();
    if (value.isEmpty || RegExp(r'\s').hasMatch(value)) {
      throw const ServerConfigurationException(
        'Escribe la dirección del servidor, por ejemplo http://192.168.0.31:8080.',
      );
    }
    final hasScheme = value.contains('://');
    final uri = Uri.tryParse(hasScheme ? value : 'http://$value');
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['http', 'https'].contains(uri.scheme) ||
        (uri.port == 0 || uri.port > 65535)) {
      throw const ServerConfigurationException(
        'La dirección no es válida. Usa una IP o un nombre de servidor con su puerto.',
      );
    }
    if (!kDebugMode && uri.scheme != 'https') {
      throw const ServerConfigurationException(
        'Esta versión requiere una dirección HTTPS.',
      );
    }
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.isNotEmpty && !path.endsWith('/api/v1')) {
      throw const ServerConfigurationException(
        'Introduce la dirección del servidor o una ruta que termine exactamente en /api/v1.',
      );
    }
    return uri.replace(
      path: path.isEmpty ? '/api/v1' : path,
      port: !hasScheme && !uri.hasPort ? 8080 : null,
    );
  }
}

abstract interface class ServerSettingsStore {
  Future<String?> read();
  Future<void> write(String address);
}

/// Guarda exclusivamente la dirección. No almacena usuarios, claves ni tokens.
class PreferencesServerSettingsStore implements ServerSettingsStore {
  static const key = 'brilliant.serverAddress';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String address) => _preferences.setString(key, address);
}

abstract interface class ServerProbe {
  Future<void> check(Uri address);
}

class HttpServerProbe implements ServerProbe {
  final HttpClient Function()? clientFactory;
  final Duration timeout;
  HttpServerProbe({
    this.clientFactory,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  Future<void> check(Uri address) async {
    final client = clientFactory?.call() ?? HttpClient();
    client.connectionTimeout = timeout;
    try {
      await (() async {
        final request = await client.getUrl(
          address.replace(path: '${address.path}/health/ready'),
        );
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        if (response.statusCode != 200) {
          throw const ServerConfigurationException(
            'El servidor no está listo o la dirección no corresponde a Brilliant.',
          );
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 8192) throw const FormatException();
        }
        final body = jsonDecode(utf8.decode(bytes));
        if (body is! Map || body['status'] != 'UP') {
          throw const ServerConfigurationException(
            'La dirección no devuelve una respuesta válida de Brilliant.',
          );
        }
      })().timeout(timeout);
    } on TimeoutException {
      throw const ServerConfigurationException(
        'El servidor no respondió. Comprueba que esté encendido y conectado a la misma red Wi-Fi.',
      );
    } on IOException {
      throw const ServerConfigurationException(
        'No se pudo conectar. Revisa la dirección, el puerto y la red Wi-Fi.',
      );
    } on FormatException {
      throw const ServerConfigurationException(
        'La dirección no devuelve una respuesta válida de Brilliant.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
