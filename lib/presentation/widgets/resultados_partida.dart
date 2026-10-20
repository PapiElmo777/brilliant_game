import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/tema_brilliant.dart';
import '../../bloc/partida_estado.dart';
import 'boton_panel.dart';

const _dorado = Color(0xFFFFC94D);

/// Menú final de la partida: trofeo, ranking y opciones para continuar.
class ResultadosPartida extends StatefulWidget {
  final List<ResultadoJugador> resultados;
  final int meta;
  final VoidCallback onEmpezarDeNuevo;
  final VoidCallback onSalirAlMenu;

  const ResultadosPartida({
    super.key,
    required this.resultados,
    required this.meta,
    required this.onEmpezarDeNuevo,
    required this.onSalirAlMenu,
  });

  @override
  State<ResultadosPartida> createState() => _ResultadosPartidaState();
}

class _ResultadosPartidaState extends State<ResultadosPartida>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
    } else if (_entrada.isDismissed) {
      _entrada.forward();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  /// Fracción de la entrada entre [inicio] y [fin], con desaceleración.
  Animation<double> _tramo(
    double inicio,
    double fin, [
    Curve curva = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _entrada,
    curve: Interval(inicio, fin, curve: curva),
  );

  Widget _aparecer(Animation<double> t, Widget child, {double desde = 24}) =>
      AnimatedBuilder(
        animation: t,
        builder: (context, child) => Opacity(
          opacity: t.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t.value) * desde),
            child: child,
          ),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final panel = _tramo(0, .35);
    final trofeo = _tramo(.12, .55, Curves.elasticOut);
    return Semantics(
      container: true,
      label: 'Resultados de la partida',
      // Centrado verticalmente; si no cabe, se desplaza.
      child: LayoutBuilder(
        builder: (context, espacio) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (espacio.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _aparecer(
                  panel,
                  desde: 60,
                  DecoratedBox(
                    key: const ValueKey('resultados_partida'),
                    decoration: ShapeDecoration(
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(22)),
                        side: BorderSide(
                          color: ColoresBrilliant.cian,
                          width: 1.5,
                        ),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xF2163A5C), Color(0xF20A1C33)],
                      ),
                      shadows: [
                        BoxShadow(
                          color: ColoresBrilliant.cian.withValues(alpha: .35),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 132,
                            child: _Trofeo(entrada: _entrada, escala: trofeo),
                          ),
                          _aparecer(
                            _tramo(.3, .6),
                            Column(
                              children: [
                                Text(
                                  'RESULTADOS',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Meta: ${widget.meta} puntos',
                                  style: const TextStyle(
                                    color: Color(0xFF9FBACB),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (var i = 0; i < widget.resultados.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _aparecer(
                                _tramo(
                                  (.4 + i * .08).clamp(0, .8),
                                  (.7 + i * .08).clamp(0, 1),
                                ),
                                _FilaRanking(resultado: widget.resultados[i]),
                              ),
                            ),
                          const SizedBox(height: 14),
                          _aparecer(
                            _tramo(.6, .9),
                            Column(
                              children: [
                                BotonPanel(
                                  key: const ValueKey('boton_empezar_de_nuevo'),
                                  texto: 'EMPEZAR DE NUEVO',
                                  icono: Icons.replay_rounded,
                                  onPressed: widget.onEmpezarDeNuevo,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    key: const ValueKey('boton_salir_menu'),
                                    onPressed: widget.onSalirAlMenu,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFB6F6FF),
                                      side: const BorderSide(
                                        color: Color(0x8872E9FF),
                                      ),
                                      shape: const BeveledRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2,
                                          ),
                                    ),
                                    icon: const Icon(Icons.home_rounded),
                                    label: const Text('SALIR AL MENÚ'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaRanking extends StatelessWidget {
  final ResultadoJugador resultado;
  const _FilaRanking({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final primero = resultado.posicion == 1;
    return Semantics(
      label:
          'Lugar ${resultado.posicion}: ${resultado.nombre}, '
          '${resultado.puntos} puntos, '
          '${resultado.zonasCompletadas} zonas completadas',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('ranking_${resultado.jugadorId}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: resultado.esLocal
                ? const [Color(0x3372E9FF), Color(0x1172E9FF)]
                : const [Color(0x22FFFFFF), Color(0x0AFFFFFF)],
          ),
          border: Border.all(
            color: primero
                ? _dorado.withValues(alpha: .8)
                : const Color(0x4472E9FF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: primero
                    ? const RadialGradient(
                        colors: [Color(0xFFFFE8A3), _dorado, Color(0xFFB8860B)],
                        stops: [0, .55, 1],
                      )
                    : null,
                color: primero ? null : const Color(0x3372E9FF),
                boxShadow: primero
                    ? [
                        BoxShadow(
                          color: _dorado.withValues(alpha: .6),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${resultado.posicion}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: primero ? const Color(0xFF3A2600) : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultado.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${resultado.zonasCompletadas} '
                    '${resultado.zonasCompletadas == 1 ? 'zona completada' : 'zonas completadas'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9FBACB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${resultado.puntos}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB6F6FF),
                    ),
                  ),
                  const TextSpan(
                    text: ' pts',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9FBACB)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trofeo dorado con rayos de luz que giran al aparecer y un brillo que lo
/// cruza una vez.
class _Trofeo extends StatelessWidget {
  final Animation<double> entrada;
  final Animation<double> escala;
  const _Trofeo({required this.entrada, required this.escala});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: entrada,
      builder: (context, _) {
        final t = entrada.value;
        final brillo = Curves.easeInOut.transform(((t - .45) / .4).clamp(0, 1));
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(132),
              painter: _RayosPainter(
                giro: Curves.easeOutCubic.transform(t) * math.pi / 3,
                intensidad: escala.value.clamp(0.0, 1.0),
              ),
            ),
            Transform.scale(
              scale: escala.value,
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFFFFF1C2),
                    _dorado,
                    Color(0xFFFFFFFF),
                    _dorado,
                    Color(0xFFB8860B),
                  ],
                  // La banda blanca cruza el trofeo una sola vez.
                  stops: [
                    0,
                    (brillo * 1.2 - .25).clamp(0, 1),
                    (brillo * 1.2 - .1).clamp(0, 1),
                    (brillo * 1.2 + .05).clamp(0, 1),
                    1,
                  ],
                ).createShader(rect),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 84,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: _dorado.withValues(alpha: .7),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RayosPainter extends CustomPainter {
  final double giro;
  final double intensidad;
  const _RayosPainter({required this.giro, required this.intensidad});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensidad <= 0) return;
    final centro = size.center(Offset.zero);
    final radio = size.shortestSide / 2;
    final pintura = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          _dorado.withValues(alpha: .45 * intensidad),
          _dorado.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: centro, radius: radio));
    const rayos = 12;
    for (var i = 0; i < rayos; i++) {
      final angulo = giro + i * 2 * math.pi / rayos;
      final rayo = Path()
        ..moveTo(centro.dx, centro.dy)
        ..lineTo(
          centro.dx + math.cos(angulo - .09) * radio,
          centro.dy + math.sin(angulo - .09) * radio,
        )
        ..lineTo(
          centro.dx + math.cos(angulo + .09) * radio,
          centro.dy + math.sin(angulo + .09) * radio,
        )
        ..close();
      canvas.drawPath(rayo, pintura);
    }
    canvas.drawCircle(
      centro,
      radio * .55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _dorado.withValues(alpha: .35 * intensidad),
            _dorado.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio * .55)),
    );
  }

  @override
  bool shouldRepaint(_RayosPainter old) =>
      old.giro != giro || old.intensidad != intensidad;
}
