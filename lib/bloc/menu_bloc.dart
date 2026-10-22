import 'dart:math';
import 'package:bloc/bloc.dart';
import '../catalogo/catalogo_tableros.dart';
import '../catalogo/definicion_tablero.dart';

sealed class MenuEvento {
  const MenuEvento();
}

final class NuevaPartidaSolicitada extends MenuEvento {
  const NuevaPartidaSolicitada();
}

final class NivelSeleccionado extends MenuEvento {
  final String tableroId;
  const NivelSeleccionado(this.tableroId);
}

final class NivelAleatorioSolicitado extends MenuEvento {
  const NivelAleatorioSolicitado();
}

final class SeleccionNivelCancelada extends MenuEvento {
  const SeleccionNivelCancelada();
}

final class NombreJugadorConfirmado extends MenuEvento {
  final String nombre;
  const NombreJugadorConfirmado(this.nombre);
}

final class CapturaNombreCancelada extends MenuEvento {
  const CapturaNombreCancelada();
}

enum FaseMenu {
  menuVisible,
  seleccionandoNivel,
  pidiendoNombre,
  creandoPartida,
  partidaPreparada,
}

class MenuEstado {
  static const longitudMaximaNombre = 16;
  final FaseMenu fase;
  final DefinicionTablero? tablero;
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
  final CatalogoTableros catalogo;
  final Random azar;
  List<DefinicionTablero> get niveles => List.unmodifiable(
    catalogo.definiciones.values.toList()..sort(
      (a, b) => (a.recursos?.numero ?? 0).compareTo(b.recursos?.numero ?? 0),
    ),
  );
  MenuBloc({CatalogoTableros? catalogo, Random? azar})
    : catalogo = catalogo ?? CatalogoTableros.predeterminado(),
      azar = azar ?? Random(),
      super(const MenuEstado()) {
    on<MenuEvento>((evento, emit) {
      MenuEstado estado(
        FaseMenu fase, {
        DefinicionTablero? tablero,
        String? jugador,
        int? solicitudId,
        String? error,
      }) => MenuEstado(
        fase: fase,
        tablero: tablero,
        jugador: jugador ?? state.jugador,
        solicitudId: solicitudId ?? state.solicitudId,
        error: error,
      );
      switch (evento) {
        case NuevaPartidaSolicitada():
          if (state.fase != FaseMenu.menuVisible &&
              state.fase != FaseMenu.partidaPreparada) {
            return;
          }
          if (niveles.isEmpty) {
            emit(
              estado(
                FaseMenu.menuVisible,
                error: 'No hay niveles disponibles.',
              ),
            );
          } else {
            emit(estado(FaseMenu.seleccionandoNivel));
          }
        case SeleccionNivelCancelada():
          if (state.fase != FaseMenu.seleccionandoNivel) return;
          emit(estado(FaseMenu.menuVisible));
        case NivelSeleccionado():
          if (state.fase != FaseMenu.seleccionandoNivel) return;
          try {
            emit(
              estado(
                FaseMenu.pidiendoNombre,
                tablero: this.catalogo.obtenerDefinicion(evento.tableroId),
              ),
            );
          } on ArgumentError {
            emit(
              estado(
                FaseMenu.seleccionandoNivel,
                error: 'Ese nivel no está disponible.',
              ),
            );
          }
        case NivelAleatorioSolicitado():
          if (state.fase != FaseMenu.seleccionandoNivel || niveles.isEmpty) {
            return;
          }
          emit(
            estado(
              FaseMenu.pidiendoNombre,
              tablero: niveles[this.azar.nextInt(niveles.length)],
            ),
          );
        case CapturaNombreCancelada():
          if (state.fase != FaseMenu.pidiendoNombre) return;
          emit(estado(FaseMenu.seleccionandoNivel, tablero: state.tablero));
        case NombreJugadorConfirmado():
          if (state.fase != FaseMenu.pidiendoNombre || state.tablero == null) {
            return;
          }
          final nombre = evento.nombre.trim();
          final error = nombre.isEmpty
              ? 'Escribe tu nombre para comenzar.'
              : nombre.length > MenuEstado.longitudMaximaNombre
              ? 'El nombre admite hasta 16 caracteres.'
              : null;
          if (error != null) {
            emit(
              estado(
                FaseMenu.pidiendoNombre,
                tablero: state.tablero,
                error: error,
              ),
            );
            return;
          }
          final tablero = state.tablero!;
          final id = state.solicitudId + 1;
          emit(
            estado(
              FaseMenu.creandoPartida,
              tablero: tablero,
              jugador: nombre,
              solicitudId: id,
            ),
          );
          emit(
            estado(
              FaseMenu.partidaPreparada,
              tablero: tablero,
              jugador: nombre,
              solicitudId: id,
            ),
          );
      }
    }, transformer: (eventos, mapper) => eventos.asyncExpand(mapper));
  }
}
