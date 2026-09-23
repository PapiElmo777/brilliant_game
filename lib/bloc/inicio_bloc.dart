import 'package:bloc/bloc.dart';

import '../core/preparacion_inicial.dart';
import '../core/tablero.dart';
import 'inicio_estado.dart';
import 'inicio_evento.dart';

/// Controla exclusivamente la preparación y la transición de inicio.
class InicioBloc extends Bloc<InicioEvento, InicioEstado> {
  final PreparacionInicial _preparacion;

  factory InicioBloc(Tablero tablero) =>
      InicioBloc._(PreparacionInicial(tablero));

  InicioBloc._(this._preparacion) : super(_estado(_preparacion)) {
    // Una única cola preserva el orden entre colocar, retirar y solicitar inicio.
    on<InicioEvento>(
      _procesar,
      transformer: (eventos, mapper) => eventos.asyncExpand(mapper),
    );
  }

  void _procesar(InicioEvento evento, Emitter<InicioEstado> emit) {
    if (state.fase == FaseInicio.iniciado) {
      emit(
        _estado(
          _preparacion,
          iniciado: true,
          error: 'La partida ya fue iniciada.',
        ),
      );
      return;
    }
    try {
      switch (evento) {
        case ValorInicialColocado():
          _preparacion.colocarValor(evento.celdaId, evento.valor);
        case ValorInicialRetirado():
          _preparacion.vaciarCelda(evento.celdaId);
        case InicioSolicitado():
          if (!_preparacion.estaLista) {
            throw StateError(
              'Debes colocar los números del 1 al 6 antes de iniciar.',
            );
          }
          emit(_estado(_preparacion, iniciado: true));
          return;
      }
      emit(_estado(_preparacion));
    } on ArgumentError catch (error) {
      emit(_estado(_preparacion, error: error.message.toString()));
    } on StateError catch (error) {
      emit(_estado(_preparacion, error: error.message));
    }
  }

  /// Permite entregar el tablero al controlador del juego solo tras iniciar.
  Tablero crearTableroParaJuego() {
    if (state.fase != FaseInicio.iniciado) {
      throw StateError('Primero debes solicitar el inicio de la partida.');
    }
    return _preparacion.crearTableroParaJuego();
  }

  static InicioEstado _estado(
    PreparacionInicial preparacion, {
    bool iniciado = false,
    String? error,
  }) => InicioEstado(
    fase: iniciado
        ? FaseInicio.iniciado
        : preparacion.estaLista
        ? FaseInicio.listo
        : FaseInicio.preparando,
    celdas: preparacion.celdas,
    numerosFaltantes: preparacion.numerosFaltantes,
    error: error,
  );
}
