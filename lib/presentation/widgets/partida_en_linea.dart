import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/inicio_bloc.dart';
import '../../bloc/inicio_estado.dart';
import '../../bloc/inicio_evento.dart';
import '../../bloc/partida_estado.dart';
import '../../catalogo/catalogo_tableros.dart';
import '../../core/anclas.dart';
import '../../core/tablero.dart';
import '../../models/tirada.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';
import '../pages/partida_page.dart' show PanelPuntos;
import 'bandeja_numeros.dart';
import 'dados_partida.dart';
import 'diseno_juego_fijo.dart';
import 'disparo_numero_overlay.dart';
import 'estado_partida_online.dart';
import 'fondo_espacial.dart';
import 'historial_tiradas.dart';
import 'meteoritos_animacion.dart';
import 'nave_entrada.dart';
import 'nave_marciano.dart';
import 'tablero_view.dart';
import 'ranking_online.dart';
import 'leyenda_colores.dart';
import 'avisos_nave.dart';
import 'alerta_tiempo_ronda.dart';

/// Comparte el diseño y las animaciones del modo local. Java decide las jugadas.
class PartidaEnLinea extends StatefulWidget {
  final LobbySnapshot lobby;
  final RoomsState state;
  final RoomsCubit rooms;
  final VoidCallback onExit;
  final VoidCallback onBack;
  final Widget chatButton;
  const PartidaEnLinea({
    super.key,
    required this.lobby,
    required this.state,
    required this.rooms,
    required this.onExit,
    required this.onBack,
    required this.chatButton,
  });
  @override
  State<PartidaEnLinea> createState() => _PartidaEnLineaState();
}

class _PartidaEnLineaState extends State<PartidaEnLinea> {
  Map<String, dynamic>? _matchSource;
  OnlineMatch? _parsedGame;
  OnlineMatch get _game {
    if (!identical(_matchSource, widget.lobby.match)) {
      _matchSource = widget.lobby.match;
      _parsedGame = OnlineMatch.fromJson(_matchSource!);
    }
    return _parsedGame!;
  }

  OnlineMatch? _boardSource;
  Tablero? _parsedBoard;
  Tablero _board(OnlineMatch game) {
    if (!identical(_boardSource, game)) {
      _boardSource = game;
      _parsedBoard = _definition.crearTablero();
      for (final e in game.board.entries) {
        _parsedBoard!.colocarValor(e.key, e.value);
      }
    }
    return _parsedBoard!;
  }

