import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth_cubit.dart';
import '../../auth/auth_repository.dart';
import '../../rankets/rankets_repository.dart';
import '../widgets/avatar_usuario.dart';

class RanketsPage extends StatefulWidget {
  final RanketsRepository repository;
  const RanketsPage({super.key, required this.repository});
  @override
  State<RanketsPage> createState() => _RanketsPageState();
}

class _RanketsPageState extends State<RanketsPage> {
  RanketsPageData? _data;
  bool _loading = true;
  int _request = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int offset = 0}) async {
    final request = ++_request;
    final auth = context.read<AuthCubit>();
    final session = auth.state.session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var data = await widget.repository.list(
        session.accessToken,
        offset: offset,
      );
      if (!mounted || request != _request) return;
      if (data.entries.isEmpty && data.total > 0 && offset >= data.total) {
        data = await widget.repository.list(session.accessToken, offset: 0);
        if (!mounted || request != _request) return;
      }
      setState(() => _data = data);
    } on AuthFailure catch (error) {
      if (!mounted || request != _request) return;
      if (error.invalidSession) {
        auth.invalidate();
      } else {
        setState(
          () => _error = error.status == 404
              ? 'Actualiza el servidor para consultar Rankets.'
              : error.message,
        );
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(
          () => _error = 'No se pudo cargar el ranking. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final ownId = context.read<AuthCubit>().state.session?.user.id;
    return Scaffold(
      backgroundColor: const Color(0xFF00102F),
      appBar: AppBar(
        title: const Text('Rankets'),
        actions: [
          IconButton(
            tooltip: 'Actualizar ranking',
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            key: const PageStorageKey('rankets_list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 56,
                        color: Color(0xFFFFD570),
                      ),
                      const Text(
                        'Los mejores jugadores',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ordenados por victorias multijugador.\nLas victorias de todos los niveles cuentan por igual.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          semanticsLabel: _error,
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : () => _load(offset: data?.offset ?? 0),
                            child: const Text('Reintentar'),
                          ),
                        ),
                      ],
                      if (data != null && !_loading && _error == null) ...[
                        if (data.me != null) ...[
                          const Text(
                            'Tu posición',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _PlayerCard(player: data.me!, own: true),
                          const SizedBox(height: 16),
                        ] else ...[
                          const Text(
                            'Juega una partida multijugador para aparecer en Rankets.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (data.total == 0)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Todavía no hay jugadores en el ranking.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        else ...[
                          Text(
                            '${data.total} jugadores',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          for (final player in data.entries)
                            _PlayerCard(
                              player: player,
                              own: player.userId == ownId,
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: data.offset == 0
                                    ? null
                                    : () => _load(
                                        offset: (data.offset - 25).clamp(
                                          0,
                                          data.total,
                                        ),
                                      ),
                                child: const Text('Anterior'),
                              ),
                              Text(
                                '${data.offset + 1}–${data.offset + data.entries.length} de ${data.total}',
                              ),
                              OutlinedButton(
                                onPressed:
                                    data.offset + data.entries.length >=
                                        data.total
                                    ? null
                                    : () => _load(offset: data.offset + 25),
                                child: const Text('Siguiente'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final RankedPlayer player;
  final bool own;
  const _PlayerCard({required this.player, required this.own});
  @override
  Widget build(BuildContext context) => Card(
    color: own ? const Color(0xFF123F69) : const Color(0xFF082541),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: own ? const Color(0xFF55DFFF) : const Color(0xFF16405A),
      ),
    ),
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarUsuario(avatarId: player.avatarId, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${player.position} · ${player.username}${own ? ' (Tú)' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${player.wins} ${player.wins == 1 ? 'victoria' : 'victorias'}',
                      style: const TextStyle(
                        color: Color(0xFFFFD570),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (player.position <= 3)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: switch (player.position) {
                      1 => const Color(0xFFFFD570),
                      2 => const Color(0xFFD0DBE5),
                      _ => const Color(0xFFDAA074),
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 1; i <= 4; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001A34),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Nivel $i: ${player.winsByLevel['tablero_0$i'] ?? 0}',
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
