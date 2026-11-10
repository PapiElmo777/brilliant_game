import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';

class MemorySessionStore implements SessionStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  test('Reabrir antes de diez minutos recupera la sesión y logout la borra', () async {
    final repo = FakeAuthRepository();
    final store = MemorySessionStore();
    final first = AuthCubit(repo, sessionStore: store);
    await first.restoreSession();
    await first.authenticate('Ana', 'a!2', register: false);
    await first.suspendSession();
    await first.close();
    expect(store.value, isNotNull);
    final reopened = AuthCubit(repo, sessionStore: store);
    addTearDown(reopened.close);
    await reopened.restoreSession();
    expect(reopened.state.session?.user.username, 'Ana');
    await reopened.logout();
    await reopened.suspendSession();
    expect(store.value, isNull);
  });

  test('A los diez minutos no recupera credenciales ni accede al servidor', () async {
    final repo = FakeAuthRepository();
    final store = MemorySessionStore();
    final source = AuthCubit(repo);
    await source.authenticate('Ana', 'a!2', register: false);
    store.value = encodeSession(source.state.session!, DateTime.now().subtract(const Duration(minutes: 10)));
    await source.close();
    final restored = AuthCubit(repo, sessionStore: store);
    addTearDown(restored.close);
    await restored.restoreSession();
    await restored.suspendSession();
    expect(restored.state.session, isNull);
    expect(store.value, isNull);
    expect(repo.sessionChecks, 0);
  });
}
