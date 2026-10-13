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

  Set<String> _destinos(int dado) => destinosConAncla(
    _tablero,
    _tirada.dados[dado].valor,
    _tirada.dados[1 - dado].valor,
  );

  bool get _sinMovimientos => _destinos(0).isEmpty && _destinos(1).isEmpty;

  PartidaEstado _estado(FasePartida fase, {String? error}) => PartidaEstado(
    fase: fase,
    tirada: _tirada,
    celdas: _tablero.celdas,
    historial: _historial,
    dadoSeleccionado: _seleccion,
    destinos: fase == FasePartida.eligiendoDestino && _seleccion != null
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
        if (state.fase != FasePartida.eligiendoDestino || _seleccion == null)
          return;
        if (!_destinos(_seleccion!).contains(evento.celdaId)) {
          emit(_estado(state.fase, error: 'Selecciona un destino disponible.'));
          return;
        }
        _tablero.colocarValor(evento.celdaId, _tirada.dados[_seleccion!].valor);
        _historial.add(
          RegistroTirada.colocada(_tirada, _seleccion!, evento.celdaId),
        );
        emit(_estado(FasePartida.rondaResuelta));
      case TiroOmitido():
        if (!state.puedeSeleccionar) return;
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
