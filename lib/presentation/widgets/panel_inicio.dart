import 'package:flutter/material.dart';

import '../../app/tema_brilliant.dart';
import 'boton_inicio.dart';

/// Panel fijo en la parte inferior de la preparación. Presenta `INICIO` al
/// completar los seis números, sin necesidad de desplazar la pantalla, y
/// después confirma el inicio de la misión.
class PanelInicio extends StatelessWidget {
  /// Altura reservada al final del contenido desplazable para que el panel no
  /// cubra el tablero.
  static const alturaReservada = 150.0;

  final bool iniciado;
  final VoidCallback onInicio;

  const PanelInicio({
    super.key,
    required this.iniciado,
    required this.onInicio,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00071226), Color(0xE6071226)],
                  stops: [0, .45],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                child: iniciado
                    ? Semantics(
                        liveRegion: true,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: ColoresBrilliant.cian,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text('Posiciones iniciales confirmadas'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: const Text(
                              '¡TODO LISTO!',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w700,
                                color: ColoresBrilliant.cian,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          BotonInicio(onPressed: onInicio),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
