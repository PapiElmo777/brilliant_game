import 'package:flutter/material.dart';

import '../../bloc/inicio_estado.dart';

class BandejaNumeros extends StatelessWidget {
  final InicioEstado estado;
  final ValueChanged<int> onSeleccionado;

  const BandejaNumeros({
    super.key,
    required this.estado,
    required this.onSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final numeros = estado.numerosFaltantes.toList()..sort();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final numero in numeros)
          Semantics(
            selected: numero == estado.numeroSeleccionado,
            button: true,
            enabled: !estado.interaccionBloqueada,
            label: 'Número $numero',
            onTap: estado.interaccionBloqueada
                ? null
                : () => onSeleccionado(numero),
            excludeSemantics: true,
            child: SizedBox(
              width: 48,
              height: 56,
              child: OutlinedButton(
                key: ValueKey('numero_$numero'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: numero == estado.numeroSeleccionado
                      ? const Color(0xFF72E9FF)
                      : const Color(0xFF132D46),
                  foregroundColor: numero == estado.numeroSeleccionado
                      ? const Color(0xFF071226)
                      : const Color(0xFFF4FAFF),
                  side: BorderSide(
                    color: numero == estado.numeroSeleccionado
                        ? Colors.white
                        : const Color(0xFF44647A),
                    width: numero == estado.numeroSeleccionado ? 2 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: estado.interaccionBloqueada
                    ? null
                    : () => onSeleccionado(numero),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$numero',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (numero == estado.numeroSeleccionado)
                      const Icon(Icons.check_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
