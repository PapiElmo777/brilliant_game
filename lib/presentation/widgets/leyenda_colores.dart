import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../catalogo/definicion_tablero.dart';
import '../../models/tipo.dart';

String simboloRegla(Tipo tipo) => switch (tipo) {
  TipoNaranja(:final grupo) => grupo == GrupoNaranja.bajo ? '1–3' : '4–6',
  TipoAzul() => '=',
  TipoAmarillo() || TipoRojo() => '≠',
  TipoVerde() => '?',
  TipoMorado() => '×○',
  _ => '·',
};

/// Reglas presentes en este nivel, sin duplicar colores ni grupos naranjas.
List<Tipo> reglasDelNivel(DefinicionTablero definicion) {
  final rules = <String, Tipo>{};
  for (final zone in definicion.zonas) {
    final tipo = zone.tipo;
    rules.putIfAbsent(
      '${tipo.color.toARGB32()}:${simboloRegla(tipo)}',
      () => tipo,
    );
  }
  return rules.values.toList(growable: false);
}

class LeyendaColores extends StatelessWidget {
  final DefinicionTablero definicion;
  const LeyendaColores({super.key, required this.definicion});
  @override
  Widget build(BuildContext context) {
    final rules = reglasDelNivel(definicion);
    final split = (rules.length / 2).ceil();
    Widget group(Iterable<Tipo> types) => LayoutBuilder(
      builder: (context, space) {
        final dimension = math
            .min(27.0, (space.maxWidth - 5) / 2)
            .clamp(12.0, 27.0);
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final tipo in types)
                CuadroRegla(tipo: tipo, dimension: dimension),
            ],
          ),
        );
      },
    );
    return Row(
      key: const ValueKey('leyenda_colores'),
      children: [
        Expanded(child: group(rules.take(split))),
        const SizedBox(width: 144),
        Expanded(child: group(rules.skip(split))),
      ],
    );
  }
}

class CuadroRegla extends StatelessWidget {
  final Tipo tipo;
  final double dimension;
  const CuadroRegla({super.key, required this.tipo, this.dimension = 27});
  @override
  Widget build(BuildContext context) {
    final dark =
        ThemeData.estimateBrightnessForColor(tipo.color) == Brightness.dark;
    return Tooltip(
      message: tipo.descripcion,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: Semantics(
        label: tipo.descripcion,
        excludeSemantics: true,
        child: Container(
          width: dimension,
          height: dimension,
          decoration: BoxDecoration(
            color: tipo.color,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: Color.lerp(tipo.color, Colors.white, .45)!,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child:
              tipo is TipoMorado ||
                  tipo is TipoAzul ||
                  tipo is TipoRojo ||
                  tipo is TipoAmarillo
              ? CustomPaint(
                  size: const Size(22, 20),
                  painter: _SimboloRegla(
                    tipo,
                    dark ? Colors.white : const Color(0xFF071226),
                  ),
                )
              : FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      simboloRegla(tipo),
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: tipo is TipoNaranja ? 12 : 21,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: dark ? Colors.white : const Color(0xFF071226),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SimboloRegla extends CustomPainter {
  final Tipo tipo;
  final Color color;
  const _SimboloRegla(this.tipo, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (tipo is TipoMorado) {
      canvas.drawLine(const Offset(3, 6), const Offset(9, 14), p);
      canvas.drawLine(const Offset(9, 6), const Offset(3, 14), p);
      canvas.drawCircle(const Offset(16, 10), 4.2, p);
    } else {
      canvas.drawLine(const Offset(4, 7), const Offset(18, 7), p);
      canvas.drawLine(const Offset(4, 13), const Offset(18, 13), p);
      if (tipo is TipoAmarillo || tipo is TipoRojo) {
        canvas.drawLine(const Offset(7, 17), const Offset(15, 3), p);
      }
    }
  }

  @override
  bool shouldRepaint(_SimboloRegla old) =>
      old.color != color || old.tipo.runtimeType != tipo.runtimeType;
}
