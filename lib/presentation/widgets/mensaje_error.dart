import 'package:flutter/material.dart';

/// Mensaje breve de error funcional emitido por BLoC.
class MensajeError extends StatelessWidget {
  final String mensaje;

  const MensajeError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('mensaje_error'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A202D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFFB4AB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Color(0xFFFFDAD6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
