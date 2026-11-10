import 'dart:async';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';

class RefreshRepository extends FakeAuthRepository {
  int refreshes = 0;
  Completer<AuthSession>? pending;
  AuthFailure? refreshFailure;
  final tokensUsed = <String>[];
  AuthSession makeSession(String token) => AuthSession(
    user: const Account(id: 'id', username: 'Ana'),
    accessToken: token,
    refreshToken: 'refresh-$token',
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );
  @override
  Future<AuthSession> login(String username, String password) async =>
      makeSession('initial');
  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshes++;
    if (refreshFailure != null) throw refreshFailure!;
    return pending == null
        ? makeSession('renewed-$refreshes')
        : pending!.future;
  }

  @override
  Future<void> logout(String accessToken) async {
    tokensUsed.add(accessToken);
  }
}

void main() {
  testWidgets('Renueva a los nueve minutos y supera diez minutos de uso', (
    tester,
  ) async {
    final repository = RefreshRepository();
    final auth = AuthCubit(repository);
    await auth.authenticate('Ana', 'a!2', register: false);
    await tester.pump(const Duration(minutes: 9));
    expect(repository.refreshes, 1);
    expect(auth.state.session!.accessToken, 'renewed-1');
    await tester.pump(const Duration(minutes: 2));
    expect(auth.state.session, isNotNull);
    await auth.close();
  });
  test(
    'Rotaciones simultáneas comparten petición y logout espera el token nuevo',
    () async {
      final repository = RefreshRepository()
        ..pending = Completer<AuthSession>();
      final auth = AuthCubit(repository);
      addTearDown(auth.close);
      await auth.authenticate('Ana', 'a!2', register: false);
      final first = auth.renewSession();
      final second = auth.renewSession();
      final logout = auth.logout();
      expect(repository.refreshes, 1);
      expect(repository.tokensUsed, isEmpty);
      repository.pending!.complete(repository.makeSession('rotated'));
      await Future.wait([first, second, logout]);
      expect(repository.tokensUsed, ['rotated']);
      expect(auth.state.session, isNull);
    },
  );
  test(
    'Respuesta tardía de refresh no restaura una sesión invalidada',
    () async {
      final repository = RefreshRepository()
        ..pending = Completer<AuthSession>();
      final auth = AuthCubit(repository);
      addTearDown(auth.close);
      await auth.authenticate('Ana', 'a!2', register: false);
      final operation = auth.renewSession();
      auth.invalidate();
      repository.pending!.complete(repository.makeSession('late'));
      await operation;
      expect(auth.state.session, isNull);
    },
  );
  testWidgets('Refresh sin conexión sale al login y no reenvía el secreto', (
    tester,
  ) async {
    final repository = RefreshRepository()
      ..refreshFailure = const AuthFailure('NETWORK_ERROR');
    final auth = AuthCubit(repository);
    await auth.authenticate('Ana', 'a!2', register: false);
    await tester.pump(const Duration(minutes: 9));
    expect(repository.refreshes, 1);
    expect(auth.state.session, isNull);
    expect(auth.state.connectionLost, isTrue);
    await tester.pump(const Duration(minutes: 1));
    expect(repository.refreshes, 1);
    expect(auth.state.session, isNull);
    await auth.close();
  });
  testWidgets('429 respeta Retry-After incluso ante renovación manual', (
    tester,
  ) async {
    final repository = RefreshRepository()
      ..refreshFailure = const AuthFailure(
        'RATE_LIMITED',
        status: 429,
        retryAfter: 20,
      );
    final auth = AuthCubit(repository);
    await auth.authenticate('Ana', 'a!2', register: false);
    await auth.renewSession();
    await auth.renewSession();
    expect(repository.refreshes, 1);
    repository.refreshFailure = null;
    await tester.pump(const Duration(seconds: 19));
    expect(repository.refreshes, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.refreshes, 2);
    expect(auth.state.session!.accessToken, 'renewed-2');
    await auth.close();
  });
  test('Refresh revocado elimina sesión', () async {
    final repository = RefreshRepository()
      ..refreshFailure = const AuthFailure('SESSION_INVALID', status: 401);
    final auth = AuthCubit(repository);
    addTearDown(auth.close);
    await auth.authenticate('Ana', 'a!2', register: false);
    await auth.renewSession();
    expect(auth.state.session, isNull);
  });
}
