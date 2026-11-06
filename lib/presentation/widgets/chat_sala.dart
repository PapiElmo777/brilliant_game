import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../multiplayer/rooms_cubit.dart';

class ChatSala extends StatefulWidget {
  final RoomsCubit rooms;
  final TextEditingController draft;
  const ChatSala({super.key, required this.rooms, required this.draft});
  @override
  State<ChatSala> createState() => _ChatSalaState();
}

class _ChatSalaState extends State<ChatSala> {
  final _scroll = ScrollController();
  void _followLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _followLatest();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.rooms, draft = widget.draft;
    return BlocConsumer<RoomsCubit, RoomsState>(
      bloc: rooms,
      listener: (context, state) {
        if (state.chatDraft.isEmpty && draft.text.isNotEmpty) draft.clear();
        if (!_scroll.hasClients || _scroll.position.extentAfter < 80) {
          _followLatest();
        }
      },
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .8,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chat de la sala',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('cerrar_chat'),
                        tooltip: 'Cerrar chat',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (!state.channelConnected)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Reconectando… Los mensajes se podrán enviar al recuperar la sala.',
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (state.hasMoreHistory)
                        TextButton(
                          onPressed: state.loadingHistory
                              ? null
                              : rooms.loadHistory,
                          child: Text(
                            state.loadingHistory
                                ? 'Cargando…'
                                : 'Ver mensajes anteriores',
                          ),
                        ),
                      if (state.messages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Todavía no hay mensajes.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final message in state.messages)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: message.kind == 'SYSTEM'
                              ? Text(
                                  message.text,
                                  style: TextStyle(
                                    color: Colors.amber.shade200,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15334D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.authorName ?? 'Jugador',
                                          style: const TextStyle(
                                            color: Color(0xFF72E9FF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(message.text),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
                if (state.error != null)
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(state.error!),
                      ),
                    ),
                  ),
                if (state.uncertain)
                  TextButton(
                    onPressed: state.busy ? null : rooms.retry,
                    child: const Text('Reintentar operación'),
                  ),
                Flexible(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('texto_chat'),
                              controller: draft,
                              onChanged: rooms.setDraft,
                              maxLength: 300,
                              minLines: 1,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Mensaje',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            key: const ValueKey('enviar_chat'),
                            tooltip: state.chatCooldown > 0
                                ? 'Espera ${state.chatCooldown} segundos'
                                : 'Enviar mensaje',
                            onPressed:
                                !state.channelConnected ||
                                    state.busy ||
                                    state.uncertain ||
                                    state.chatCooldown > 0
                                ? null
                                : () => rooms.sendMessage(draft.text),
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
