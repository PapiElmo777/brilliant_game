import 'dart:math' as math;

import 'package:flutter/material.dart';

class RespuestaError extends StatefulWidget {
  final Widget child;

  const RespuestaError({super.key, required this.child});

  @override
  State<RespuestaError> createState() => _RespuestaErrorState();
}

class _RespuestaErrorState extends State<RespuestaError> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(5 * math.sin(_controller.value * math.pi * 6) * (1 - _controller.value), 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFFFFB4AB).withValues(alpha: .3 * (1 - _controller.value)), blurRadius: 14)],
        ),
        child: child,
      ),
    ),
  );
}
