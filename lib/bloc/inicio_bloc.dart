import 'package:bloc/bloc.dart';

import '../core/preparacion_inicial.dart';
import '../core/tablero.dart';
import 'inicio_estado.dart';
import 'inicio_evento.dart';

class InicioBloc extends Bloc<InicioEvento, InicioEstado> {
  final PreparacionInicial _preparacion;
  int _ultimoDisparoId = 0;

  factory InicioBloc(Tablero tablero, {bool animarEntrada = false}) =>
      InicioBloc._(PreparacionInicial(tablero), animarEntrada);

  InicioBloc._(this._preparacion, bool animarEntrada)
    : super(_estado(
        _preparacion,
        faseVisual: animarEntrada ? FaseVisualInicio.llegandoNave : null,
      )) {
    // Una única cola preserva el orden entre acciones y confirmaciones visuales.
    on<InicioEvento>(
      _procesar,
      transformer: (eventos, mapper) => eventos.asyncExpand(mapper),
    );
  }

  void _procesar(InicioEvento evento, Emitter<InicioEstado> emit) {
    if (evento is LlegadaNaveCompletada) {
      if (state.faseVisual == FaseVisualInicio.llegandoNave) {
        emit(_estado(_preparacion, faseVisual: FaseVisualInicio.mostrandoNumeros));
      }
      return;
    }
    if (evento is PresentacionNumerosCompletada) {
      if (state.faseVisual == FaseVisualInicio.mostrandoNumeros) {
        emit(_estado(_preparacion));
      }
      return;
    }
    if (evento is DisparoNumeroCompletado) {
      final disparo = state.disparoPendiente;
      if (disparo == null || disparo.id != evento.disparoId) return;
      _preparacion.colocarValor(disparo.celdaId, disparo.numero);
      emit(_estado(_preparacion));
      return;
    }
    if (state.fase == FaseInicio.iniciado) {
      emit(_estado(_preparacion, iniciado: true, error: 'La partida ya fue iniciada.'));
      return;
    }
    if (state.interaccionBloqueada) return;

    try {
      switch (evento) {
        case ValorInicialColocado():
          _preparacion.colocarValor(evento.celdaId, evento.valor);
        case ValorInicialRetirado():
          _preparacion.vaciarCelda(evento.celdaId);
        case NumeroInicialSeleccionado():
          if (!state.numerosFaltantes.contains(evento.valor)) {
            throw ArgumentError('Selecciona un número disponible del 1 al 6.');
          }
          emit(_estado(_preparacion, numeroSeleccionado: evento.valor));
          return;
        case CeldaInicialSeleccionada():
          final celda = state.celdas[evento.celdaId];
          if (celda == null || !celda.esInicio) {
            throw ArgumentError('Selecciona una celda inicial del tablero.');
          }
          if (celda.estaOcupada) {
            _preparacion.vaciarCelda(celda.id);
          } else {
            final numero = state.numeroSeleccionado;
            if (numero == null) {
              throw StateError('Selecciona primero un número disponible.');
            }
            _preparacion.validarColocacion(celda.id, numero);
            emit(_estado(
              _preparacion,
              faseVisual: FaseVisualInicio.disparando,
              numeroSeleccionado: numero,
              disparoPendiente: DisparoPendiente(
                id: ++_ultimoDisparoId,
                numero: numero,
                celdaId: celda.id,
              ),
            ));
            return;
          }
        case SeleccionCancelada():
          break;
        case InicioSolicitado():
          if (!_preparacion.estaLista) {
            throw StateError('Debes colocar los números del 1 al 6 antes de iniciar.');
          }
          emit(_estado(_preparacion, iniciado: true));
          return;
        case LlegadaNaveCompletada():
        case PresentacionNumerosCompletada():
        case DisparoNumeroCompletado():
          return;
      }
      emit(_estado(_preparacion));
    } on ArgumentError catch (error) {
      emit(_estado(_preparacion,
        numeroSeleccionado: state.numeroSeleccionado,
        error: error.message.toString(),
      ));
    } on StateError catch (error) {
      emit(_estado(_preparacion,
        numeroSeleccionado: state.numeroSeleccionado,
        error: error.message,
      ));
    }
  }

  Tablero crearTableroParaJuego() {
    if (state.fase != FaseInicio.iniciado) {
      throw StateError('Primero debes solicitar el inicio de la partida.');
    }
    return _preparacion.crearTableroParaJuego();
  }

  static InicioEstado _estado(
    PreparacionInicial preparacion, {
    bool iniciado = false,
    FaseVisualInicio? faseVisual,
    int? numeroSeleccionado,
    DisparoPendiente? disparoPendiente,
    String? error,
  }) => InicioEstado(
    fase: iniciado
        ? FaseInicio.iniciado
        : preparacion.estaLista
        ? FaseInicio.listo
        : FaseInicio.preparando,
    faseVisual: faseVisual,
    numeroSeleccionado: numeroSeleccionado,
    disparoPendiente: disparoPendiente,
    celdas: preparacion.celdas,
    numerosFaltantes: preparacion.numerosFaltantes,
    error: error,
  );
}
