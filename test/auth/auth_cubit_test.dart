import 'dart:async';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';

class PendingRepository extends FakeAuthRepository {
  final pending = Completer<AuthSession>();
  int logins = 0;
  final deletion = Completer<void>();
  @override
  Future<AuthSession> login(String username, String password) {
    logins++;
    return pending.future;
  }

  @override
  Future<void> deleteAccount(String accessToken, String currentPassword) =>
      deletion.future;
}

AuthSession session() => AuthSession(
  user: const Account(id: 'id', username: 'Ana'),
  accessToken: 'token',
  expiresAt: DateTime.now().add(const Duration(minutes: 10)),
);

void main() {
  test('Registro y borrado confirmado publican y limpian identidad', () async {
    final repository = FakeAuthRepository();
    final auth = AuthCubit(repository);
    addTearDown(auth.close);
    await auth.authenticate('Ana', 'contraseña de prueba', register: true);
    expect(auth.state.session!.user.id, 'uuid-de-prueba');
    await auth.deleteAccount('contraseña de prueba');
    expect(repository.deletes, 1);
    expect(auth.state.session, isNull);
    expect(auth.state.error, 'Cuenta eliminada.');
  });

  for (final code in [
    'CURRENT_PASSWORD_INVALID',
    'NETWORK_ERROR',
    'SERVER_ERROR',
  ]) {
    test('Borrado con $code conserva sesión y no reintenta', () async {
      final repository = FakeAuthRepository();
      final auth = AuthCubit(repository);
      addTearDown(auth.close);
      await auth.authenticate('Ana', 'contraseña de prueba', register: false);
      repository.failure = AuthFailure(
        code,
        status: code == 'CURRENT_PASSWORD_INVALID' ? 403 : null,
      );
      await auth.deleteAccount('contraseña de prueba');
      expect(auth.state.session, isNotNull);
      expect(repository.deletes, 1);
      expect(auth.state.busy, isFalse);
      expect(
        auth.state.error,
        code == 'CURRENT_PASSWORD_INVALID'
            ? contains('incorrecta')
            : contains('No se pudo confirmar el borrado'),
      );
    });
  }

  test('401 protegido limpia la sesión sin afirmar borrado', () async {
    final repository = FakeAuthRepository();
    final auth = AuthCubit(repository);
    addTearDown(auth.close);
    await auth.authenticate('Ana', 'contraseña de prueba', register: false);
    repository.failure = const AuthFailure('SESSION_INVALID', status: 401);
    await auth.deleteAccount('contraseña de prueba');
    expect(auth.state.session, isNull);
    expect(auth.state.error, isNot(contains('eliminada')));
  });

  test('Doble envío y respuesta tardía no restauran identidad', () async {
    final repository = PendingRepository();
    final auth = AuthCubit(repository);
    addTearDown(auth.close);
    final login = auth.authenticate(
      'Ana',
      'contraseña de prueba',
      register: false,
    );
    await auth.authenticate('Ana', 'contraseña de prueba', register: false);
    expect(repository.logins, 1);
    auth.invalidate();
    repository.pending.complete(session());
    await login;
    expect(auth.state.session, isNull);
  });

  test('Borrado tardío después de caducar no publica éxito', () async {
    final repository = PendingRepository();
    final auth = AuthCubit(repository);
    addTearDown(auth.close);
    final login = auth.authenticate(
      'Ana',
      'contraseña de prueba',
      register: false,
    );
    repository.pending.complete(session());
    await login;
    final deletion = auth.deleteAccount('contraseña de prueba');
    auth.invalidate();
    repository.deletion.complete();
    await deletion;
    expect(auth.state.session, isNull);
    expect(auth.state.error, contains('sesión terminó'));
  });

  testWidgets('Respeta Retry-After y caducidad indicada por servidor', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..failure = const AuthFailure('RATE_LIMITED', status: 429, retryAfter: 2);
    final auth = AuthCubit(repository);
    await auth.authenticate('Ana', 'contraseña de prueba', register: false);
    expect(auth.state.cooldown, 2);
    repository.failure = null;
    await auth.authenticate('Ana', 'contraseña de prueba', register: false);
    expect(auth.state.session, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(auth.state.cooldown, 0);
    await auth.authenticate('Ana', 'contraseña de prueba', register: false);
    await tester.pump(const Duration(hours: 1));
    expect(auth.state.session, isNull);
    await auth.close();
  });
}
