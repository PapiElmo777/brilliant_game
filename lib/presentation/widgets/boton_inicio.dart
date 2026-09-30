import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tema_brilliant.dart';
import 'boton_panel.dart';

/// Botón `INICIO`: entra desde abajo con un pequeño rebote y emite dos
/// pulsos de resplandor para llamar la atención sin repetirse indefinidamente.
class BotonInicio extends StatefulWidget {
  final VoidCallback onPressed;

  const BotonInicio({super.key, required this.onPressed});

  @override
  State<BotonInicio> createState() => _BotonInicioState();
}

class _BotonInicioState extends State<BotonInicio>
    with SingleTickerProviderStateMixin {
  static const _entrada = Interval(0, .4, curve: Curves.easeOutBack);
  static const _pulsos = Interval(.4, 1);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
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
    child: BotonPanel(
      key: const ValueKey('boton_inicio'),
      texto: 'INICIO',
      icono: Icons.rocket_launch_rounded,
      onPressed: widget.onPressed,
    ),
    builder: (context, child) {
      final entrada = _entrada.transform(_controller.value);
      final pulso = math
          .sin(_pulsos.transform(_controller.value) * math.pi * 2)
          .abs();
      return Opacity(
        opacity: entrada.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 90 * (1 - entrada)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: ColoresBrilliant.cian.withValues(alpha: .55 * pulso),
                  blurRadius: 12 + 24 * pulso,
                  spreadRadius: 6 * pulso,
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    },
  );
}
