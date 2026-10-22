import 'dart:math';
import 'package:bloc/bloc.dart';
import '../core/anclas.dart';
import '../core/marcador.dart';
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

  /// Zonas reclamadas por los jugadores. Por ahora juega un solo jugador
  /// local y la meta se toma como si fuera una partida de [jugadores].
  final Marcador _marcador;
  final String _jugador;
  final String _nombreJugador;

  /// Zona completada con la colocación de esta ronda; se libera si la
  /// jugada se cambia antes de lanzar.
  Reclamo? _reclamoRonda;

  factory PartidaBloc(
    Tablero tablero, {
    Random? azar,
    int jugadores = 2,
    String jugadorId = 'jugador_1',
    String? nombreJugador,
  }) {
    final copia = Tablero(
      id: tablero.id,
      zonas: [
        for (final zona in tablero.zonas.values)
          Zona(
            id: zona.id,
            tipo: zona.tipo,
            campoPuntuacion: zona.campoPuntuacion,
            puntuaciones: zona.puntuaciones,
            celdas: zona.celdas.values,
          ),
      ],
    );
    final fuente = azar ?? Random();
    return PartidaBloc._(
      copia,
      fuente,
      Tirada.lanzar(1, fuente),
      Marcador(jugadores: jugadores),
      jugadorId,
      nombreJugador ?? 'Jugador',
    );
  }

  PartidaBloc._(
    this._tablero,
    this._azar,
    Tirada primera,
    this._marcador,
    this._jugador,
    this._nombreJugador,
  ) : super(
        PartidaEstado(
          fase: FasePartida.tirando,
          tirada: primera,
          celdas: _tablero.celdas,
          historial: const [],
          meta: _marcador.meta,
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
    if (_reclamoRonda case final reclamo?) _marcador.liberar(reclamo);
    _reclamoRonda = null;
  }

  bool get _sinMovimientos => _destinos(0).isEmpty && _destinos(1).isEmpty;

  PartidaEstado _estado(FasePartida fase, {String? error}) => PartidaEstado(
    fase: fase,
    tirada: _tirada,
    celdas: _tablero.celdas,
    historial: _historial,
    dadoSeleccionado: _seleccion,
    celdaColocada: _colocacion,
    puntos: _marcador.puntosDe(_jugador),
    meta: _marcador.meta,
    puestosReclamados: {
      for (final zonaId in _marcador.reclamos.keys)
        zonaId: _marcador.puestosReclamados(zonaId),
    },
    reclamoRonda: _reclamoRonda,
    resultados: fase == FasePartida.mostrandoResultados
        ? _resultados()
        : const [],
    destinos:
        (fase == FasePartida.eligiendoDestino || _colocacion != null) &&
            fase != FasePartida.celebrandoVictoria &&
            fase != FasePartida.mostrandoResultados &&
            _seleccion != null
        ? _destinos(_seleccion!)
        : const {},
    puedeOmitir:
        !{
          FasePartida.tirando,
          FasePartida.revelandoResultados,
          FasePartida.moviendoDados,
          FasePartida.rondaResuelta,
          FasePartida.celebrandoVictoria,
          FasePartida.mostrandoResultados,
        }.contains(fase) &&
        _sinMovimientos,
    error: error,
  );

  /// Ranking con nombres. Por ahora sólo participa el jugador local.
  List<ResultadoJugador> _resultados() => [
    for (final posicion in _marcador.ranking([_jugador]))
      ResultadoJugador(
        jugadorId: posicion.jugadorId,
        nombre: _nombreJugador,
        puntos: posicion.puntos,
        zonasCompletadas: posicion.zonasCompletadas,
        posicion: posicion.posicion,
        esLocal: posicion.jugadorId == _jugador,
      ),
  ];

  void _procesar(PartidaEvento evento, Emitter<PartidaEstado> emit) {
    final id = switch (evento) {
      MeteorosSolicitados() => evento.tiradaAnteriorId,
      ImpactoConfirmado() => evento.tiradaId,
      MeteorosCompletados() => evento.tiradaId,
      DadoSeleccionado() => evento.tiradaId,
      MovimientoDadosCompletado() => evento.tiradaId,
      DestinoSeleccionado() => evento.tiradaId,
      TiroOmitido() => evento.tiradaId,
      DadosRelanzados() => evento.tiradaId,
      CelebracionCompletada() => evento.tiradaId,
    };
    if (id != _tirada.id) return;
    // Al terminar la partida sólo se espera el cierre de la celebración.
    if (state.partidaTerminada) {
      if (evento is CelebracionCompletada &&
          state.fase == FasePartida.celebrandoVictoria) {
        emit(_estado(FasePartida.mostrandoResultados));
      }
      return;
    }
    switch (evento) {
      case CelebracionCompletada():
        return;
      case MeteorosSolicitados():
        if (state.fase != FasePartida.rondaResuelta || state.gano) return;
        _tirada = Tirada.lanzar(_tirada.id + 1, _azar);
        _seleccion = null;
        _colocacion = null;
        _reclamoRonda = null;
        emit(_estado(FasePartida.tirando));
      case DadosRelanzados():
        if (!state.puedeRelanzar) return;
        // Como omitir: la tirada se registra sin escribir nada y comienza
        // directamente la siguiente.
        _historial.add(RegistroTirada.omitida(_tirada));
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
        final zona = _tablero.obtenerZonaDeCelda(evento.celdaId);
        if (zona.estaCompletada) {
          _reclamoRonda = _marcador.reclamar(zona: zona, jugadorId: _jugador);
        }
        _historial.add(
          RegistroTirada.colocada(_tirada, _seleccion!, evento.celdaId),
        );
        // Llegar a la meta termina la partida: la jugada ya no se cambia.
        emit(
          _estado(
            _marcador.haGanado(_jugador)
                ? FasePartida.celebrandoVictoria
                : FasePartida.rondaResuelta,
          ),
        );
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
