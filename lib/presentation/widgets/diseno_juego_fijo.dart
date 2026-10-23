import 'dart:math' as math;
import 'package:flutter/material.dart';

class MedidasJuegoFijo {
  final BoxConstraints espacio;
  MedidasJuegoFijo(this.espacio);
  bool get horizontal =>
      espacio.maxWidth >= 600 && espacio.maxWidth > espacio.maxHeight * 1.3;
  bool get compacto => horizontal || espacio.maxHeight < 720;
  double get ancho => horizontal
      ? math.min(1100, espacio.maxWidth) - 24
      : math.min(520, espacio.maxWidth) - 24;
  double get anchoPanel =>
      horizontal ? (ancho * .4).clamp(260.0, 360.0) : ancho;
  double get altoCabecera => compacto ? 34 : 44;
  double get altoPie => compacto ? 56 : 64;
}

class DisenoJuegoFijo extends StatelessWidget {
  final MedidasJuegoFijo medidas;
  final Widget cabecera;
  final Widget controles;
  final double altoControles;
  final Widget tablero;
  final Widget pie;
  const DisenoJuegoFijo({
    super.key,
    required this.medidas,
    required this.cabecera,
    required this.controles,
    required this.altoControles,
    required this.tablero,
    required this.pie,
  });
  Widget _tablero() => LayoutBuilder(
    builder: (context, espacio) => Center(
      child: SizedBox.square(
        dimension: espacio.biggest.shortestSide,
        child: tablero,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: medidas.horizontal ? 1100 : 520),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Column(
          children: [
            SizedBox(height: medidas.altoCabecera, child: cabecera),
            Expanded(
              child: medidas.horizontal
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: medidas.anchoPanel,
                          child: Column(
                            children: [
                              SizedBox(height: altoControles, child: controles),
                              const Spacer(),
                              SizedBox(height: medidas.altoPie, child: pie),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _tablero()),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(height: altoControles, child: controles),
                        Expanded(child: _tablero()),
                        SizedBox(height: medidas.altoPie, child: pie),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
