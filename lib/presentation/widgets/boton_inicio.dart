import 'package:flutter/material.dart';

import 'boton_panel.dart';

class BotonInicio extends StatelessWidget {
  final VoidCallback onPressed;

  const BotonInicio({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    child: BotonPanel(
      key: const ValueKey('boton_inicio'),
      texto: 'INICIO',
      icono: Icons.rocket_launch_rounded,
      onPressed: onPressed,
    ),
    builder: (context, progreso, child) => Opacity(
      opacity: progreso,
      child: Transform.scale(scale: .92 + .08 * progreso, child: child),
    ),
  );
}
