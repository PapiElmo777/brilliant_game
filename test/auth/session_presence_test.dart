import 'dart:async';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';

class PendingSessionRepository extends FakeAuthRepository {
  final pending = Completer<void>();
  @override
  Future<void> checkSession(String accessToken) {
    sessionChecks++;
    return pending.future;
  }
}

void main() {
  test(
    '409 conserva el acceso anterior y permite reintentar en el nuevo cliente',
    () async {
      final repository = FakeAuthRepository()
        ..failure = const AuthFailure('SESSION_ALREADY_ACTIVE', status: 409);
      final auth = AuthCubit(repository);
      addTearDown(auth.close);
      await auth.authenticate('Ana', 'a!2', register: false);
      expect(auth.state.session, isNull);
      expect(auth.state.error, contains('ya tiene una sesión abierta'));
      expect(auth.state.busy, isFalse);
      repository.failure = null;
      await auth.authenticate('Ana', 'a!2', register: false);
      expect(auth.state.session, isNotNull);
    },
  );

  testWidgets('Mantiene actividad cada 10 segundos y limpia rutas tras 401', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await iniciarApp(tester, repository: repository);
    await tester.pump(const Duration(seconds: 10));
    expect(repository.sessionChecks, 1);
    expect(find.text('UN JUGADOR'), findsOneWidget);
    repository.sessionFailure = const AuthFailure(
      'SESSION_INVALID',
      status: 401,
    );
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('UN JUGADOR'), findsNothing);
    expect(
      find.text('La sesión terminó. Inicia sesión de nuevo.'),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('UN JUGADOR'), findsNothing);
  });

  testWidgets('Comprueba la sesión al volver a primer plano', (tester) async {
    final repository = FakeAuthRepository();
    await iniciarApp(tester, repository: repository);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.sessionChecks, 1);
    expect(find.byType(BrilliantGameApp), findsOneWidget);
  });

  test('Un fallo de red no afirma que se cerró la sesión', () async {
    final repository = FakeAuthRepository()
      ..sessionFailure = const AuthFailure('NETWORK_ERROR');
    final auth = AuthCubit(repository);
    addTearDown(auth.close);
    await auth.authenticate('Ana', 'a!2', register: false);
    await auth.checkSession();
    expect(auth.state.session, isNotNull);
    expect(auth.state.error, isNull);
  });

  test(
    'No solapa comprobaciones ni aplica un 401 antiguo a otra sesión',
    () async {
      final repository = PendingSessionRepository();
      final auth = AuthCubit(repository);
      addTearDown(auth.close);
      await auth.authenticate('Ana', 'a!2', register: false);
      final checking = auth.checkSession();
      await auth.checkSession();
      expect(repository.sessionChecks, 1);
      await auth.logout();
      await auth.authenticate('Ana', 'a!2', register: false);
      repository.pending.completeError(
        const AuthFailure('SESSION_INVALID', status: 401),
      );
      await checking;
      expect(auth.state.session, isNotNull);
    },
  );
}
