import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../../catalogo/catalogo_tableros.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';
import '../pages/partida_page.dart' show GloboAlien;

class AvisosNave extends StatefulWidget {
  final RoomsCubit rooms;
  final String mensajeBase;
  final bool compacto;
  final bool prioridadBase;
  const AvisosNave({
    super.key,
    required this.rooms,
    required this.mensajeBase,
    this.compacto = false,
    this.prioridadBase = false,
  });
  @override
  State<AvisosNave> createState() => _AvisosNaveState();
}

class _Aviso {
  final String? text, roundId;
  final int? roundNumber;
  const _Aviso.text(this.text) : roundId = null, roundNumber = null;
  const _Aviso.round(this.roundId, this.roundNumber) : text = null;
}

class _AvisosNaveState extends State<AvisosNave> {
  final _queue = Queue<_Aviso>();
  final _seen = <String>{};
  Map<String, dynamic>? _source;
  String? _roundId;
  _Aviso? _current;
  Timer? _timer;
  StreamSubscription<RoomsState>? _subscription;
  String keyOf(Map<String, dynamic> c) =>
      '${c['memberId']}:${c['zoneId']}:${c['place']}:${c['sequence']}';
  @override
  void initState() {
    super.initState();
    final state = widget.rooms.state;
    _source = state.lobby?.match;
    if (_source != null) {
      final game = OnlineMatch.fromJson(_source!);
      _seen.addAll(game.claims.map(keyOf));
      _roundId = game.round?.id;
      if (game.round != null && game.round!.ownAction == null) {
        _queue.add(_Aviso.round(game.round!.id, game.round!.number));
        _next();
      }
    }
    _subscription = widget.rooms.stream.listen(_receive);
  }

  void _receive(RoomsState state) {
    if (!mounted) return;
    final source = state.lobby?.match;
    if (source == null || identical(source, _source)) return;
    _source = source;
    final game = OnlineMatch.fromJson(source);
    if (game.result != null || game.state == 'END_VOTE') {
      _timer?.cancel();
      _queue.clear();
      setState(() => _current = null);
      return;
    }
    final round = game.round;
    if (round != null && round.id != _roundId) {
      _roundId = round.id;
      _queue.removeWhere((a) => a.roundId != null);
      _queue.addFirst(_Aviso.round(round.id, round.number));
      if (_current?.roundId != null) {
        _timer?.cancel();
        _current = null;
      }
    }
    final zones = CatalogoTableros.predeterminado()
        .obtenerDefinicion(game.levelId)
        .zonas;
    final grouped = <String, List<String>>{};
    for (final claim in game.claims) {
      if (!_seen.add(keyOf(claim))) continue;
      final member = claim['memberId'] as String;
      final zone = zones.where((z) => z.id == claim['zoneId']).firstOrNull;
      grouped
          .putIfAbsent(member, () => [])
          .add(
            'Zona ${zone?.nombre ?? claim['zoneId']}: ${claim['place']}.º lugar, +${claim['points']} puntos',
          );
    }
    for (final entry in grouped.entries) {
      final name =
          game.scores
              .where((s) => s['memberId'] == entry.key)
              .firstOrNull?['username'] ??
          state.lobby?.members
              .where((m) => m.id == entry.key)
              .firstOrNull
              ?.name ??
          'Un jugador';
      _queue.add(_Aviso.text('¡$name reclamó ${entry.value.join(' · ')}!'));
    }
    if (_current == null) setState(_next);
  }

  void _next() {
    _timer?.cancel();
    _current = _queue.isEmpty ? null : _queue.removeFirst();
    if (_current != null) {
      _timer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(_next);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aviso = _current;
    return Semantics(
      liveRegion: true,
      child: StreamBuilder<RoomsState>(
        stream: widget.rooms.stream,
        initialData: widget.rooms.state,
        builder: (context, snapshot) {
          final seconds = snapshot.data?.secondsRemaining ?? 0;
          final ruleWarning =
              aviso?.roundId != null &&
              (widget.mensajeBase.startsWith('Ninguno de los dados') ||
                  widget.mensajeBase.startsWith('Jugada confirmada') ||
                  widget.mensajeBase.startsWith('Confirma tu jugada') ||
                  widget.mensajeBase.startsWith(
                    'Este número no tiene destinos',
                  ));
          final active =
              !widget.prioridadBase &&
              !ruleWarning &&
              aviso != null &&
              (aviso.roundId == null || aviso.roundId == _roundId);
          final message = !active
              ? widget.mensajeBase
              : aviso.text ??
                    '¡Ronda ${aviso.roundNumber}! Tienes $seconds segundos para mover.';
          return GloboAlien(
            key: const ValueKey('globo_nave_online'),
            mensaje: message,
            importante: active || widget.prioridadBase,
            compacto: widget.compacto,
          );
        },
      ),
    );
  }
}
