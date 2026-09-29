import 'package:bloc/bloc.dart';

import '../catalogo/catalogo_tableros.dart';
import '../catalogo/definicion_tablero.dart';

final class NuevaPartidaSolicitada {
  const NuevaPartidaSolicitada();
}

enum FaseMenu { menuVisible, creandoPartida, partidaPreparada }

class MenuEstado {
  final FaseMenu fase;
  final DefinicionTablero? tablero;
  final int solicitudId;
  final String? error;

  const MenuEstado({
    this.fase = FaseMenu.menuVisible,
    this.tablero,
    this.solicitudId = 0,
    this.error,
  });
}

class MenuBloc extends Bloc<NuevaPartidaSolicitada, MenuEstado> {
  MenuBloc({CatalogoTableros? catalogo}) : super(const MenuEstado()) {
    final tableros = catalogo ?? CatalogoTableros.predeterminado();
    on<NuevaPartidaSolicitada>((evento, emit) {
      final solicitudId = state.solicitudId + 1;
      emit(MenuEstado(fase: FaseMenu.creandoPartida, solicitudId: solicitudId));
      try {
        final tablero = tableros.obtenerDefinicion('tablero_01');
        emit(
          MenuEstado(
            fase: FaseMenu.partidaPreparada,
            tablero: tablero,
            solicitudId: solicitudId,
          ),
        );
      } on ArgumentError catch (error) {
        emit(
          MenuEstado(solicitudId: solicitudId, error: error.message.toString()),
        );
      }
    }, transformer: (eventos, mapper) => eventos.asyncExpand(mapper));
  }
}
