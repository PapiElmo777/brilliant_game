import 'package:flutter/material.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';

class MarcadorOnline extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  final String? ownId;
  const MarcadorOnline({super.key, required this.scores, this.ownId});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      key: const ValueKey('marcador_online'),
      scrollDirection: Axis.horizontal,
      itemCount: scores.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final s = scores[i];
        return Chip(
          label: Text(
            '${s['memberId'] == ownId ? 'Tú' : s['username']}: ${s['points']} pts${s['abandoned'] == 1 ? ' · salió' : ''}',
          ),
          labelStyle: const TextStyle(fontSize: 13),
          visualDensity: VisualDensity.compact,
        );
      },
    ),
  );
}

/// Estado compartido de cierre/votación; las animaciones finales llegan en fase 6.
class EstadoPartidaOnline extends StatelessWidget {
  final OnlineMatch game;
  final LobbySnapshot lobby;
  final RoomsState state;
  final RoomsCubit rooms;
  const EstadoPartidaOnline({
    super.key,
    required this.game,
    required this.lobby,
    required this.state,
    required this.rooms,
  });
  @override
  Widget build(BuildContext context) {
    final ownId = lobby.members
        .where((m) => m.userId == rooms.auth.state.session?.user.id)
        .firstOrNull
        ?.id;
    final result = game.result;
    if (result != null) {
      final ranking = (result['ranking'] as List).cast<Map<String, dynamic>>();
      final winner = ranking
          .where((p) => p['memberId'] == result['winnerMemberId'])
          .firstOrNull;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            winner == null
                ? 'Partida finalizada'
                : '${winner['username']} ganó',
            key: const ValueKey('resultado_online'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(switch (result['reason']) {
            'TARGET' => 'Meta alcanzada',
            'END_VOTE' => 'Finalizada por votación',
            'ABANDONMENT' => 'Victoria por abandono',
            _ => 'Sin participantes',
          }, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          for (final p in ranking)
            ListTile(
              leading: Text('${p['position']}.º'),
              title: Text(
                '${p['username']}${p['memberId'] == ownId ? ' · Tú' : ''}',
              ),
              subtitle: Text(
                '${p['completedZones']} ${p['completedZones'] == 1 ? 'zona' : 'zonas'}${p['abandoned'] == 1 ? ' · Abandonó' : ''}',
              ),
              trailing: Text('${p['points']} pts'),
            ),
          const SizedBox(height: 12),
          const Text(
            'Usa la flecha de regreso para salir de la sala.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    final vote = game.endVote!;
    final ballots = (vote['ballots'] as List).cast<Map<String, dynamic>>();
    final ownVote = ballots.where((b) => b['memberId'] == ownId).firstOrNull;
    final yes = ballots.where((b) => b['approve'] == 1).length;
    final enabled =
        state.channelConnected &&
        !state.busy &&
        !state.uncertain &&
        ownVote == null &&
        (state.secondsRemaining ?? 0) > 0;
    final horizontal = MediaQuery.sizeOf(context).width > 600;
    final buttons = [
      FilledButton(
        key: const ValueKey('votar_finalizar_online'),
        onPressed: enabled
            ? () => rooms.castBallot(game.id, vote['id'] as String, true)
            : null,
        child: const Text('Finalizar'),
      ),
      OutlinedButton(
        key: const ValueKey('votar_continuar_online'),
        onPressed: enabled
            ? () => rooms.castBallot(game.id, vote['id'] as String, false)
            : null,
        child: const Text('Continuar'),
      ),
    ];
    return ListView(
      padding: EdgeInsets.all(horizontal ? 8 : 20),
      children: [
        Text(
          '¿Finalizar la partida?',
          key: const ValueKey('votacion_online'),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Nadie pudo colocar en tres rondas. Si se aprueba, gana el primero del marcador.',
        ),
        Text(
          '$yes a favor · se necesitan ${vote['required']}',
          key: const ValueKey('mayoria_online'),
        ),
        if (ownVote != null)
          Text(
            ownVote['approve'] == 1
                ? 'Tu voto: finalizar'
                : 'Tu voto: continuar',
          ),
        const SizedBox(height: 12),
        if (horizontal)
          Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 12),
              Expanded(child: buttons[1]),
            ],
          )
        else ...[
          buttons[0],
          const SizedBox(height: 8),
          buttons[1],
        ],
        const SizedBox(height: 16),
        for (final s in game.scores)
          ListTile(
            title: Text('${s['username']}'),
            trailing: Text('${s['points']} pts'),
          ),
      ],
    );
  }
}
