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
    Widget group(Iterable<Tipo> types) => Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [for (final tipo in types) CuadroRegla(tipo: tipo)],
      ),
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
  const CuadroRegla({super.key, required this.tipo});
  @override
  Widget build(BuildContext context) {
    final dark =
        ThemeData.estimateBrightnessForColor(tipo.color) == Brightness.dark;
    return Tooltip(
      message: tipo.descripcion,
      child: Semantics(
        label: tipo.descripcion,
        excludeSemantics: true,
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: tipo.color,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: Color.lerp(tipo.color, Colors.white, .45)!,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
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
