import 'dart:math';
import 'package:flutter/material.dart';
import '../../bloc/inicio_estado.dart';
import '../../catalogo/catalogo_tableros.dart';
import '../../catalogo/definicion_tablero.dart';
import '../../core/anclas.dart';
import '../../core/preparacion_inicial.dart';
import '../../core/tablero.dart';
import '../../models/tirada.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';
import 'dados_partida.dart';
import 'fondo_espacial.dart';
import 'nave_marciano.dart';
import 'tablero_view.dart';
import 'estado_partida_online.dart';

class PartidaEnLinea extends StatefulWidget {
  final LobbySnapshot lobby;
  final RoomsState state;
  final RoomsCubit rooms;
  const PartidaEnLinea({
    super.key,
    required this.lobby,
    required this.state,
    required this.rooms,
  });
  @override
  State<PartidaEnLinea> createState() => _PartidaEnLineaState();
}

class _PartidaEnLineaState extends State<PartidaEnLinea> {
  late final DefinicionTablero _definition = CatalogoTableros.predeterminado()
      .obtenerDefinicion(_game.levelId);
  late final PreparacionInicial _preparation = PreparacionInicial(
    _definition.crearTablero(),
  );
  final _scroll = ScrollController();
  int? _number, _die;
  String? _initialCell, _target, _error;
  OnlineMatch get _game => OnlineMatch.fromJson(widget.lobby.match!);
  bool get _enabled =>
      widget.state.channelConnected &&
      !widget.state.busy &&
      !widget.state.uncertain;
  @override
  void didUpdateWidget(PartidaEnLinea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = OnlineMatch.fromJson(oldWidget.lobby.match!);
    if (old.round?.id != _game.round?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
    if (old.round?.id != _game.round?.id || _game.round?.ownAction != null) {
      _die = null;
      _target = null;
      _error = null;
    }
    if (_game.prepared) {
      _number = null;
      _initialCell = null;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Tablero _board() {
    final board = _definition.crearTablero();
    for (final entry in _game.board.entries) {
      board.colocarValor(entry.key, entry.value);
    }
    return board;
  }

  void _prepareCell(String id) {
    if (!_enabled || _game.prepared) return;
    try {
      if (_number != null) {
        _preparation.colocarValor(id, _number!);
        _number = null;
        _initialCell = null;
      } else if (_initialCell != null) {
        if (_initialCell == id) {
          _preparation.vaciarCelda(id);
        } else {
          _preparation.intercambiar(_initialCell!, id);
        }
        _initialCell = null;
      } else if (_preparation.celdas[id]?.valor != null) {
        _initialCell = id;
      } else {
        throw ArgumentError('Elige primero un número del 1 al 6.');
      }
      setState(() => _error = null);
    } on ArgumentError catch (e) {
      setState(() => _error = '${e.message}');
    }
  }

  void _randomize() {
    try {
      for (final (cell, value) in _preparation.distribucionAleatoria(
        Random(),
      )) {
        _preparation.colocarValor(cell, value);
      }
      setState(() {
        _number = null;
        _initialCell = null;
        _error = null;
      });
    } on Object {
      setState(
        () => _error =
            'No se pudo completar ese acomodo. Revisa los números colocados.',
      );
    }
  }

  Widget _fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);
  Widget _layout({
    required List<Widget> header,
    required Widget board,
    required Widget actions,
  }) => LayoutBuilder(
    key: const ValueKey('contenido_partida_online'),
    builder: (context, size) {
      final horizontal = size.maxWidth > 600;
      final boardView = Center(
        child: AspectRatio(aspectRatio: 1, child: board),
      );
      if (size.maxHeight < (horizontal ? 196 : 250)) {
        return ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(8),
          children: [
            ...header,
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: board,
              ),
            ),
            const SizedBox(height: 8),
            actions,
          ],
        );
      }
      return Padding(
        padding: const EdgeInsets.all(8),
        child: horizontal
            ? Row(
                children: [
                  Expanded(child: boardView),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: min(380, size.maxWidth * .5),
                    child: Column(
                      children: [
                        ...header,
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 90,
                              child: NaveMarciano(
                                recursos: _definition.recursos,
                              ),
                            ),
                          ),
                        ),
                        actions,
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  ...header,
                  Expanded(child: boardView),
                  const SizedBox(height: 6),
                  actions,
                ],
              ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final game = _game, round = game.round;
    if (game.state == 'END_VOTE' || game.result != null) {
      return EstadoPartidaOnline(
        game: game,
        lobby: widget.lobby,
        state: widget.state,
        rooms: widget.rooms,
      );
    }
    final board = game.prepared ? _board() : null;
    final editable = _enabled && !game.prepared && game.state == 'PREPARING';
    final canAct =
        _enabled &&
        game.state == 'ROUND_ACTIVE' &&
        round != null &&
        round.ownAction == null &&
        (widget.state.secondsRemaining ?? 0) > 0;
    final destinations = round != null && _die != null
        ? destinosConAncla(board!, round.dice[_die!], round.dice[1 - _die!])
        : <String>{};
    final waiting = widget.lobby.members
        .where((m) => !game.preparedIds.contains(m.id))
        .length;
    final initialState = InicioEstado(
      fase: _preparation.estaLista ? FaseInicio.listo : FaseInicio.preparando,
      celdas: _preparation.celdas,
      numerosFaltantes: _preparation.numerosFaltantes,
      numeroSeleccionado: _number,
      celdaSeleccionada: _initialCell,
    );
    final boardView = !game.prepared
        ? AbsorbPointer(
            absorbing: !editable,
            child: TableroView(
              definicion: _definition,
              estado: initialState,
              onCeldaSeleccionada: _prepareCell,
            ),
          )
        : TableroView.partida(
            definicion: _definition,
            celdas: board!.celdas,
            destinos: canAct ? destinations : {},
            interactiva: canAct,
            celdaPropuesta: _target,
            puestosReclamados: {
              for (final zone in game.zones)
                zone['zoneId'] as String: (zone['nextPlace'] as int) - 1,
            },
            onCeldaSeleccionada: (id) {
              if (destinations.contains(id)) {
                setState(() {
                  _target = id;
                  _error = null;
                });
              } else {
                setState(() => _error = 'Casilla no válida para ese dado.');
              }
            },
          );
    final header = <Widget>[];
    Widget actions;
    if (round == null) {
      final status =
          _error ??
          (game.prepared
              ? (waiting == 1
                    ? 'Preparación confirmada. Falta 1 participante.'
                    : 'Preparación confirmada. Faltan $waiting participantes.')
              : '${6 - _preparation.numerosFaltantes.length}/6 colocados · toca una casilla +');
      header.add(
        SizedBox(
          height: 44,
          child: _fit(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Preparando la misión',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: _error != null
                        ? Colors.amber
                        : const Color(0xFFB1C4D4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!game.prepared) {
        header.add(
          SizedBox(
            height: 48,
            child: Row(
              children: [
                for (var i = 1; i <= 6; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        key: ValueKey('numero_online_$i'),
                        showCheckmark: false,
                        label: Text(
                          '$i',
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(fontSize: 20),
                        ),
                        selected: _number == i,
                        onSelected:
                            editable &&
                                _preparation.numerosFaltantes.contains(i)
                            ? (_) => setState(() {
                                _number = i;
                                _initialCell = null;
                                _error = null;
                              })
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        header.add(
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const ValueKey('acomodo_online_aleatorio'),
                    onPressed: editable && !_preparation.estaLista
                        ? _randomize
                        : null,
                    child: _fit(const Text('Acomodo aleatorio')),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: !editable
                        ? null
                        : () {
                            _preparation.reiniciar();
                            setState(() {
                              _number = null;
                              _initialCell = null;
                              _error = null;
                            });
                          },
                    child: _fit(const Text('Reiniciar')),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      actions = game.prepared
          ? SizedBox(
              height: 48,
              child: _fit(Text('$waiting participantes por confirmar')),
            )
          : SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('confirmar_preparacion_online'),
                onPressed: editable && _preparation.estaLista
                    ? () => widget.rooms.confirmPreparation(game.id, {
                        for (final c in _preparation.celdas.values)
                          if (c.valor != null) c.id: c.valor!,
                      })
                    : null,
                child: _fit(const Text('Confirmar preparación')),
              ),
            );
    } else {
      final status =
          _error ??
          (round.ownAction != null
              ? 'Esperando a los demás'
              : widget.state.secondsRemaining == 0
              ? 'Tiempo agotado'
              : _target != null
              ? '${round.dice[_die!]} en $_target · sin confirmar'
              : _die == null
              ? 'Elige dado; el otro es el ancla'
              : destinations.isEmpty
              ? 'Sin destinos: prueba el otro dado u omite'
              : 'Elige una casilla resaltada');
      final resolved = round.resolvedIds
          .intersection(widget.lobby.members.map((m) => m.id).toSet())
          .length;
      header.add(
        SizedBox(
          height: 70,
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey('dados_online_${round.id}'),
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 550),
                builder: (context, t, _) => Transform.translate(
                  offset: Offset(
                    0,
                    (1 - Curves.easeInOutCubic.transform(t)) * 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Transform.rotate(
                            angle: (1 - t) * (i == 0 ? -.12 : .13),
                            child: FichaDado(
                              key: ValueKey('dado_online_$i'),
                              dado: Dado(i, round.dice[i]),
                              seleccionado: _die == i,
                              onTap: canAct
                                  ? () => setState(() {
                                      _die = i;
                                      _target = null;
                                      _error = null;
                                    })
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _fit(
                  SizedBox(
                    width: 160,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status,
                          key: _target == null
                              ? null
                              : const ValueKey('propuesta_online'),
                          maxLines: 3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _error == null
                                ? const Color(0xFFB1C4D4)
                                : Colors.amber,
                          ),
                        ),
                        Text(
                          '$resolved/${widget.lobby.members.length} resolvieron',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      actions = SizedBox(
        height: 48,
        child: Row(
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
                    ? () => widget.rooms.confirmAction(game.id, round.id)
                    : null,
                child: _fit(const Text('Omitir ronda')),
              ),
            ),
          ],
        ),
      );
    }
    return FondoEspacial(
      ruta: _definition.recursos?.fondo,
      numeroEnContenido: true,
      child: _layout(
        header: [
          if (game.prepared && game.round != null && game.scores.isNotEmpty)
            MarcadorOnline(
              scores: game.scores,
              ownId: widget.lobby.members
                  .where(
                    (m) => m.userId == widget.rooms.auth.state.session?.user.id,
                  )
                  .firstOrNull
                  ?.id,
            ),
          ...header,
        ],
        board: boardView,
        actions: actions,
      ),
    );
  }
}
