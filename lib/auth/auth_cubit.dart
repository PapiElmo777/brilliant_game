import 'dart:async';
import 'package:bloc/bloc.dart';
import 'auth_repository.dart';

class AuthState {
  final AuthSession? session;
  final bool busy;
  final String? error;
  final int cooldown;
  final bool logoutUnconfirmed;
  const AuthState({
    this.session,
    this.busy = false,
    this.error,
    this.cooldown = 0,
    this.logoutUnconfirmed = false,
  });
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  Timer? _expiry;
  Timer? _cooldown;
  Timer? _presence;
  bool _checkingSession = false;
  int _generation = 0;
  AuthCubit(this.repository) : super(const AuthState());

  void clearError() {
    if (!state.busy) {
      emit(AuthState(session: state.session, cooldown: state.cooldown));
    }
  }

  Future<void> authenticate(
    String username,
    String password, {
    required bool register,
  }) async {
    if (state.busy || state.cooldown > 0 || state.session != null) return;
    final generation = ++_generation;
    emit(const AuthState(busy: true));
    try {
      final session = await (register
          ? repository.register(username, password)
          : repository.login(username, password));
      if (isClosed || generation != _generation) return;
      final remaining = session.expiresAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        invalidate();
        return;
      }
      _expiry = Timer(remaining, invalidate);
      _presence?.cancel();
      _presence = Timer.periodic(
        const Duration(seconds: 10),
        (_) => checkSession(),
      );
      emit(AuthState(session: session));
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) {
        // Login/register are public: a 401 here cannot expire a local session
        // that has not been established. Keep the form available to retry.
        _fail(
          error.status == 401 && error.code != 'INVALID_CREDENTIALS'
              ? const AuthFailure('AUTH_ENDPOINT_REJECTED', status: 401)
              : error,
        );
      }
    }
  }

  /// A 401 from the authenticated probe clears every protected route. Network
  /// errors do not claim the server closed a session; the next probe retries.
  Future<void> checkSession() async {
    final session = state.session;
    if (session == null || state.busy || _checkingSession || isClosed) return;
    final generation = _generation;
    _checkingSession = true;
    try {
      await repository.checkSession(session.accessToken);
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation && error.status == 401) {
        invalidate();
      }
    } finally {
      _checkingSession = false;
    }
  }

  Future<void> logout() async {
    final session = state.session;
    if (session == null || state.busy || state.cooldown > 0) return;
    final generation = ++_generation;
    emit(
      AuthState(
        session: session,
        busy: true,
        error: state.error,
        logoutUnconfirmed: state.logoutUnconfirmed,
      ),
    );
    try {
      await repository.logout(session.accessToken);
      if (isClosed || generation != _generation) return;
      _clearSession('Sesión cerrada.');
    } on AuthFailure catch (error) {
      if (isClosed || generation != _generation) return;
      if (error.status == 401) {
        invalidate();
      } else {
        _fail(error, logout: true);
      }
    }
  }

  void logoutLocally() {
    if (state.session == null || !state.logoutUnconfirmed) return;
    _clearSession(
      'Saliste de este dispositivo. No se pudo confirmar el cierre de sesión en el servidor.',
    );
  }

  void _clearSession(String message) {
    ++_generation;
    _expiry?.cancel();
    _cooldown?.cancel();
    _presence?.cancel();
    if (!isClosed) emit(AuthState(error: message));
  }

  Future<void> deleteAccount(String password) async {
    final session = state.session;
    if (session == null || state.busy || state.cooldown > 0) return;
    final generation = ++_generation;
    emit(AuthState(session: session, busy: true));
    try {
      await repository.deleteAccount(session.accessToken, password);
      if (isClosed || generation != _generation) return;
      _clearSession('Cuenta eliminada.');
    } on AuthFailure catch (error) {
      if (isClosed || generation != _generation) return;
      if (error.invalidSession || error.status == 401) {
        invalidate();
      } else {
        _fail(error, deletion: true);
      }
    }
  }

  void _fail(AuthFailure error, {bool deletion = false, bool logout = false}) {
    final message = logout
        ? 'No se pudo confirmar el cierre de sesión en el servidor. Puedes reintentar o salir solo de este dispositivo.'
        : deletion &&
              (error.code == 'NETWORK_ERROR' || error.code == 'SERVER_ERROR')
        ? 'No se pudo confirmar el borrado. La cuenta podría haberse eliminado. No se reintentará automáticamente.'
        : error.message;
    emit(
      AuthState(
        session: state.session,
        error: message,
        cooldown: error.retryAfter,
        logoutUnconfirmed: logout,
      ),
    );
    _cooldown?.cancel();
    if (state.cooldown > 0) {
      _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isClosed) return timer.cancel();
        final remaining = state.cooldown - 1;
        emit(
          AuthState(
            session: state.session,
            error: state.error,
            cooldown: remaining,
            logoutUnconfirmed: state.logoutUnconfirmed,
          ),
        );
        if (remaining <= 0) timer.cancel();
      });
    }
  }

  /// Invalida también operaciones pendientes: una respuesta tardía no restaura
  /// una identidad después de la caducidad o de desmontar la aplicación.
  void invalidate() =>
      _clearSession('La sesión terminó. Inicia sesión de nuevo.');

  @override
  Future<void> close() {
    ++_generation;
    _expiry?.cancel();
    _cooldown?.cancel();
    _presence?.cancel();
    return super.close();
  }
}
