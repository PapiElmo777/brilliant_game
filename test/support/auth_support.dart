import 'dart:math';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  final String name;
  AuthFailure? failure;
  int deletes = 0;
  int logouts = 0;
  FakeAuthRepository({this.name = 'Ana'});
  @override
  Future<AuthSession> login(String username, String password) async {
    if (failure != null) throw failure!;
    return AuthSession(
      user: Account(id: 'uuid-de-prueba', username: name),
      accessToken: 'token-de-prueba',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<AuthSession> register(String username, String password) =>
      login(username, password);
  @override
  Future<void> logout(String accessToken) async {
    logouts++;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> deleteAccount(String accessToken, String currentPassword) async {
    deletes++;
    if (failure != null) throw failure!;
  }

  @override
  void close() {}
}

Future<void> iniciarApp(
  WidgetTester tester, {
  Random? azarPartida,
  AuthRepository? repository,
}) async {
  await tester.pumpWidget(
    BrilliantGameApp(
      azarPartida: azarPartida,
      authRepository: repository ?? FakeAuthRepository(),
    ),
  );
  addTearDown(() async => tester.pumpWidget(const SizedBox()));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('auth_username')), 'Ana');
  await tester.enterText(
    find.byKey(const ValueKey('auth_password')),
    'clave de pruebas segura',
  );
  final button = find.byKey(const ValueKey('auth_submit'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
