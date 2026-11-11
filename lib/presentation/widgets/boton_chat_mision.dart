import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../multiplayer/rooms_cubit.dart';

class BotonChatMision extends StatefulWidget {
  final RoomsState state;
  final String? ownId;
  final bool compact, abierto;
  final VoidCallback onPressed;
  const BotonChatMision({
    super.key,
    required this.state,
    required this.ownId,
    required this.onPressed,
    this.compact = false,
    this.abierto = false,
  });
  @override
  State<BotonChatMision> createState() => _BotonChatMisionState();
}

class _BotonChatMisionState extends State<BotonChatMision>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  int _lastSequence = 0;
  int latest() =>
      widget.state.messages.fold(0, (n, m) => math.max(n, m.sequence));
  @override
  void initState() {
    super.initState();
    _lastSequence = latest();
  }

  @override
  void didUpdateWidget(BotonChatMision oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.lobby?.id != oldWidget.state.lobby?.id) {
      _lastSequence = latest();
      _shake.stop();
      _shake.value = 0;
      return;
    }
    final received = widget.state.messages.any(
      (m) =>
          m.sequence > _lastSequence &&
          m.kind == 'PLAYER' &&
          m.authorId != widget.ownId,
    );
    _lastSequence = math.max(_lastSequence, latest());
    if (received && !widget.abierto) {
      HapticFeedback.lightImpact();
      if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shake.stop();
      _shake.value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Badge(
      isLabelVisible: widget.state.unread > 0,
      label: Text('${widget.state.unread}'),
      child: const Icon(Icons.chat_bubble_outline),
    );
    final button = widget.compact
        ? IconButton.filledTonal(
            key: const ValueKey('abrir_chat'),
            tooltip: 'Chat de la sala',
            onPressed: widget.onPressed,
            icon: badge,
          )
        : FloatingActionButton(
            key: const ValueKey('abrir_chat'),
            tooltip: 'Chat de la sala',
            onPressed: widget.onPressed,
            child: badge,
          );
    return AnimatedBuilder(
      animation: _shake,
      child: button,
      builder: (context, child) {
        final wave = math.sin(_shake.value * math.pi * 12) * (1 - _shake.value);
        return Transform.translate(
          offset: Offset(wave * 3, 0),
          child: Transform.rotate(angle: wave * .16, child: child),
        );
      },
    );
  }
}
