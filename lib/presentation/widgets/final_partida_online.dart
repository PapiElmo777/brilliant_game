import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../catalogo/catalogo_tableros.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';
import 'celebracion_victoria.dart';
import 'fondo_espacial.dart';
import 'nave_marciano.dart';
import 'ranking_online.dart';
import 'insignia_resultado.dart';

class FinalPartidaOnline extends StatefulWidget {
  final OnlineMatch game;
  final String? ownId;
  final RoomsState state;
  final RoomsCubit rooms;
  final VoidCallback onExit;
  const FinalPartidaOnline({
    super.key,
    required this.game,
    required this.ownId,
    required this.state,
    required this.rooms,
    required this.onExit,
  });
  @override
  State<FinalPartidaOnline> createState() => _FinalPartidaOnlineState();
}

class _FinalPartidaOnlineState extends State<FinalPartidaOnline> {
  final _control = ControlCelebracion();
  final _ship = GlobalKey(), _board = GlobalKey();
  late bool _shown = widget.rooms.resultWasShown(widget.game.id);
  Map<String, dynamic> get _result => widget.game.result!;
  List<Map<String, dynamic>> get _ranking => [
    for (final entry in _result['ranking'] as List)
      Map<String, dynamic>.from(entry as Map),
  ];
  Map<String, dynamic>? get _own =>
      _ranking.where((p) => p['memberId'] == widget.ownId).firstOrNull;
  bool get _won =>
      widget.ownId != null && widget.ownId == _result['winnerMemberId'];
  void _complete() {
    if (!mounted || _shown) return;
    widget.rooms.markResultShown(widget.game.id);
    setState(() => _shown = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shown = true;
      widget.rooms.markResultShown(widget.game.id);
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = CatalogoTableros.predeterminado().obtenerDefinicion(
      widget.game.levelId,
    );
    final winner = _ranking
        .where((p) => p['memberId'] == _result['winnerMemberId'])
        .firstOrNull;
    final place = _own?['position'];
    final positionText = place == null
        ? 'Partida finalizada'
        : 'Tu puesto: $place.º';
    if (!_shown && _result['winnerMemberId'] != null) {
      final board = definition.crearTablero();
      for (final e in widget.game.board.entries) {
        board.colocarValor(e.key, e.value);
      }
      return FondoEspacial(
        ruta: definition.recursos?.fondo,
        numeroEnContenido: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_won)
              CelebracionVictoria(
                key: const ValueKey('victoria_online'),
                definicion: definition,
                celdas: board.celdas,
                puntos: _own?['points'] as int? ?? 0,
                nave: _ship,
                tablero: _board,
                control: _control,
                onCompletada: _complete,
              )
            else
              DerrotaOnline(
                key: const ValueKey('derrota_online'),
                nave: NaveMarciano(
                  recursos: definition.recursos,
                  hazActivo: false,
                ),
                puesto: positionText,
                posicion: place as int?,
                onComplete: _complete,
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Ver ranking',
                key: const ValueKey('ver_ranking_online'),
                onPressed: _complete,
                icon: const Icon(Icons.emoji_events_rounded),
              ),
            ),
          ],
        ),
      );
    }
    final enabled =
        widget.state.channelConnected &&
        !widget.state.busy &&
        !widget.state.uncertain;
    final available = widget.game.rematch?['available'] == true;
    return FondoEspacial(
      ruta: definition.recursos?.fondo,
      numeroEnContenido: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              InsigniaResultado(ganador: _won, puesto: place as int?),
              const SizedBox(height: 18),
              Text(
                winner == null
                    ? 'Partida finalizada'
                    : '${winner['username']} ganó',
                key: const ValueKey('resultado_online'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                switch (_result['reason']) {
                  'TARGET' => 'Meta alcanzada',
                  'END_VOTE' => 'Finalizada por votación',
                  'ABANDONMENT' => 'Victoria por abandono',
                  _ => 'Sin participantes',
                },
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9EB5C7)),
              ),
              if (!_won && place != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    positionText,
                    key: const ValueKey('puesto_online'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF96ECFF),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 24, 2, 12),
                child: Text(
                  'REGISTRO DEL ESCUADRÓN',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.8,
                    color: Color(0xFF9EB5C7),
                  ),
                ),
              ),
              for (final p in rankingDePartida(widget.game))
                TarjetaRanking(game: widget.game, row: p, ownId: widget.ownId),
              const SizedBox(height: 12),
              Text(
                available
                    ? '${widget.game.rematch?['acceptedCount'] ?? 0} aceptaron la revancha'
                    : 'La siguiente partida ya comenzó.',
                textAlign: TextAlign.center,
              ),
              FilledButton(
                key: const ValueKey('revancha_online'),
                onPressed: enabled && available
                    ? () => widget.rooms.acceptRematch(widget.game.id)
                    : null,
                child: const Text('Revancha'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('salir_menu_online'),
                onPressed: widget.state.busy || widget.state.uncertain
                    ? null
                    : widget.onExit,
                child: const Text('Salir al menú principal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DerrotaOnline extends StatefulWidget {
  final Widget nave;
  final String puesto;
  final int? posicion;
  final VoidCallback onComplete;
  const DerrotaOnline({
    super.key,
    required this.nave,
    required this.puesto,
    this.posicion,
    required this.onComplete,
  });
  @override
  State<DerrotaOnline> createState() => _DerrotaOnlineState();
}

class _DerrotaOnlineState extends State<DerrotaOnline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _line =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3600),
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onComplete();
        })
        ..forward();
  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _line,
    builder: (context, _) => LayoutBuilder(
      builder: (context, size) {
        final t = _line.value;
        final hit = ((t - .28) / .12).clamp(0.0, 1.0),
            fall = ((t - .4) / .45).clamp(0.0, 1.0);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left:
                  size.maxWidth * .5 - math.min(170.0, size.maxWidth * .4) / 2,
              top: size.maxHeight * .22 + fall * fall * size.maxHeight * .65,
              child: Transform.rotate(
                angle: fall * 1.8,
                child: Opacity(
                  opacity: 1 - fall,
                  child: SizedBox(
                    width: math.min(170.0, size.maxWidth * .4),
                    child: widget.nave,
                  ),
                ),
              ),
            ),
            if (t >= .12 && t < .4)
              Positioned(
                left: size.maxWidth * .5,
                top: 0,
                width: 4,
                height: size.maxHeight * .3,
                child: const ColoredBox(color: Color(0xFFFF475C)),
              ),
            if (hit > 0 && fall < .6)
              Positioned(
                left: size.maxWidth * .5 - 32,
                top: size.maxHeight * .27 - 32,
                child: Opacity(
                  opacity: 1 - fall,
                  child: Transform.scale(
                    scale: hit * (1 + fall),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFA13C),
                      size: 64,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.posicion != null)
                    Text(
                      '${widget.posicion}.º',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF96ECFF),
                      ),
                    ),
                  Text(
                    widget.puesto,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
