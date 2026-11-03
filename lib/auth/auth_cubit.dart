import 'dart:async';
import 'package:bloc/bloc.dart';
import 'auth_repository.dart';

class AuthState {
  final AuthSession? session;
  final bool busy;
  final String? error;
  final int cooldown;
  const AuthState({
    this.session,
    this.busy = false,
    this.error,
    this.cooldown = 0,
  });
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  Timer? _expiry;
  Timer? _cooldown;
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
      emit(AuthState(session: session));
    } on AuthFailure catch (error) {
      if (!isClosed && generation == _generation) _fail(error);
    }
  }

  Future<void> deleteAccount(String password) async {
    final session = state.session;
    if (session == null || state.busy || state.cooldown > 0) return;
    final generation = ++_generation;
    emit(AuthState(session: session, busy: true));
    try {
      await repository.deleteAccount(session.accessToken, password);
      if (isClosed || generation != _generation) return;
      _expiry?.cancel();
      ++_generation;
      emit(const AuthState(error: 'Cuenta eliminada.'));
    } on AuthFailure catch (error) {
      if (isClosed || generation != _generation) return;
      if (error.invalidSession || error.status == 401) {
        invalidate();
      } else {
        _fail(error, deletion: true);
      }
    }
  }

  void _fail(AuthFailure error, {bool deletion = false}) {
    final message =
        deletion &&
            (error.code == 'NETWORK_ERROR' || error.code == 'SERVER_ERROR')
        ? 'No se pudo confirmar el borrado. La cuenta podría haberse eliminado. No se reintentará automáticamente.'
        : error.message;
    emit(
      AuthState(
        session: state.session,
        error: message,
        cooldown: error.retryAfter,
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
          ),
        );
        if (remaining <= 0) timer.cancel();
      });
    }
  }

  /// Invalida también operaciones pendientes: una respuesta tardía no restaura
  /// una identidad después de la caducidad o de desmontar la aplicación.
  void invalidate() {
    ++_generation;
    _expiry?.cancel();
    _cooldown?.cancel();
    if (!isClosed) {
      emit(
        const AuthState(error: 'La sesión terminó. Inicia sesión de nuevo.'),
      );
    }
  }

  @override
  Future<void> close() {
    ++_generation;
    _expiry?.cancel();
    _cooldown?.cancel();
    return super.close();
  }
}
