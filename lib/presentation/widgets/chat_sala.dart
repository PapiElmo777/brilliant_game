import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../multiplayer/rooms_cubit.dart';
import '../../multiplayer/rooms_repository.dart';
import 'panel_galactico.dart';

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
      listenWhen: (a, b) =>
          !identical(a.messages, b.messages) || a.chatDraft != b.chatDraft,
      listener: (context, state) {
        if (state.chatDraft.isEmpty && draft.text.isNotEmpty) draft.clear();
        if (!_scroll.hasClients || _scroll.position.extentAfter < 80) {
          _followLatest();
        }
      },
      buildWhen: (a, b) =>
          !identical(a.messages, b.messages) ||
          a.channelConnected != b.channelConnected ||
          a.error != b.error ||
          a.uncertain != b.uncertain ||
          a.busy != b.busy ||
          a.loadingHistory != b.loadingHistory ||
          a.hasMoreHistory != b.hasMoreHistory ||
          a.chatCooldown != b.chatCooldown,
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = math.min(
                MediaQuery.sizeOf(context).height * .82,
                constraints.maxHeight,
              );
              final compact = height < 320;
              final ownId = state.lobby?.members
                  .where((m) => m.userId == rooms.auth.state.session?.user.id)
                  .firstOrNull
                  ?.id;
              return SizedBox(
                height: height,
                child: PanelGalactico(
                  child: Column(
                    children: [
                      CabeceraGalactica(
                        title: 'Chat de la sala',
                        caption: 'CANAL DE ESCUADRÓN',
                        icon: Icons.forum_outlined,
                        closeLabel: 'Cerrar chat',
                        closeKey: const ValueKey('cerrar_chat'),
                        compact: compact,
                      ),
                      const Divider(height: 1, color: Color(0x225ACDE5)),
                      if (!state.channelConnected)
                        const Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Reconectando… Los mensajes se podrán enviar al recuperar la sala.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: oroGalactico,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          itemCount: state.messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
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
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  if (state.messages.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.satellite_alt_rounded,
                                            color: Color(0xFF56778D),
                                            size: 30,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Todavía no hay mensajes.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF96AFC1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }
                            final message = state.messages[index - 1];
                            return _MensajeChat(
                              message: message,
                              own: message.authorId == ownId && ownId != null,
                            );
                          },
                        ),
                      ),
                      if (state.error != null)
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                  color: Color(0xFFFFB4AB),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (state.uncertain)
                        Flexible(
                          child: SingleChildScrollView(
                            child: TextButton(
                              onPressed: state.busy ? null : rooms.retry,
                              child: const Text('Reintentar operación'),
                            ),
                          ),
                        ),
                      Flexible(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B2032),
                              border: Border(
                                top: BorderSide(color: Color(0x225ACDE5)),
                              ),
                            ),
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
                                    maxLines: compact ? 1 : 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'Mensaje',
                                      hintText: 'Transmite al escuadrón…',
                                      filled: true,
                                      fillColor: const Color(0xFF132E42),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                      counterStyle: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF7795A9),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0x334F819B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  key: const ValueKey('enviar_chat'),
                                  tooltip: state.chatCooldown > 0
                                      ? 'Espera ${state.chatCooldown} segundos'
                                      : 'Enviar mensaje',
                                  style: IconButton.styleFrom(
                                    backgroundColor: cianHolograma,
                                    foregroundColor: tintaEspacial,
                                    minimumSize: const Size(48, 48),
                                  ),
                                  onPressed:
                                      !state.channelConnected ||
                                          state.busy ||
                                          state.uncertain ||
                                          state.chatCooldown > 0
                                      ? null
                                      : () => rooms.sendMessage(draft.text),
                                  icon: const Icon(Icons.arrow_upward_rounded),
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
            },
          ),
        ),
      ),
    );
  }
}

class _MensajeChat extends StatelessWidget {
  final RoomMessage message;
  final bool own;
  const _MensajeChat({required this.message, required this.own});
  @override
  Widget build(BuildContext context) {
    if (message.kind == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                Icons.sensors_rounded,
                color: Color(0xFFA9B9A9),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFFA9B9A9),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final time = message.time.toLocal();
    final stamp =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .9,
        child: Container(
          key: ValueKey('mensaje_${message.id}'),
          margin: EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: own ? 10 : 0,
            right: own ? 0 : 10,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: own ? const Color(0xFF123B4B) : const Color(0xFF142B3E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(own ? 16 : 4),
              bottomRight: Radius.circular(own ? 4 : 16),
            ),
            border: Border.all(
              color: own ? const Color(0x445DD8E6) : const Color(0x224F819B),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 2,
                children: [
                  Text(
                    own ? 'Tú' : message.authorName ?? 'Jugador',
                    style: const TextStyle(
                      fontSize: 11,
                      color: cianHolograma,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    stamp,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7F9BAD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Color(0xFFE8F3FC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
