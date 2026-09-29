import 'dart:math' as math;

import 'package:flutter/material.dart';

class FondoEspacial extends StatelessWidget {
  final Widget child;

  const FondoEspacial({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050D20), Color(0xFF102C49), Color(0xFF091421)],
        ),
      ),
      child: CustomPaint(painter: _EscenarioPainter(), child: child),
    );
  }
}

class _EscenarioPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(27);
    final pintura = Paint();
    for (var i = 0; i < 100; i++) {
      final posicion = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * .85,
      );
      pintura.color = Colors.white.withValues(
        alpha: .15 + random.nextDouble() * .55,
      );
      canvas.drawCircle(posicion, i % 9 == 0 ? 1.5 : .7, pintura);
    }
    final planeta = Offset(size.width * .87, size.height * .16);
    pintura.shader = const RadialGradient(
      center: Alignment(-.5, -.5),
      colors: [Color(0xFF5B8291), Color(0xFF1A344A)],
    ).createShader(Rect.fromCircle(center: planeta, radius: 28));
    canvas.drawCircle(planeta, 28, pintura);
    pintura.shader = null;
    final suelo = Rect.fromLTWH(
      -size.width * .3,
      size.height - 75,
      size.width * 1.6,
      220,
    );
    pintura.color = const Color(0xFF22384B);
    canvas.drawOval(suelo, pintura);
    pintura.color = const Color(0xFF15283B);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .12, size.height - 35, 100, 24),
      pintura,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .72, size.height - 45, 58, 14),
      pintura,
    );
  }

  @override
  bool shouldRepaint(_EscenarioPainter oldDelegate) => false;
}
