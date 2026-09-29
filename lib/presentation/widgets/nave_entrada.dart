import 'package:flutter/material.dart';

class NaveEntrada extends StatefulWidget {
  final bool llegando;
  final VoidCallback onCompletada;
  final Widget child;

  const NaveEntrada({super.key, required this.llegando, required this.onCompletada, required this.child});

  @override
  State<NaveEntrada> createState() => _NaveEntradaState();
}

class _NaveEntradaState extends State<NaveEntrada> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) _notificar();
  });
  bool _notificada = false;

  void _notificar() {
    if (!widget.llegando || _notificada) return;
    _notificada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompletada();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizar();
  }

  @override
  void didUpdateWidget(NaveEntrada oldWidget) {
    super.didUpdateWidget(oldWidget);
    _actualizar();
  }

  void _actualizar() {
    if (!widget.llegando || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _notificar();
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -240 * (1 - Curves.easeOutBack.transform(_controller.value))),
        child: Opacity(opacity: Curves.easeOut.transform(_controller.value), child: child),
      ),
    );
  }
}
