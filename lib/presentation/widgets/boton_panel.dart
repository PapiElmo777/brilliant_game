import 'package:flutter/material.dart';

import '../../app/tema_brilliant.dart';

/// Botón principal con apariencia de panel tecnológico: esquinas biseladas,
/// contorno cian luminoso y marcas en las esquinas.
class BotonPanel extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback? onPressed;

  const BotonPanel({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  static const _forma = BeveledRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    side: BorderSide(color: ColoresBrilliant.cian, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null;
    return AnimatedOpacity(
      opacity: activo ? 1 : .5,
      duration: const Duration(milliseconds: 150),
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: _forma,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E5A78), Color(0xFF0C2640), Color(0xFF123A57)],
            stops: [0, .55, 1],
          ),
          shadows: [
            BoxShadow(
              color: Color(0x5572E9FF),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: const _MarcasPanelPainter(),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                shape: _forma.copyWith(side: BorderSide.none),
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFFE2F9FF),
                disabledForegroundColor: const Color(0xFFE2F9FF),
                overlayColor: ColoresBrilliant.cian,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              icon: Icon(icono, color: ColoresBrilliant.cian),
              label: Text(texto),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarcasPanelPainter extends CustomPainter {
  const _MarcasPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = const Color(0xFFB6F6FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const largo = 12.0;
    const margen = 6.0;
    // Marcas cortas centradas en los bordes superior e inferior.
    final centro = size.width / 2;
    canvas.drawLine(
      Offset(centro - largo * 2, margen / 2),
      Offset(centro + largo * 2, margen / 2),
      pintura,
    );
    canvas.drawLine(
      Offset(centro - largo, size.height - margen / 2),
      Offset(centro + largo, size.height - margen / 2),
      pintura,
    );
    // Indicadores laterales.
    pintura.strokeWidth = 3;
    for (final x in [margen + 4, size.width - margen - 4]) {
      canvas.drawLine(
        Offset(x, size.height / 2 - 6),
        Offset(x, size.height / 2 + 6),
        pintura,
      );
    }
  }

  @override
  bool shouldRepaint(_MarcasPanelPainter oldDelegate) => false;
}
