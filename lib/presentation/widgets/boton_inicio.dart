import 'package:flutter/material.dart';

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
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('boton_inicio'),
        onPressed: onPressed,
        icon: const Icon(Icons.rocket_launch_rounded),
        label: const Text('INICIO'),
      ),
    ),
    builder: (context, progreso, child) => Opacity(
      opacity: progreso,
      child: Transform.scale(scale: .92 + .08 * progreso, child: child),
    ),
  );
}
