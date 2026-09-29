import 'package:flutter/material.dart';

class NaveMarciano extends StatelessWidget {
  const NaveMarciano({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Marciano a bordo de su nave espacial',
      child: const AspectRatio(
        aspectRatio: 1.65,
        child: CustomPaint(painter: _NavePainter()),
      ),
    );
  }
}

class _NavePainter extends CustomPainter {
  const _NavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 182);
    final pintura = Paint();
    final haz = Path()..moveTo(122, 122)..lineTo(77, 182)..lineTo(223, 182)..lineTo(178, 122)..close();
    pintura.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x5572E9FF), Color(0x0072E9FF)],
    ).createShader(const Rect.fromLTWH(77, 122, 146, 60));
    canvas.drawPath(haz, pintura);
    pintura.shader = const RadialGradient(
      colors: [Color(0x6672E9FF), Color(0x0072E9FF)],
    ).createShader(const Rect.fromLTWH(10, 55, 280, 110));
    canvas.drawOval(const Rect.fromLTWH(10, 55, 280, 110), pintura);
    pintura.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF448C9B), Color(0xFF102B4A)],
    ).createShader(const Rect.fromLTWH(87, 17, 126, 100));
    canvas.drawOval(const Rect.fromLTWH(87, 17, 126, 100), pintura);
    pintura.shader = null;
    pintura.color = const Color(0xFFACF0A2);
    canvas.drawOval(const Rect.fromLTWH(121, 42, 58, 58), pintura);
    pintura.color = const Color(0xFF0D2938);
    canvas.drawOval(const Rect.fromLTWH(129, 61, 15, 22), pintura);
    canvas.drawOval(const Rect.fromLTWH(156, 61, 15, 22), pintura);
    pintura.color = const Color(0xFFE9FFF2);
    canvas.drawCircle(const Offset(134, 66), 3, pintura);
    canvas.drawCircle(const Offset(161, 66), 3, pintura);
    pintura.color = const Color(0x8872E9FF);
    pintura.style = PaintingStyle.stroke;
    pintura.strokeWidth = 2;
    canvas.drawArc(const Rect.fromLTWH(87, 17, 126, 100), 3.3, 2.6, false, pintura);
    pintura.style = PaintingStyle.fill;
    pintura.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFBBDDE5), Color(0xFF37617B), Color(0xFF142E4C)],
      stops: [0, .48, 1],
    ).createShader(const Rect.fromLTWH(35, 85, 230, 52));
    canvas.drawOval(const Rect.fromLTWH(35, 85, 230, 52), pintura);
    pintura.shader = null;
    pintura.color = const Color(0xFF72E9FF);
    pintura.style = PaintingStyle.stroke;
    pintura.strokeWidth = 3;
    canvas.drawArc(const Rect.fromLTWH(35, 85, 230, 52), .15, 2.85, false, pintura);
    pintura.style = PaintingStyle.fill;
    for (final x in [76.0, 111.0, 150.0, 189.0, 224.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 113), width: 12, height: 5), pintura);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NavePainter oldDelegate) => false;
}
