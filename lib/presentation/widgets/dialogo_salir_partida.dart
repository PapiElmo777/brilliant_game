import 'package:flutter/material.dart';

import '../../app/tema_brilliant.dart';

/// Pregunta si se abandona la partida; devuelve `true` al confirmar.
class DialogoSalirPartida extends StatelessWidget {
  const DialogoSalirPartida({super.key});

  static Future<bool> mostrar(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const DialogoSalirPartida(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF0C2640),
    shape: const BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      side: BorderSide(color: ColoresBrilliant.cian, width: 1.5),
    ),
    title: const Text(
      '¿Seguro que quieres salir?',
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
    content: const Text('Se perderá el progreso de la partida.'),
    actions: [
      TextButton(
        key: const ValueKey('cancelar_salida'),
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('confirmar_salida'),
        style: FilledButton.styleFrom(foregroundColor: ColoresBrilliant.fondo),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('SALIR'),
      ),
    ],
  );
}
