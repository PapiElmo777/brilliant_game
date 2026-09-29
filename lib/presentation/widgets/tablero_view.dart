import 'package:flutter/material.dart';

import '../../bloc/inicio_estado.dart';
import '../../catalogo/definicion_tablero.dart';
import '../../models/celda.dart';
import '../../models/tipo.dart';

class TableroView extends StatelessWidget {
  final DefinicionTablero definicion;
  final InicioEstado estado;
  final ValueChanged<String> onCeldaSeleccionada;

  const TableroView({
    super.key,
    required this.definicion,
    required this.estado,
    required this.onCeldaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    final tipos = {
      for (final zona in definicion.zonas)
        for (final celda in zona.celdas) celda.id: zona.tipo,
    };
    final celdas = estado.celdas.values.toList()
      ..sort((a, b) {
        final fila = a.fila.compareTo(b.fila);
        return fila == 0 ? a.columna.compareTo(b.columna) : fila;
      });
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCC071226),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF355972)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: celdas.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final celda = celdas[index];
            return CeldaView(
              key: ValueKey('celda_${celda.id}'),
              celda: celda,
              tipo: tipos[celda.id]!,
              onTap: estado.interaccionBloqueada
                  ? null
                  : () => onCeldaSeleccionada(celda.id),
            );
          },
        ),
      ),
    );
  }
}

class CeldaView extends StatelessWidget {
  final Celda celda;
  final Tipo tipo;
  final VoidCallback? onTap;

  const CeldaView({
    super.key,
    required this.celda,
    required this.tipo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final texto =
        ThemeData.estimateBrightnessForColor(tipo.color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF071226);
    final estado = celda.valor == null ? 'vacía' : 'número ${celda.valor}';
    return Semantics(
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      label:
          'Fila ${celda.fila + 1}, columna ${celda.columna + 1}${celda.esInicio ? ', celda inicial' : ''}, $estado. ${tipo.descripcion}',
      hint: celda.esInicio
          ? (celda.estaOcupada
                ? 'Retirar número'
                : 'Colocar número seleccionado')
          : 'Celda de juego',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(tipo.color, Colors.white, .18)!,
                tipo.color,
                Color.lerp(tipo.color, Colors.black, .2)!,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: celda.esInicio
                  ? const Color(0xFFB6F6FF)
                  : const Color(0x33FFFFFF),
              width: celda.esInicio ? 2 : 1,
            ),
            boxShadow: celda.esInicio
                ? const [BoxShadow(color: Color(0x6672E9FF), blurRadius: 6)]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Center(
              child: celda.valor != null
                  ? FittedBox(
                      child: Text(
                        '${celda.valor}',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: texto,
                        ),
                      ),
                    )
                  : celda.esInicio
                  ? Icon(Icons.add_rounded, size: 20, color: texto)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
