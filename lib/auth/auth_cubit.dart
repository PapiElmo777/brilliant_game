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
  Timer? _renewal;
  Future<void>? _refreshing;
  String? _uncertainRefreshToken;
  DateTime? _refreshNotBefore;
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
      _scheduleSession(session);
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

  void _scheduleSession(AuthSession session) {
    _expiry?.cancel();
    _renewal?.cancel();
    final remaining = session.expiresAt.difference(DateTime.now());
    _expiry = Timer(remaining, invalidate);
    if (session.refreshToken != null) {
      final delay = remaining - const Duration(seconds: 60);
      _renewal = Timer(delay.isNegative ? Duration.zero : delay, renewSession);
    }
  }

  /// Una única rotación; un reintento de un refresh ya consumido revoca la sesión.
  Future<void> renewSession() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final session = state.session;
    if (isClosed ||
        session?.refreshToken == null ||
        session!.refreshToken == _uncertainRefreshToken) {
      return Future.value();
    }
    if (_refreshNotBefore?.isAfter(DateTime.now()) == true) {
      return Future.value();
    }
    _renewal?.cancel();
    if (state.busy) {
      _renewal = Timer(const Duration(seconds: 10), renewSession);
      return Future.value();
    }
    final generation = _generation;
    final operation = _renew(session, generation);
    _refreshing = operation;
    return operation.whenComplete(() {
      if (identical(_refreshing, operation)) _refreshing = null;
    });
  }

  Future<void> _renew(AuthSession session, int generation) async {
    try {
      final renewed = await repository.refresh(session.refreshToken!);
      if (isClosed || generation != _generation) return;
      if (renewed.user.id != session.user.id ||
          !renewed.expiresAt.isAfter(DateTime.now())) {
        invalidate();
        return;
      }
      _uncertainRefreshToken = null;
      _refreshNotBefore = null;
      _scheduleSession(renewed);
      emit(
        AuthState(
          session: renewed,
          error: state.error,
          cooldown: state.cooldown,
          logoutUnconfirmed: state.logoutUnconfirmed,
        ),
      );
    } on AuthFailure catch (error) {
      if (isClosed || generation != _generation) return;
      if (error.status == 401 || error.status == 403) {
        invalidate();
      } else if (error.status == 429) {
        final delay = Duration(
          seconds: error.retryAfter > 0 ? error.retryAfter : 10,
        );
        _refreshNotBefore = DateTime.now().add(delay);
        _renewal = Timer(delay, () {
          _refreshNotBefore = null;
          renewSession();
        });
      } else {
        _uncertainRefreshToken = session.refreshToken;
      }
      // Red/5xx: resultado incierto de rotación. No reenviar el secreto;
      // mantener el acceso actual hasta su caducidad o un 401 de presencia.
    }
  }

  /// A 401 from the authenticated probe clears every protected route. Network
  /// errors do not claim the server closed a session; the next probe retries.
  Future<void> checkSession() async {
    var session = state.session;
    if (session == null || state.busy || _checkingSession || isClosed) return;
    if (!session.expiresAt.isAfter(DateTime.now())) {
      invalidate();
      return;
    }
    if (session.expiresAt.difference(DateTime.now()) <=
        const Duration(seconds: 60)) {
      await renewSession();
      session = state.session;
      if (session == null || isClosed || state.busy) return;
    }
    final generation = _generation;
    _checkingSession = true;
    try {
      await repository.checkSession(session.accessToken);
    } on AuthFailure catch (error) {
      if (!isClosed &&
          generation == _generation &&
          error.status == 401 &&
          state.session?.accessToken == session.accessToken) {
        invalidate();
      }
    } finally {
      _checkingSession = false;
    }
  }

  Future<void> logout() async {
    await _refreshing;
    final session = state.session;
    if (isClosed || session == null || state.busy || state.cooldown > 0) return;
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
    _uncertainRefreshToken = null;
    _refreshNotBefore = null;
    _expiry?.cancel();
    _renewal?.cancel();
    _cooldown?.cancel();
    _presence?.cancel();
    if (!isClosed) emit(AuthState(error: message));
  }

  Future<void> deleteAccount(String password) async {
    await _refreshing;
    final session = state.session;
    if (isClosed || session == null || state.busy || state.cooldown > 0) return;
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
    _uncertainRefreshToken = null;
    _refreshNotBefore = null;
    _expiry?.cancel();
    _renewal?.cancel();
    _cooldown?.cancel();
    _presence?.cancel();
    return super.close();
  }
}
