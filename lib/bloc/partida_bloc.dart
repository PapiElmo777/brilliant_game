import 'dart:math';
import 'package:bloc/bloc.dart';
import '../core/anclas.dart';
import '../core/tablero.dart';
import '../models/tirada.dart';
import '../models/zona.dart';
import 'partida_estado.dart';
import 'partida_evento.dart';

class PartidaBloc extends Bloc<PartidaEvento, PartidaEstado> {
  final Tablero _tablero;
  final Random _azar;
  final _historial = <RegistroTirada>[];
  late Tirada _tirada;
  int? _seleccion;

  /// Celda escrita en la ronda actual. Puede cambiarse hasta lanzar de nuevo.
  String? _colocacion;

  factory PartidaBloc(Tablero tablero, {Random? azar}) {
    final copia = Tablero(
      id: tablero.id,
      zonas: [
        for (final zona in tablero.zonas.values)
          Zona(
            id: zona.id,
            tipo: zona.tipo,
            campoPuntuacion: zona.campoPuntuacion,
            celdas: zona.celdas.values,
          ),
      ],
    );
    final fuente = azar ?? Random();
    return PartidaBloc._(copia, fuente, Tirada.lanzar(1, fuente));
  }

  PartidaBloc._(this._tablero, this._azar, Tirada primera)
    : super(
        PartidaEstado(
          fase: FasePartida.tirando,
          tirada: primera,
          celdas: _tablero.celdas,
          historial: const [],
        ),
      ) {
    _tirada = primera;
    on<PartidaEvento>(
      _procesar,
      transformer: (eventos, mapper) => eventos.asyncExpand(mapper),
    );
  }

  /// Destinos del dado como si la colocación de esta ronda no existiera.
  Set<String> _destinos(int dado) {
    Set<String> calcular() => destinosConAncla(
      _tablero,
      _tirada.dados[dado].valor,
      _tirada.dados[1 - dado].valor,
    );
    final colocacion = _colocacion;
    if (colocacion == null) return calcular();
    final valor = _tablero.obtenerCelda(colocacion).valor!;
    _tablero.vaciarCelda(colocacion);
    try {
      return calcular();
    } finally {
      _tablero.colocarValor(colocacion, valor);
    }
  }

  /// Retira el número escrito en esta ronda y su registro del historial.
  void _deshacerColocacion() {
    final colocacion = _colocacion;
    if (colocacion == null) return;
    _tablero.vaciarCelda(colocacion);
    _historial.removeLast();
    _colocacion = null;
  }

  bool get _sinMovimientos => _destinos(0).isEmpty && _destinos(1).isEmpty;

  PartidaEstado _estado(FasePartida fase, {String? error}) => PartidaEstado(
    fase: fase,
    tirada: _tirada,
    celdas: _tablero.celdas,
    historial: _historial,
    dadoSeleccionado: _seleccion,
    celdaColocada: _colocacion,
    destinos:
        (fase == FasePartida.eligiendoDestino || _colocacion != null) &&
            _seleccion != null
        ? _destinos(_seleccion!)
        : const {},
    puedeOmitir:
        !{
          FasePartida.tirando,
          FasePartida.revelandoResultados,
          FasePartida.moviendoDados,
          FasePartida.rondaResuelta,
        }.contains(fase) &&
        _sinMovimientos,
    error: error,
  );

  void _procesar(PartidaEvento evento, Emitter<PartidaEstado> emit) {
    final id = switch (evento) {
      MeteorosSolicitados() => evento.tiradaAnteriorId,
      ImpactoConfirmado() => evento.tiradaId,
      MeteorosCompletados() => evento.tiradaId,
      DadoSeleccionado() => evento.tiradaId,
      MovimientoDadosCompletado() => evento.tiradaId,
      DestinoSeleccionado() => evento.tiradaId,
      TiroOmitido() => evento.tiradaId,
    };
    if (id != _tirada.id) return;
    switch (evento) {
      case MeteorosSolicitados():
        if (state.fase != FasePartida.rondaResuelta) return;
        _tirada = Tirada.lanzar(_tirada.id + 1, _azar);
        _seleccion = null;
        _colocacion = null;
        emit(_estado(FasePartida.tirando));
      case ImpactoConfirmado():
        if (state.fase == FasePartida.tirando)
          emit(_estado(FasePartida.revelandoResultados));
      case MeteorosCompletados():
        if (!state.animandoMeteoros) return;
        emit(
          _estado(
            _sinMovimientos
                ? FasePartida.sinMovimientos
                : FasePartida.eligiendoNumero,
          ),
        );
      case DadoSeleccionado():
        if (!state.puedeSeleccionar || evento.dadoId < 0 || evento.dadoId > 1)
          return;
        if (_colocacion != null) {
          // Cambiar de dado tras colocar deshace la jugada para rehacerla.
          if (evento.dadoId == _seleccion) return;
          _deshacerColocacion();
        }
        final subir = _seleccion == null;
        _seleccion = evento.dadoId;
        emit(
          _estado(
            subir ? FasePartida.moviendoDados : FasePartida.eligiendoDestino,
          ),
        );
      case MovimientoDadosCompletado():
        if (state.fase == FasePartida.moviendoDados)
          emit(_estado(FasePartida.eligiendoDestino));
      case DestinoSeleccionado():
        if (state.puedeSeleccionar && _seleccion == null) {
          emit(_estado(state.fase, error: 'Primero elige un número.'));
          return;
        }
        if (_colocacion != null && evento.celdaId == _colocacion) {
          // Tocar el número recién escrito lo retira.
          _deshacerColocacion();
          emit(_estado(FasePartida.eligiendoDestino));
          return;
        }
        if (!state.puedeSeleccionar || _seleccion == null) return;
        if (!_destinos(_seleccion!).contains(evento.celdaId)) {
          emit(
            _estado(
              state.fase,
              error: 'Esa casilla no es válida. Elige una casilla resaltada.',
            ),
          );
          return;
        }
        _deshacerColocacion();
        _tablero.colocarValor(evento.celdaId, _tirada.dados[_seleccion!].valor);
        _colocacion = evento.celdaId;
        _historial.add(
          RegistroTirada.colocada(_tirada, _seleccion!, evento.celdaId),
        );
        emit(_estado(FasePartida.rondaResuelta));
      case TiroOmitido():
        if (!state.puedeSeleccionar || state.fase == FasePartida.rondaResuelta)
          return;
        if (!_sinMovimientos) {
          emit(
            _estado(
              state.fase,
              error:
                  'Hay movimientos disponibles. Cambia el número seleccionado.',
            ),
          );
          return;
        }
        _historial.add(RegistroTirada.omitida(_tirada));
        emit(_estado(FasePartida.rondaResuelta));
    }
  }
}
