import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class Account {
  final String id;
  final String username;
  const Account({required this.id, required this.username});

  factory Account.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    if (id is! String ||
        id.isEmpty ||
        username is! String ||
        username.isEmpty) {
      throw const FormatException('Cuenta inválida');
    }
    return Account(id: id, username: username);
  }
}

class AuthSession {
  final Account user;
  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });
}

class AuthFailure implements Exception {
  final String code;
  final int? status;
  final int retryAfter;
  const AuthFailure(this.code, {this.status, this.retryAfter = 0});

  bool get invalidSession => status == 401 && code != 'INVALID_CREDENTIALS';
  String get message => switch (code) {
    'INVALID_CREDENTIALS' => 'Usuario o contraseña incorrectos.',
    'AUTH_ENDPOINT_REJECTED' =>
      'El servidor rechazó la solicitud de acceso. Inténtalo de nuevo.',
    'CURRENT_PASSWORD_INVALID' => 'La contraseña actual es incorrecta.',
    'USERNAME_UNAVAILABLE' => 'Ese nombre de usuario ya está ocupado.',
    'SESSION_ALREADY_ACTIVE' =>
      'La cuenta ya tiene una sesión abierta en otro dispositivo. Cierra esa sesión o espera 45 segundos si la app se cerró.',
    'VALIDATION_ERROR' =>
      'Revisa los datos. Para crear cuenta, usa de 3 a 128 caracteres, al menos uno especial, y evita contraseñas comunes.',
    'RATE_LIMITED' =>
      'Demasiados intentos. Espera antes de volver a intentarlo.',
    'NETWORK_ERROR' =>
      'No se pudo confirmar la respuesta del servidor. Revisa tu conexión.',
    'ACCESS_TOKEN_EXPIRED' ||
    'SESSION_INVALID' ||
    'UNAUTHORIZED' => 'La sesión terminó. Inicia sesión de nuevo.',
    'CONFIGURATION_ERROR' =>
      'La dirección del servidor no está configurada correctamente.',
    _ => 'El servidor no pudo completar la operación. Inténtalo más tarde.',
  };
}

abstract interface class AuthRepository {
  Future<AuthSession> register(String username, String password);
  Future<AuthSession> login(String username, String password);
  Future<AuthSession> refresh(String refreshToken);
  Future<void> logout(String accessToken);
  Future<void> checkSession(String accessToken);
  Future<void> deleteAccount(String accessToken, String currentPassword);
  void close();
}

/// Solo habla con el origen configurado. No sigue redirecciones, no reintenta
/// mutaciones y nunca guarda ni registra cuerpos ni credenciales. Access y refresh viven solo en memoria.
class HttpAuthRepository implements AuthRepository {
  final Uri baseUrl;
  final HttpClient _client;
  final Duration timeout;

  static Uri get configuredBaseUrl =>
      Uri.tryParse(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:8080/api/v1',
        ),
      ) ??
      Uri();

  HttpAuthRepository({
    Uri? baseUrl,
    HttpClient? client,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = baseUrl ?? configuredBaseUrl,
       _client = client ?? HttpClient();

  bool get _validUrl =>
      baseUrl.hasAuthority &&
      baseUrl.host.isNotEmpty &&
      baseUrl.userInfo.isEmpty &&
      !baseUrl.hasQuery &&
      !baseUrl.hasFragment &&
      baseUrl.path.replaceFirst(RegExp(r'/+$'), '').endsWith('/api/v1') &&
      (baseUrl.scheme == 'https' || (kDebugMode && baseUrl.scheme == 'http'));

  Future<Map<String, dynamic>?> _send(
    String method,
    String path,
    int expected, {
    Map<String, String>? body,
    String? token,
  }) async {
    if (!_validUrl) throw const AuthFailure('CONFIGURATION_ERROR');
    HttpClientRequest? request;
    int? status;
    var timedOut = false;
    try {
      return await (() async {
        final uri = baseUrl.replace(
          path: '${baseUrl.path.replaceFirst(RegExp(r'/+$'), '')}/$path',
        );
        request = await _client.openUrl(method, uri);
        if (timedOut) {
          request!.abort();
          throw const AuthFailure('NETWORK_ERROR');
        }
        request!.followRedirects = false;
        request!.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (token != null) {
          request!.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $token',
          );
        }
        if (body != null) {
          request!.headers.contentType = ContentType.json;
          request!.add(utf8.encode(jsonEncode(body)));
        }
        final response = await request!.close();
        status = response.statusCode;
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 65536) {
            throw const FormatException('Respuesta demasiado grande');
          }
        }
        Map<String, dynamic>? json;
        if (bytes.isNotEmpty) {
          final decoded = jsonDecode(utf8.decode(bytes));
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('JSON inválido');
          }
          json = decoded;
        }
        if (response.statusCode != expected) {
          final error = json?['error'];
          throw AuthFailure(
            error is Map && error['code'] is String
                ? error['code'] as String
                : 'SERVER_ERROR',
            status: response.statusCode,
            retryAfter:
                (int.tryParse(response.headers.value('retry-after') ?? '') ?? 0)
                    .clamp(0, 86400),
          );
        }
        return json;
      })().timeout(timeout);
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      timedOut = true;
      request?.abort();
      throw const AuthFailure('NETWORK_ERROR');
    } on IOException {
      throw AuthFailure('NETWORK_ERROR', status: status);
    } on FormatException {
      throw AuthFailure('SERVER_ERROR', status: status);
    }
  }

  Future<AuthSession> _authenticate(
    String path,
    int status,
    String username,
    String password,
  ) async {
    final json = await _send(
      'POST',
      path,
      status,
      body: {'username': username.trim(), 'password': password},
    );
    return _session(json);
  }

  AuthSession _session(Map<String, dynamic>? json) {
    if (json == null ||
        json['user'] is! Map<String, dynamic> ||
        json['accessToken'] is! String ||
        (json['accessToken'] as String).isEmpty ||
        json['tokenType'] != 'Bearer' ||
        json['refreshToken'] is! String ||
        (json['refreshToken'] as String).isEmpty ||
        json['expiresIn'] is! int ||
        (json['expiresIn'] as int) <= 0) {
      throw const AuthFailure('SERVER_ERROR');
    }
    try {
      return AuthSession(
        user: Account.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.now().add(
          Duration(seconds: json['expiresIn'] as int),
        ),
      );
    } on FormatException {
      throw const AuthFailure('SERVER_ERROR');
    }
  }

  @override
  Future<AuthSession> register(String username, String password) =>
      _authenticate('auth/register', 201, username, password);
  @override
  Future<AuthSession> login(String username, String password) =>
      _authenticate('auth/login', 200, username, password);
  @override
  Future<AuthSession> refresh(String refreshToken) async => _session(
    await _send(
      'POST',
      'auth/refresh',
      200,
      body: {'refreshToken': refreshToken},
    ),
  );

  @override
  Future<void> logout(String accessToken) async {
    await _send('POST', 'auth/logout', 204, token: accessToken);
  }

  @override
  Future<void> checkSession(String accessToken) async {
    await _send('GET', 'users/me', 200, token: accessToken);
  }

  @override
  Future<void> deleteAccount(String accessToken, String currentPassword) async {
    await _send(
      'DELETE',
      'users/me',
      204,
      body: {'currentPassword': currentPassword},
      token: accessToken,
    );
  }

  @override
  void close() => _client.close(force: true);
}