  late final _definition = CatalogoTableros.predeterminado().obtenerDefinicion(
    _game.levelId,
  );
  late final _inicio = InicioBloc(
    _definition.crearTablero(),
    animarEntrada: true,
  );
  final _ship = GlobalKey(),
      _canvas = GlobalKey(),
      _above = GlobalKey(),
      _below = GlobalKey();
  late final _cells = {
    for (final zone in _definition.zonas)
      for (final cell in zone.celdas) cell.id: GlobalKey(),
  };
  int? _die;
  String? _target;
  FasePartida _dicePhase = FasePartida.eligiendoNumero;
  late bool _meteors = _game.round != null;
  bool _diceRevealed = false;
  DisparoPendiente? _shot;
  int _shotSequence = 0;
  bool get _enabled =>
      widget.state.channelConnected &&
      !widget.state.busy &&
      !widget.state.uncertain;
  @override
  void didUpdateWidget(PartidaEnLinea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.lobby.match, widget.lobby.match)) return;
    final old = OnlineMatch.fromJson(oldWidget.lobby.match!);
    if (old.round?.id != _game.round?.id) {
      _die = null;
      _target = null;
      _dicePhase = FasePartida.eligiendoNumero;
      _meteors = _game.round != null;
      _diceRevealed = false;
    }
    if (old.round != null) {
      for (final cell in _game.board.entries) {
        if (!old.board.containsKey(cell.key)) {
          _shot = DisparoPendiente(
            id: ++_shotSequence,
            numero: cell.value,
            celdaId: cell.key,
          );
          break;
        }
      }
    }
    if (_game.round?.ownAction != null) {
      _target = null;
    }
  }

  @override
  void dispose() {
    _inicio.close();
    super.dispose();
  }

  Widget _fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);
  void _ranking() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RankingSala(rooms: widget.rooms),
  );
  List<RegistroTirada> _history(OnlineMatch game) => [
    for (final h in game.history)
      if (h['kind'] == 'PLACE')
        RegistroTirada.colocada(
          Tirada(
            h['number'] as int,
            (h['dice'] as List)[0] as int,
            (h['dice'] as List)[1] as int,
          ),
          h['dieIndex'] as int,
          h['cellId'] as String,
        )
      else
        RegistroTirada.omitida(
          Tirada(
            h['number'] as int,
            (h['dice'] as List)[0] as int,
            (h['dice'] as List)[1] as int,
          ),
        ),
  ];
  @override
  Widget build(BuildContext context) {
    final game = _game, round = game.round;
    if (game.result != null || game.state == 'END_VOTE') {
      return EstadoPartidaOnline(
        game: game,
        lobby: widget.lobby,
        state: widget.state,
        rooms: widget.rooms,
        onExit: widget.onExit,
      );
    }
    return BlocBuilder<InicioBloc, InicioEstado>(
      bloc: _inicio,
      builder: (context, initial) {
        final board = _board(game);
        final preparing = round == null;
        final editable = _enabled && !game.prepared;
        final canAct =
            _enabled &&
            round != null &&
            round.ownAction == null &&
            (widget.state.secondsRemaining ?? 0) > 0 &&
            !_meteors &&
            _shot == null;
        final own = widget.lobby.members
            .where((m) => m.userId == widget.rooms.auth.state.session?.user.id)
            .firstOrNull;
        final points =
            game.scores
                    .where((s) => s['memberId'] == own?.id)
                    .firstOrNull?['points']
                as int? ??
            0;
        final selected = round?.ownAction?['dieIndex'] as int? ?? _die;
        final movesByDie = round == null
            ? <Set<String>>[]
            : [
                destinosConAncla(board, round.dice[0], round.dice[1]),
                destinosConAncla(board, round.dice[1], round.dice[0]),
              ];
        final noMoves =
            round != null && movesByDie.every((cells) => cells.isEmpty);
        final destinations = round != null && _die != null
            ? movesByDie[_die!]
            : <String>{};
        final waiting = widget.lobby.members
            .where((m) => !game.preparedIds.contains(m.id))
            .length;
        final message = preparing
            ? (game.prepared
                  ? 'Preparación confirmada. ${waiting == 1 ? 'Falta 1 participante.' : 'Faltan $waiting participantes.'}'
                  : initial.error ??
                        (initial.numeroSeleccionado == null
                            ? '${6 - initial.numerosFaltantes.length} de 6 colocados'
                            : 'Número ${initial.numeroSeleccionado} seleccionado · toca una celda +'))
            : round.ownAction != null
            ? 'Jugada confirmada · esperando a los demás'
            : noMoves && (!_meteors || _diceRevealed)
            ? '${motivoSinMovimientos(board, round.dice[0], round.dice[1])} Solo puedes omitir el turno.'
            : _target != null
            ? 'Confirma tu jugada'
            : _die == null
            ? 'Elige un dado para colocar su número'
            : destinations.isEmpty
            ? 'Este número no tiene destinos. Cambia al otro dado.'
            : 'El otro dado es el ancla · elige una casilla';
        final drawCells = {
          for (final entry in board.celdas.entries)
            entry.key: entry.key == _shot?.celdaId
                ? entry.value.sinValor()
                : entry.value,
        };
        final table = !game.prepared
            ? AbsorbPointer(
                absorbing: !editable,
                child: TableroView(
                  definicion: _definition,
                  estado: initial,
                  clavesCeldas: _cells,
                  onCeldaSeleccionada: (id) =>
                      _inicio.add(CeldaInicialSeleccionada(id)),
                ),
              )
            : TableroView.partida(
                definicion: _definition,
                atenuarPremios: true,
                celdas: drawCells,
                clavesCeldas: _cells,
                destinos: canAct ? destinations : {},
                interactiva: canAct && !noMoves,
                celdaPropuesta: canAct ? _target : null,
                numeroPropuesto: canAct && _die != null
                    ? round.dice[_die!]
                    : null,
                puestosReclamados: {
                  for (final z in game.zones)
                    z['zoneId'] as String: (z['nextPlace'] as int) - 1,
                },
                onCeldaSeleccionada: (id) {
                  if (destinations.contains(id)) setState(() => _target = id);
                },
              );
        return FondoEspacial(
          key: const ValueKey('contenido_partida_online'),
          ruta: _definition.recursos?.fondo,
          numeroEnContenido: true,
          child: LayoutBuilder(
            builder: (context, space) {
              final m = MedidasJuegoFijo(space);
              final shipWidth = m.compacto
                  ? (preparing ? 48.0 : 56.0)
                  : preparing
                  ? 134.0
                  : (space.maxHeight * .17).clamp(110.0, 160.0);
              final shipHeight =
                  shipWidth / (_definition.recursos?.proporcionNave ?? 1.65);
              final numberHeight = m.compacto
                  ? 0.0
                  : FondoEspacial.altoNumero(m.anchoPanel);
              final ship = SizedBox(
                key: _ship,
                width: shipWidth,
                child: NaveEntrada(
                  llegando:
                      preparing &&
                      !game.prepared &&
                      initial.faseVisual == FaseVisualInicio.llegandoNave,
                  onCompletada: () =>
                      _inicio.add(const LlegadaNaveCompletada()),
                  child: NaveMarciano(
                    recursos: _definition.recursos,
                    hazActivo:
                        initial.faseVisual != FaseVisualInicio.llegandoNave ||
                        game.prepared,
                  ),
                ),
              );
              final top = m.compacto
                  ? SizedBox(
                      height: preparing ? 62 : 68,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 78,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 54,
                                  height: 18,
                                  child: NumeroFondoNivel(
                                    ruta: _definition.recursos?.fondo,
                                    compacto: true,
                                  ),
                                ),
                                ship,
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 22,
                                  child: preparing
                                      ? _fit(const Text('PREPARA TU MISIÓN'))
                                      : PanelPuntos(
                                          puntos: points,
                                          meta: game.target,
                                          compacto: true,
                                        ),
                                ),
                                Expanded(
                                  child: _fit(
                                    preparing
                                        ? Text(
                                            message,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                          )
                                        : SizedBox(
                                            width: m.anchoPanel - 88,
                                            child: AvisosNave(
                                              rooms: widget.rooms,
                                              mensajeBase: message,
                                              prioridadBase:
                                                  noMoves &&
                                                  round.ownAction == null,
                                              compacto: true,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!preparing)
                            SizedBox(
                              width: 50,
                              height: 54,
                              child: TiempoRondaOnline(
                                rooms: widget.rooms,
                                roundId: round.id,
                                initialSeconds:
                                    widget.state.secondsRemaining ?? 0,
                              ),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: numberHeight,
                          child: NumeroFondoNivel(
                            ruta: _definition.recursos?.fondo,
                          ),
                        ),
                        SizedBox(
                          height: shipHeight,
                          child: preparing
                              ? Center(child: ship)
                              : Row(
                                  children: [
                                    Expanded(
                                      child: TiempoRondaOnline(
                                        rooms: widget.rooms,
                                        roundId: round.id,
                                        initialSeconds:
                                            widget.state.secondsRemaining ?? 0,
                                      ),
                                    ),
                                    ship,
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: PanelPuntos(
                                          puntos: points,
                                          meta: game.target,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        SizedBox(
                          height: 22,
                          child: _fit(
                            Text(
                              preparing
                                  ? 'PREPARA TU MISIÓN'
                                  : 'MISIÓN DE ${own?.name.toUpperCase() ?? ''}',
                              style: const TextStyle(
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        if (!preparing)
                          SizedBox(
                            height: 64,
                            child: _fit(
                              SizedBox(
                                width: m.anchoPanel,
                                child: AvisosNave(
                                  rooms: widget.rooms,
                                  mensajeBase: message,
                                  prioridadBase:
                                      noMoves && round.ownAction == null,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
              final prepActions = Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: editable && !initial.interaccionBloqueada
                          ? () => _inicio.add(const PreparacionReiniciada())
                          : null,
                      child: _fit(const Text('Cancelar selección')),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('acomodo_online_aleatorio'),
                      onPressed:
                          editable &&
                              !initial.interaccionBloqueada &&
                              initial.numerosFaltantes.isNotEmpty
                          ? () => _inicio.add(
                              const ColocacionAleatoriaSolicitada(),
                            )
                          : null,
                      child: _fit(const Text('Acomodo aleatorio')),
                    ),
                  ),
                ],
              );
              final headerHeight = m.compacto
                  ? (preparing ? 62.0 : 68.0)
                  : numberHeight + shipHeight + 22 + (preparing ? 0 : 64);
              final diceState = round == null
                  ? null
                  : PartidaEstado(
                      fase: _meteors && !_diceRevealed
                          ? FasePartida.tirando
                          : round.ownAction != null
                          ? FasePartida.rondaResuelta
                          : noMoves
                          ? FasePartida.sinMovimientos
                          : _dicePhase,
                      tirada: Tirada(
                        round.number,
                        round.dice[0],
                        round.dice[1],
                      ),
                      celdas: board.celdas,
                      historial: _history(game),
                      meta: game.target,
                      dadoSeleccionado: selected,
                      destinos: destinations,
                      puntos: points,
                    );
              final actionRow = noMoves
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('omitir_ronda_online'),
                        onPressed: canAct
                            ? () =>
                                  widget.rooms.confirmAction(game.id, round.id)
                            : null,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: _fit(const Text('Omitir turno')),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('confirmar_jugada_online'),
                            onPressed: canAct && _target != null
                                ? () => widget.rooms.confirmAction(
                                    game.id,
                                    round.id,
                                    dieIndex: _die,
                                    cellId: _target,
                                  )
                                : null,
                            child: _fit(const Text('Confirmar jugada')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('omitir_ronda_online'),
                            onPressed: canAct
                                ? () => widget.rooms.confirmAction(
                                    game.id,
                                    round.id,
                                  )
                                : null,
                            child: _fit(const Text('Omitir ronda')),
                          ),
                        ),
                      ],
                    );
              final preparationFooter = game.prepared
                  ? _fit(const Text('Posiciones iniciales confirmadas'))
                  : FilledButton(
                      key: const ValueKey('confirmar_preparacion_online'),
                      onPressed: editable && initial.puedeIniciar
                          ? () => widget.rooms.confirmPreparation(game.id, {
                              for (final c in initial.celdas.values)
                                if (c.valor != null) c.id: c.valor!,
                            })
                          : null,
                      child: _fit(const Text('Confirmar preparación')),
                    );
              return Stack(
                key: _canvas,
                fit: StackFit.expand,
                children: [
                  DisenoJuegoFijo(
                    medidas: m,
                    altoControles:
                        headerHeight +
                        (preparing ? (m.compacto ? 84 : 120) : 80),
                    cabecera: Row(
                      children: [
                        IconButton(
                          tooltip: 'Salir de la sala',
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: _fit(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'BRILLIANT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                if (round != null)
                                  BlocSelector<RoomsCubit, RoomsState, int?>(
                                    bloc: widget.rooms,
                                    selector: (state) => state.secondsRemaining,
                                    builder: (context, seconds) => Text(
                                      'Ronda ${round.number} · ${seconds ?? widget.state.secondsRemaining ?? 0} s',
                                      key: const ValueKey('reloj_online'),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (round != null)
                          Flexible(
                            flex: 2,
                            child: HistorialTiradas(
                              registros: _history(game),
                              celdas: board.celdas,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Ranking',
                          key: const ValueKey('ranking_online'),
                          onPressed: _ranking,
                          icon: const Icon(Icons.emoji_events_rounded),
                          visualDensity: VisualDensity.compact,
                        ),
                        widget.chatButton,
                      ],
                    ),
                    controles: Column(
                      children: [
                        top,
                        if (preparing) ...[
                          SizedBox(
                            height: m.compacto ? 48 : 52,
                            child: AbsorbPointer(
                              absorbing: !editable,
                              child: BandejaNumeros(
                                prefijoClave: 'numero_online_',
                                estado: initial,
                                altura: 48,
                                onPresentacionCompletada: () => _inicio.add(
                                  const PresentacionNumerosCompletada(),
                                ),
                                onSeleccionado: (n) =>
                                    _inicio.add(NumeroInicialSeleccionado(n)),
                              ),
                            ),
                          ),
                          if (!m.compacto)
                            SizedBox(
                              height: 28,
                              child: _fit(
                                Text(message, textAlign: TextAlign.center),
                              ),
                            ),
                          SizedBox(
                            height: m.compacto ? 36 : 40,
                            child: prepActions,
                          ),
                        ] else
                          SizedBox(
                            key: _above,
                            height: 80,
                            width: double.infinity,
                            child: LeyendaColores(definicion: _definition),
                          ),
                      ],
                    ),
                    tablero: table,
                    pie: preparing
                        ? Center(child: preparationFooter)
                        : SizedBox(
                            key: _below,
                            width: double.infinity,
                            child:
                                selected == null &&
                                    round.ownAction == null &&
                                    !noMoves
                                ? null
                                : Center(child: actionRow),
                          ),
                  ),
                  if (round != null && diceState != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !canAct || noMoves,
                        child: DadosPartida(
                          key: ValueKey('dados_${round.id}'),
                          prefijoClave: 'dado_online_',
                          estado: diceState,
                          interactiva: canAct && !noMoves,
                          lienzo: _canvas,
                          arriba: _above,
                          abajo: _below,
                          onSeleccionar: (id) => setState(() {
                            _die = id;
                            _target = null;
                            // Los dados ya están arriba después de la primera elección.
                            // Cambiar de dado no vuelve a solicitar esa animación.
                            if (_dicePhase == FasePartida.eligiendoNumero) {
                              _dicePhase = FasePartida.moviendoDados;
                            }
                          }),
                          onMovimientoCompletado: () => setState(
                            () => _dicePhase = FasePartida.eligiendoDestino,
                          ),
                        ),
                      ),
                    ),
                  if (round != null &&
                      selected == null &&
                      round.ownAction == null &&
                      !noMoves)
                    Positioned(
                      bottom: 0,
                      right: 12,
                      child: IconButton(
                        key: const ValueKey('omitir_ronda_online'),
                        tooltip: 'Omitir ronda',
                        onPressed: canAct
                            ? () =>
                                  widget.rooms.confirmAction(game.id, round.id)
                            : null,
                        icon: const Icon(Icons.skip_next),
                      ),
                    ),
                  if ((preparing ? initial.disparoPendiente : _shot)
                      case final shot?)
                    Positioned.fill(
                      child: DisparoNumeroOverlay(
                        key: ValueKey(
                          'disparo_${preparing ? 'inicio' : 'ronda'}_${shot.id}',
                        ),
                        disparo: shot,
                        origen: _ship,
                        destino: _cells[shot.celdaId]!,
                        fraccionOrigen: Offset(
                          .5,
                          _definition.recursos?.emisionY ?? .68,
                        ),
                        onCompletado: () {
                          if (preparing) {
                            _inicio.add(DisparoNumeroCompletado(shot.id));
                          } else {
                            setState(() => _shot = null);
                          }
                        },
                      ),
                    ),
                  if (_meteors && _shot == null && round != null)
                    Positioned.fill(
                      child: MeteoritosAnimacion(
                        key: ValueKey('meteoros_${round.id}'),
                        tiradaId: round.number,
                        onImpacto: (_) {
                          if (mounted && _game.round?.id == round.id) {
                            setState(() => _diceRevealed = true);
                          }
                        },
                        onCompletada: (_) {
                          if (mounted) setState(() => _meteors = false);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
