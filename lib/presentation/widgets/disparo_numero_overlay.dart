import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bloc/inicio_estado.dart';

class DisparoNumeroOverlay extends StatefulWidget {
  final DisparoPendiente disparo;
  final GlobalKey origen;
  final GlobalKey destino;
  final VoidCallback onCompletado;

  const DisparoNumeroOverlay({
    super.key,
    required this.disparo,
    required this.origen,
    required this.destino,
    required this.onCompletado,
  });

  @override
  State<DisparoNumeroOverlay> createState() => _DisparoNumeroOverlayState();
}

class _DisparoNumeroOverlayState extends State<DisparoNumeroOverlay>
    with SingleTickerProviderStateMixin {
  final _lienzo = GlobalKey();
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 650),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _notificar();
      });
  bool _iniciado = false;
  bool _notificado = false;

  void _notificar() {
    if (_notificado) return;
    _notificado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompletado();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) {
      if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
      return;
    }
    _iniciado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
        WidgetsBinding.instance.scheduleFrame();
      } else {
        _controller.forward();
      }
    });
  }

  Offset? _posicion(GlobalKey key, RenderBox lienzo, {bool nave = false}) {
    final objeto = key.currentContext?.findRenderObject();
    if (objeto is! RenderBox || !objeto.hasSize || !objeto.attached)
      return null;
    final punto = Offset(
      objeto.size.width / 2,
      objeto.size.height * (nave ? .68 : .5),
    );
    return lienzo.globalToLocal(objeto.localToGlobal(punto));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox.expand(
          key: _lienzo,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final lienzo = _lienzo.currentContext?.findRenderObject();
              if (lienzo is! RenderBox || !lienzo.hasSize)
                return const SizedBox();
              final origen = _posicion(widget.origen, lienzo, nave: true);
              final destino = _posicion(widget.destino, lienzo);
              if (origen == null ||
                  destino == null ||
                  MediaQuery.disableAnimationsOf(context))
                return const SizedBox();
              final progreso = Curves.easeInOutCubic.transform(
                _controller.value,
              );
              final posicion = _trayectoria(origen, destino, progreso);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EstelaPainter(origen, destino, progreso),
                    ),
                  ),
                  Positioned(
                    left: posicion.dx - 22,
                    top: posicion.dy - 22,
                    child: Transform.scale(
                      scale: 1 + .18 * math.sin(math.pi * progreso),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB6F6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xAA72E9FF),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${widget.disparo.numero}',
                          style: const TextStyle(
                            color: Color(0xFF071226),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Offset _trayectoria(Offset origen, Offset destino, double progreso) =>
    Offset.lerp(origen, destino, progreso)! +
    Offset(32, -24) * math.sin(math.pi * progreso);

class _EstelaPainter extends CustomPainter {
  final Offset origen;
  final Offset destino;
  final double progreso;

  const _EstelaPainter(this.origen, this.destino, this.progreso);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 12; i++) {
      final t = math.max(0.0, progreso - (12 - i) * .013);
      canvas.drawCircle(
        _trayectoria(origen, destino, t),
        1.5 + i * .3,
        Paint()..color = const Color(0xFF72E9FF).withValues(alpha: i / 18),
      );
    }
  }

  @override
  bool shouldRepaint(_EstelaPainter oldDelegate) =>
      oldDelegate.progreso != progreso ||
      oldDelegate.origen != origen ||
      oldDelegate.destino != destino;
}
