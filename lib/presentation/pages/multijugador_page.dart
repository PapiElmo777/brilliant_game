import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth_cubit.dart';
import '../widgets/chat_sala.dart';
import '../widgets/partida_en_linea.dart';
import '../../catalogo/catalogo_tableros.dart';
import '../../core/marcador.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';

class MultijugadorPage extends StatefulWidget {
  final RoomsRepository repository;
  final bool closeRepository;
  const MultijugadorPage({
    super.key,
    required this.repository,
    this.closeRepository = false,
  });
  @override
  State<MultijugadorPage> createState() => _MultijugadorPageState();
}

class _MultijugadorPageState extends State<MultijugadorPage>
    with WidgetsBindingObserver {
  late final RoomsCubit _rooms;
  bool _askingLeave = false;
  final _chatDraft = TextEditingController();
  bool _chatOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rooms = RoomsCubit(widget.repository, context.read<AuthCubit>())
      ..refresh()
      ..startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rooms.refresh();
      _rooms.startPolling();
    } else {
      _rooms.pausePolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rooms.close();
    _chatDraft.dispose();
    if (widget.closeRepository) widget.repository.close();
    super.dispose();
  }

  Future<void> _leave({bool toMenu = false}) async {
    if (_askingLeave || _rooms.state.busy) return;
    if (_rooms.state.uncertain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reintenta la operación pendiente antes de salir.'),
        ),
      );
      return;
    }
    _askingLeave = true;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Salir de la sala?'),
        content: const Text(
          'Dejarás de ocupar un lugar. Si eres el anfitrión, otro jugador asumirá el rol.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirmar_salida_sala'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    _askingLeave = false;
    if (accepted == true && mounted) {
      await _rooms.leave();
      if (toMenu) {
        await WidgetsBinding.instance.endOfFrame;
        if (mounted && _rooms.state.lobby == null) {
          Navigator.maybePop(context);
        }
      }
    }
  }

  Future<void> _showChat() async {
    if (_chatOpen) return;
    _chatOpen = true;
    _chatDraft.text = _rooms.state.chatDraft;
    _rooms.setChatOpen(true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatSala(rooms: _rooms, draft: _chatDraft),
    );
    _chatOpen = false;
    if (mounted && !_rooms.isClosed) _rooms.setChatOpen(false);
  }

  Future<void> _create() async {
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => const _CrearSalaDialog(),
    );
    if (result != null && mounted) await _rooms.create(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<RoomsCubit, RoomsState>(
    bloc: _rooms,
    buildWhen: (previous, current) =>
        !identical(previous.lobby, current.lobby) ||
        !identical(previous.rooms, current.rooms) ||
        !identical(previous.messages, current.messages) ||
        previous.busy != current.busy ||
        previous.loading != current.loading ||
        previous.uncertain != current.uncertain ||
        previous.error != current.error ||
        previous.channelConnected != current.channelConnected ||
        previous.connecting != current.connecting ||
        previous.unread != current.unread ||
        previous.chatCooldown != current.chatCooldown ||
        previous.loadingHistory != current.loadingHistory ||
        previous.hasMoreHistory != current.hasMoreHistory ||
        previous.chatDraft != current.chatDraft ||
        (previous.secondsRemaining == 0) != (current.secondsRemaining == 0) ||
        // Las pantallas de votación conservan su contador actual.
        current.lobby?.match?['state'] == 'END_VOTE',
    listener: (context, state) {
      if (state.lobby == null && _chatOpen) Navigator.of(context).pop();
    },
    builder: (context, state) {
      final lobby = state.lobby;
      final userId = context.read<AuthCubit>().state.session?.user.id;
      final own = lobby?.members.where((m) => m.userId == userId).firstOrNull;
      final host = own != null && own.id == lobby?.hostId;
      final enabled =
          !state.busy &&
          !state.uncertain &&
          (lobby == null || state.channelConnected);
      final inLobby = lobby?.state == 'LOBBY';
      final game = lobby?.match == null
          ? null
          : OnlineMatch.fromJson(lobby!.match!);
      final mission =
          game != null &&
          (game.state == 'PREPARING' || game.state == 'ROUND_ACTIVE');
      final ownScore = game?.scores
          .where((s) => s['memberId'] == own?.id)
          .firstOrNull;
      return PopScope(
        canPop: lobby == null && !state.busy && !state.uncertain,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && lobby != null) _leave();
        },
        child: Scaffold(
          appBar: mission
              ? null
              : AppBar(
                  title: Text(lobby?.name ?? 'Multijugador'),
                  bottom:
                      game == null ||
                          game.state == 'FINISHED' ||
                          (game.round == null && game.state != 'END_VOTE')
                      ? null
                      : PreferredSize(
                          preferredSize: const Size.fromHeight(36),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: FittedBox(
                              child: Text(
                                game.state == 'END_VOTE'
                                    ? 'Votación · ${state.secondsRemaining ?? 0} s'
                                    : 'Ronda ${game.round!.number} · ${state.secondsRemaining ?? 0} s',
                                key: const ValueKey('reloj_online'),
                              ),
                            ),
                          ),
                        ),
                  leading: BackButton(
                    onPressed: () {
                      if (lobby == null) {
                        Navigator.maybePop(context);
                      } else {
                        _leave();
                      }
                    },
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: state.busy ? null : _rooms.refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    if (lobby != null && !state.channelConnected)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Reconectando con la sala…',
                          key: ValueKey('estado_canal'),
                        ),
                      ),
                    if (state.busy || state.loading)
                      const LinearProgressIndicator(),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                state.error!,
                                key: const ValueKey('error_sala'),
                              ),
                            ),
                            if (state.uncertain)
                              FilledButton(
                                onPressed: state.busy ? null : _rooms.retry,
                                child: const Text('Reintentar operación'),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: lobby == null
                          ? _list(state, enabled)
                          : game == null
                          ? _lobby(lobby, host && enabled && inLobby, userId)
                          : PartidaEnLinea(
                              key: ValueKey(game.id),
                              lobby: lobby,
                              state: state,
                              rooms: _rooms,
                              onExit: () => _leave(toMenu: true),
                              onBack: () => _leave(),
                              chatButton: _chatButton(state, compact: true),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: lobby == null || mission
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: inLobby
                              ? FilledButton.icon(
                                  key: ValueKey(
                                    host ? 'iniciar_sala' : 'listo_sala',
                                  ),
                                  onPressed: !enabled || own == null
                                      ? null
                                      : host
                                      ? lobby.members.length >= 2 &&
                                                lobby.levelId != null &&
                                                lobby.members.every(
                                                  (m) =>
                                                      m.connected &&
                                                      (m.id == lobby.hostId ||
                                                          m.ready),
                                                )
                                            ? _rooms.startMatch
                                            : null
                                      : () => _rooms.ready(!own.ready),
                                  icon: Icon(
                                    host
                                        ? Icons.rocket_launch
                                        : own?.ready == true
                                        ? Icons.undo
                                        : Icons.check,
                                  ),
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      host
                                          ? 'Iniciar partida'
                                          : own?.ready == true
                                          ? 'Quitar Listo'
                                          : 'Listo',
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (ownScore != null &&
                                        game?.result == null)
                                      Text(
                                        '${ownScore['points']} / ${game!.target} puntos',
                                        key: const ValueKey(
                                          'puntos_propios_online',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    if (ownScore == null ||
                                        game?.result != null ||
                                        game?.state == 'END_VOTE' ||
                                        game?.round?.ownAction != null ||
                                        game?.round == null)
                                      Text(
                                        game?.result != null
                                            ? 'Partida finalizada'
                                            : game?.state == 'END_VOTE'
                                            ? 'Rondas en pausa'
                                            : game?.round?.ownAction != null
                                            ? 'Ronda resuelta · esperando'
                                            : game?.prepared == true &&
                                                  game?.round == null
                                            ? 'Preparación confirmada'
                                            : 'Meta ${lobby.match?['target'] ?? ''} puntos',
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 12),
                        _chatButton(state),
                      ],
                    ),
                  ),
                ),
        ),
      );
    },
  );
  Widget _chatButton(RoomsState state, {bool compact = false}) => compact
      ? IconButton.filledTonal(
          key: const ValueKey('abrir_chat'),
          tooltip: 'Chat de la sala',
          onPressed: _showChat,
          icon: Badge(
            isLabelVisible: state.unread > 0,
            label: Text('${state.unread}'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
        )
      : FloatingActionButton(
          key: const ValueKey('abrir_chat'),
          tooltip: 'Chat de la sala',
          onPressed: _showChat,
          child: Badge(
            isLabelVisible: state.unread > 0,
            label: Text('${state.unread}'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
        );
  Widget _list(RoomsState state, bool enabled) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      FilledButton.icon(
        key: const ValueKey('alojar_partida'),
        onPressed: enabled && !state.loading ? _create : null,
        icon: const Icon(Icons.add),
        label: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Alojar partida'),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Partidas disponibles',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      if (state.rooms.isEmpty && !state.loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No hay salas disponibles. Aloja una partida para invitar a otros jugadores.',
            textAlign: TextAlign.center,
          ),
        ),
      for (final room in state.rooms)
        Card(
          child: ListTile(
            title: Text(room['name'] as String),
            subtitle: Text(
              'Anfitrión: ${room['hostName']}\n${room['occupancy']}/${room['capacity']} jugadores · ${_levelName(room['levelId'] as String?)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              key: ValueKey('unirse_${room['id']}'),
              tooltip: 'Entrar a la sala',
              icon: const Icon(Icons.login),
              onPressed:
                  enabled &&
                      (room['occupancy'] as int) < (room['capacity'] as int)
                  ? () => _rooms.join(room['id'] as String)
                  : null,
            ),
          ),
        ),
    ],
  );
  String _levelName(String? id) => id == null
      ? 'Sin nivel elegido'
      : CatalogoTableros.predeterminado().obtenerDefinicion(id).nombre!;
  Widget _lobby(LobbySnapshot lobby, bool canConfigure, String? userId) {
    final host = lobby.members.where((m) => m.id == lobby.hostId).firstOrNull;
    return ListView(
      key: const ValueKey('contenido_lobby'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Anfitrión: ${host?.name ?? '—'}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          '${lobby.members.length}/${lobby.capacity} jugadores · Meta ${lobby.match?['target'] ?? (lobby.members.length >= 2 ? metaDePuntos(lobby.members.length) : 'por definir')}',
        ),
        const SizedBox(height: 16),
        if (lobby.state == 'LOBBY')
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Capacidad máxima'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: const ValueKey('capacidad_sala'),
                value: lobby.capacity,
                isExpanded: true,
                items: [
                  for (var i = 2; i <= 6; i++)
                    DropdownMenuItem(
                      value: i,
                      enabled: i >= lobby.members.length,
                      child: Text('$i jugadores'),
                    ),
                ],
                onChanged: !canConfigure
                    ? null
                    : (value) {
                        if (value != null && value != lobby.capacity) {
                          _rooms.capacity(value);
                        }
                      },
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          lobby.state == 'LOBBY' ? 'Elige el nivel' : 'Preparando la misión',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            crossAxisCount: constraints.maxWidth >= 650 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .95,
            children: [
              for (final level
                  in CatalogoTableros.predeterminado().definiciones.values)
                Semantics(
                  selected: lobby.levelId == level.id,
                  button: true,
                  label: level.nombre,
                  child: Card(
                    color: lobby.levelId == level.id
                        ? const Color(0xFF514415)
                        : const Color(0xFF24303D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: lobby.levelId == level.id
                            ? Colors.amber
                            : Colors.grey,
                        width: lobby.levelId == level.id ? 3 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('sala_${level.id}'),
                      onTap: canConfigure
                          ? () => _rooms.settings(lobby.capacity, level.id)
                          : null,
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                level.recursos!.miniatura,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: FittedBox(
                              child: Text(
                                level.nombre!,
                                maxLines: 1,
                                style: TextStyle(
                                  color: lobby.levelId == level.id
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (lobby.state == 'LOBBY')
          OutlinedButton.icon(
            key: const ValueKey('nivel_aleatorio_sala'),
            onPressed: canConfigure ? _rooms.randomLevel : null,
            icon: const Icon(Icons.shuffle),
            label: const Text('Nivel aleatorio'),
          ),
        const SizedBox(height: 20),
        const Text(
          'Participantes',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        for (final member in lobby.members)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  member.id == lobby.hostId
                      ? Icons.star
                      : member.ready
                      ? Icons.check_circle
                      : Icons.person_outline,
                  color: member.id == lobby.hostId
                      ? Colors.amber
                      : member.ready
                      ? Colors.greenAccent
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${member.name}${member.userId == userId ? ' (tú)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${member.id == lobby.hostId
                            ? 'Anfitrión'
                            : member.ready
                            ? 'Listo'
                            : 'Sin confirmar'} · ${member.connected ? 'Conectado' : 'Reconectando'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _rooms.state.busy ? null : _leave,
          icon: const Icon(Icons.logout),
          label: const Text('Salir de la sala'),
        ),
      ],
    );
  }
}

class _CrearSalaDialog extends StatefulWidget {
  const _CrearSalaDialog();
  @override
  State<_CrearSalaDialog> createState() => _CrearSalaDialogState();
}

class _CrearSalaDialogState extends State<_CrearSalaDialog> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  int _capacity = 6;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Alojar partida'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('nombre_sala'),
              controller: _name,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Nombre del servidor',
              ),
              validator: (name) => name == null || name.trim().isEmpty
                  ? 'Escribe un nombre para la sala.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _capacity,
              decoration: const InputDecoration(labelText: 'Capacidad máxima'),
              items: [
                for (var i = 2; i <= 6; i++)
                  DropdownMenuItem(value: i, child: Text('$i jugadores')),
              ],
              onChanged: (n) => setState(() => _capacity = n!),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('crear_sala'),
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (_name.text.trim(), _capacity));
          }
        },
        child: const Text('Crear sala'),
      ),
    ],
  );
}
