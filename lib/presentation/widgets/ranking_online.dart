import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../catalogo/catalogo_tableros.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';
import 'panel_galactico.dart';

int _number(Map<String, dynamic> row, String key) =>
    (row[key] as num?)?.toInt() ?? 0;

/// Misma prelación de Java. El resultado final conserva sus puestos congelados.
List<Map<String, dynamic>> rankingDePartida(OnlineMatch game) {
  final frozen = game.result?['ranking'] as List?;
  if (frozen != null) {
    return [
      for (final row in frozen) Map<String, dynamic>.from(row as Map),
    ]..sort((a, b) => _number(a, 'position').compareTo(_number(b, 'position')));
  }
  final rows = [
    for (final row in game.scores) {...row},
  ];
  rows.sort((a, b) {
    for (final (key, descending) in [
      ('abandoned', false),
      ('points', true),
      ('completedZones', true),
      ('scoreSequence', false),
      ('joinOrder', false),
    ]) {
      final order = _number(a, key).compareTo(_number(b, key));
      if (order != 0) return descending ? -order : order;
    }
    return '${a['memberId']}'.compareTo('${b['memberId']}');
  });
  return [
    for (var i = 0; i < rows.length; i++) {...rows[i], 'position': i + 1},
  ];
}

class RankingSala extends StatelessWidget {
  final RoomsCubit rooms;
  const RankingSala({super.key, required this.rooms});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .82,
    child: PanelGalactico(
      child: BlocBuilder<RoomsCubit, RoomsState>(
        bloc: rooms,
        buildWhen: (a, b) => !identical(a.lobby?.match, b.lobby?.match),
        builder: (context, state) {
          final match = state.lobby?.match;
          final game = match == null ? null : OnlineMatch.fromJson(match);
          final ownId = state.lobby?.members
              .where((m) => m.userId == rooms.auth.state.session?.user.id)
              .firstOrNull
              ?.id;
          return Column(
            children: [
              CabeceraGalactica(
                title: 'Ranking',
                caption: game?.result == null
                    ? 'CLASIFICACIÓN EN VIVO'
                    : 'MISIÓN COMPLETADA',
                icon: Icons.emoji_events_outlined,
                closeLabel: 'Cerrar ranking',
                closeKey: const ValueKey('cerrar_ranking'),
              ),
              const Divider(height: 1, color: Color(0x225ACDE5)),
              Expanded(
                child: game == null
                    ? const Center(child: Text('Sin partida activa'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final row in rankingDePartida(game))
                            TarjetaRanking(game: game, row: row, ownId: ownId),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(4, 12, 4, 16),
                            child: Text(
                              'Zonas conquistadas · color, puesto y premio',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8BA7BB),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class TarjetaRanking extends StatelessWidget {
  final OnlineMatch game;
  final Map<String, dynamic> row;
  final String? ownId;
  const TarjetaRanking({
    super.key,
    required this.game,
    required this.row,
    this.ownId,
  });
  @override
  Widget build(BuildContext context) {
    final own = row['memberId'] == ownId;
    final leader = row['position'] == 1;
    final accent = leader
        ? oroGalactico
        : own
        ? cianHolograma
        : const Color(0xFF8BA7BB);
    final claims = game.claims
        .where((c) => c['memberId'] == row['memberId'])
        .toList();
    final zones = CatalogoTableros.predeterminado()
        .obtenerDefinicion(game.levelId)
        .zonas;
    final card = Container(
      key: ValueKey('ranking_jugador_${row['memberId']}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: own ? const Color(0xFF123146) : const Color(0xE60A1C2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: leader || own ? .5 : .16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Puesto ${row['position']}',
                child: Container(
                  width: 38,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${row['position']}.º',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['username']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row['completedZones']} ${row['completedZones'] == 1 ? 'zona' : 'zonas'}${own ? ' · Tú' : ''}${row['abandoned'] == 1 ? ' · Abandonó' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF96AFC1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  heightFactor: 1,
                  child: Text(
                    '${row['points']} pts',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (claims.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final claim in claims)
                  Builder(
                    builder: (context) {
                      final id = claim['zoneId'] as String;
                      final zone = zones.where((z) => z.id == id).firstOrNull;
                      final name = id.replaceAll('_', ' ');
                      final label =
                          zone?.nombre ??
                          (name.isEmpty
                              ? 'Sin nombre'
                              : '${name[0].toUpperCase()}${name.substring(1)}');
                      final color = zone?.tipo.color ?? cianHolograma;
                      return Semantics(
                        label:
                            'Zona $label, puesto ${claim['place']}, ${claim['points']} puntos',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: .32),
                            ),
                          ),
                          child: Text(
                            'Zona $label · ${claim['place']}.º · +${claim['points']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color.lerp(color, Colors.white, .65),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    if (game.result?['winnerMemberId'] != row['memberId']) return card;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey('coronacion_${row['memberId']}'),
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 2600),
      child: card,
      builder: (context, value, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: oroGalactico.withValues(
                alpha: .3 * math.sin(value * math.pi).abs(),
              ),
              blurRadius: 20,
            ),
          ],
        ),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: Opacity(opacity: .7 + .3 * value, child: child),
        ),
      ),
    );
  }
}
