import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'panel_galactico.dart';

/// Entrada finita del podio: salto estelar y una insignia de piloto holográfica.
class InsigniaResultado extends StatefulWidget {
  final bool ganador;
  final int? puesto;
  const InsigniaResultado({
    super.key,
    required this.ganador,
    required this.puesto,
  });
  @override
  State<InsigniaResultado> createState() => _InsigniaResultadoState();
}

class _InsigniaResultadoState extends State<InsigniaResultado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.stop();
      _entry.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _entry.forward();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.ganador ? oroGalactico : cianHolograma;
    return Container(
      key: ValueKey(widget.ganador ? 'insignia_ganador' : 'insignia_posicion'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .28)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF2132D40), Color(0xF0081629)],
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.ganador ? 'CAMPEÓN DE LA GALAXIA' : 'MISIÓN COMPLETADA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.2,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          RepaintBoundary(
            child: SizedBox(
              height: 188,
              width: double.infinity,
              child: CustomPaint(
                painter: _InsigniaPainter(_entry, color, widget.ganador),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _entry,
                    child: Semantics(
                      label: widget.puesto == null
                          ? 'Misión finalizada'
                          : 'Puesto ${widget.puesto}',
                      child: Text(
                        widget.puesto == null ? '—' : '${widget.puesto}.º',
                        key: const ValueKey('posicion_grande_online'),
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 94,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -6,
                          color: color,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: .4),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    builder: (context, child) => Transform.scale(
                      scale:
                          .82 +
                          .18 * Curves.easeOutCubic.transform(_entry.value),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            widget.ganador
                ? 'La Fuerza está contigo.'
                : 'Tu escuadrón te espera en la próxima misión.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF9EB5C7),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsigniaPainter extends CustomPainter {
  final Animation<double> entry;
  final Color color;
  final bool winner;
  _InsigniaPainter(this.entry, this.color, this.winner) : super(repaint: entry);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = Curves.easeOutCubic.transform(entry.value);
    final radius = math.min(74.0, size.width * .25);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Un salto al hiperespacio se apaga y deja las estrellas del podio.
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi * 2 / 24 + .13;
      final outer = radius + 8 + (i % 4) * 12 + 40 * t;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      final end =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (outer + (1 - t) * 34);
      p.color = color.withValues(alpha: .15 + (1 - t) * .35);
      canvas.drawLine(start, end, p);
      canvas.drawCircle(
        start,
        i % 3 == 0 ? 1.4 : .7,
        Paint()..color = color.withValues(alpha: .35),
      );
    }
    p.color = color.withValues(alpha: .22);
    canvas.drawCircle(center, radius, p);
    p.strokeWidth = 2;
    p.color = color.withValues(alpha: .65);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 5),
        t * math.pi * .65 + i * math.pi * 2 / 3,
        math.pi * .34,
        false,
        p,
      );
    }
    // Alas simétricas de una insignia de piloto, sin imágenes ni video extra.
    p.strokeWidth = 1.5;
    p.color = color.withValues(alpha: .4);
    for (final side in [-1.0, 1.0]) {
      for (var line = 0; line < 3; line++) {
        final start = center + Offset(side * (radius + 13), -12 + line * 12);
        canvas.drawLine(start, start + Offset(side * (21 - line * 5), -7), p);
      }
    }
    if (winner) {
      final crown = Path()
        ..moveTo(center.dx - 14, center.dy - radius + 6)
        ..lineTo(center.dx - 18, center.dy - radius - 5)
        ..lineTo(center.dx - 6, center.dy - radius)
        ..lineTo(center.dx, center.dy - radius - 12)
        ..lineTo(center.dx + 6, center.dy - radius)
        ..lineTo(center.dx + 18, center.dy - radius - 5)
        ..lineTo(center.dx + 14, center.dy - radius + 6)
        ..close();
      canvas.drawPath(crown, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_InsigniaPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.winner != winner ||
      oldDelegate.entry != entry;
}
