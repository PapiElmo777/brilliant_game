import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_repository.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  final String server;
  final FlutterSecureStorage storage;
  const SecureSessionStore(
    this.server, {
    this.storage = const FlutterSecureStorage(),
  });
  String get _key => 'brilliant.session.${Uri.encodeComponent(server)}';
  @override
  Future<String?> read() => storage.read(key: _key);
  @override
  Future<void> write(String value) => storage.write(key: _key, value: value);
  @override
  Future<void> clear() => storage.delete(key: _key);
}

String encodeSession(AuthSession session, DateTime savedAt) => jsonEncode({
  'savedAt': savedAt.toIso8601String(),
  'user': {
    'id': session.user.id,
    'username': session.user.username,
    'avatarId': session.user.avatarId,
  },
  'accessToken': session.accessToken,
  'refreshToken': session.refreshToken,
  'expiresAt': session.expiresAt.toIso8601String(),
});

(AuthSession, DateTime) decodeSession(String raw) {
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return (
    AuthSession(
      user: Account.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String?,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    ),
    DateTime.parse(data['savedAt'] as String),
  );
}
