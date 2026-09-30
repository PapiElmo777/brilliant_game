import 'package:flutter/material.dart';

import '../../app/tema_brilliant.dart';
import '../../bloc/menu_bloc.dart';

/// Solicita el nombre del jugador. Devuelve el texto escrito o `null` si se
/// cancela; la validación definitiva corresponde a `MenuBloc`.
class DialogoNombreJugador extends StatefulWidget {
  final String? inicial;
  final String? error;

  const DialogoNombreJugador({super.key, this.inicial, this.error});

  static Future<String?> mostrar(
    BuildContext context, {
    String? inicial,
    String? error,
  }) => showDialog<String>(
    context: context,
    builder: (_) => DialogoNombreJugador(inicial: inicial, error: error),
  );

  @override
  State<DialogoNombreJugador> createState() => _DialogoNombreJugadorState();
}

class _DialogoNombreJugadorState extends State<DialogoNombreJugador> {
  late final _controlador = TextEditingController(text: widget.inicial);

  bool get _hayNombre => _controlador.text.trim().isNotEmpty;

  void _confirmar() {
    if (_hayNombre) Navigator.of(context).pop(_controlador.text);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C2640),
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: ColoresBrilliant.cian, width: 1.5),
      ),
      title: const Text(
        '¿Cómo te llamas?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        key: const ValueKey('campo_nombre'),
        controller: _controlador,
        autofocus: true,
        maxLength: MenuEstado.longitudMaximaNombre,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _confirmar(),
        decoration: InputDecoration(
          labelText: 'Nombre del jugador',
          errorText: widget.error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('confirmar_nombre'),
          style: FilledButton.styleFrom(
            foregroundColor: ColoresBrilliant.fondo,
            disabledBackgroundColor: const Color(0xFF1E3A52),
            disabledForegroundColor: const Color(0xFF6F8798),
          ),
          onPressed: _hayNombre ? _confirmar : null,
          child: const Text('CONTINUAR'),
        ),
      ],
    );
  }
}
