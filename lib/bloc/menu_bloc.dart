import 'package:bloc/bloc.dart';

import '../catalogo/catalogo_tableros.dart';
import '../catalogo/definicion_tablero.dart';

sealed class MenuEvento {
  const MenuEvento();
}

/// Abre la captura del nombre del jugador.
final class NuevaPartidaSolicitada extends MenuEvento {
  const NuevaPartidaSolicitada();
}

/// Confirma el nombre y prepara la partida con el primer tablero.
final class NombreJugadorConfirmado extends MenuEvento {
  final String nombre;
  const NombreJugadorConfirmado(this.nombre);
}

final class CapturaNombreCancelada extends MenuEvento {
  const CapturaNombreCancelada();
}

enum FaseMenu { menuVisible, pidiendoNombre, creandoPartida, partidaPreparada }

class MenuEstado {
  static const longitudMaximaNombre = 16;

  final FaseMenu fase;
  final DefinicionTablero? tablero;

  /// Último nombre aceptado; se propone al solicitar otra partida.
  final String? jugador;
  final int solicitudId;
  final String? error;

  const MenuEstado({
    this.fase = FaseMenu.menuVisible,
    this.tablero,
    this.jugador,
    this.solicitudId = 0,
    this.error,
  });
}

class MenuBloc extends Bloc<MenuEvento, MenuEstado> {
  MenuBloc({CatalogoTableros? catalogo}) : super(const MenuEstado()) {
    final tableros = catalogo ?? CatalogoTableros.predeterminado();
    on<MenuEvento>((evento, emit) {
      switch (evento) {
        case NuevaPartidaSolicitada():
          if (state.fase == FaseMenu.pidiendoNombre ||
              state.fase == FaseMenu.creandoPartida) {
            return;
          }
          emit(
            MenuEstado(
              fase: FaseMenu.pidiendoNombre,
              jugador: state.jugador,
              solicitudId: state.solicitudId,
            ),
          );
        case CapturaNombreCancelada():
          if (state.fase != FaseMenu.pidiendoNombre) return;
          emit(
            MenuEstado(jugador: state.jugador, solicitudId: state.solicitudId),
          );
        case NombreJugadorConfirmado():
          if (state.fase != FaseMenu.pidiendoNombre) return;
          final nombre = evento.nombre.trim();
          final error = nombre.isEmpty
              ? 'Escribe tu nombre para comenzar.'
              : nombre.length > MenuEstado.longitudMaximaNombre
              ? 'El nombre admite hasta '
                    '${MenuEstado.longitudMaximaNombre} caracteres.'
              : null;
          if (error != null) {
            emit(
              MenuEstado(
                fase: FaseMenu.pidiendoNombre,
                jugador: state.jugador,
                solicitudId: state.solicitudId,
                error: error,
              ),
            );
            return;
          }
          final solicitudId = state.solicitudId + 1;
          emit(
            MenuEstado(
              fase: FaseMenu.creandoPartida,
              jugador: nombre,
              solicitudId: solicitudId,
            ),
          );
          try {
            emit(
              MenuEstado(
                fase: FaseMenu.partidaPreparada,
                tablero: tableros.obtenerDefinicion('tablero_01'),
                jugador: nombre,
                solicitudId: solicitudId,
              ),
            );
          } on ArgumentError catch (error) {
            emit(
              MenuEstado(
                jugador: nombre,
                solicitudId: solicitudId,
                error: error.message.toString(),
              ),
            );
          }
      }
    }, transformer: (eventos, mapper) => eventos.asyncExpand(mapper));
  }
}
