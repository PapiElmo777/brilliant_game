import 'dart:math' as math;
import 'package:flutter/material.dart';

class FondoEspacial extends StatelessWidget {
  final Widget child;
  final String? ruta;
  final bool numeroEnContenido;
  const FondoEspacial({
    super.key,
    required this.child,
    this.ruta,
    this.numeroEnContenido = false,
  });

  static double altoNumero(double ancho) => ancho * 145 / 841;

  @override
  Widget build(BuildContext context) {
    if (ruta != null) {
      return ColoredBox(
        color: const Color(0xFF071226),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: numeroEnContenido
                    ? _RecorteFondo(ruta: ruta!, numero: false)
                    : Image.asset(
                        ruta!,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        color: const Color(0x38000000),
                        colorBlendMode: BlendMode.darken,
                        excludeFromSemantics: true,
                      ),
              ),
            ),
            child,
          ],
        ),
      );
    }
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

// Se encuadran dos partes del mismo recurso: el número acompaña a la nave
// y el paisaje permanece fijo, sin repetir el número detrás del contenido.
class _RecorteFondo extends StatelessWidget {
  final String ruta;
  final bool numero;
  final bool compacto;
  const _RecorteFondo({
    required this.ruta,
    required this.numero,
    this.compacto = false,
  });
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      width: numero && compacto ? 300 : 841,
      height: numero ? (compacto ? 100 : 145) : 1725,
      child: ClipRect(
        child: OverflowBox(
          alignment: numero ? Alignment.topCenter : Alignment.bottomCenter,
          minWidth: 841,
          maxWidth: 841,
          minHeight: 1870,
          maxHeight: 1870,
          child: Transform.translate(
            offset: Offset(0, numero && compacto ? -24 : 0),
            child: Image.asset(
              ruta,
              width: 841,
              height: 1870,
              fit: BoxFit.fill,
              color: const Color(0x38000000),
              colorBlendMode: BlendMode.darken,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}

class NumeroFondoNivel extends StatelessWidget {
  final String? ruta;
  final bool compacto;
  const NumeroFondoNivel({
    super.key,
    required this.ruta,
    this.compacto = false,
  });
  @override
  Widget build(BuildContext context) {
    if (ruta == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: AspectRatio(
        key: const ValueKey('numero_fondo_nivel'),
        aspectRatio: compacto ? 3 : 841 / 145,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0, .08, .95, 1],
          ).createShader(rect),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0, .08, .95, 1],
            ).createShader(rect),
            child: _RecorteFondo(ruta: ruta!, numero: true, compacto: compacto),
          ),
        ),
      ),
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
