import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/menu_bloc.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/boton_panel.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/nave_marciano.dart';

class MenuInicialPage extends StatelessWidget {
  final ValueChanged<DefinicionTablero> onNuevaPartida;

  const MenuInicialPage({super.key, required this.onNuevaPartida});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MenuBloc(),
      child: BlocConsumer<MenuBloc, MenuEstado>(
        listenWhen: (anterior, actual) =>
            actual.fase == FaseMenu.partidaPreparada || actual.error != null,
        listener: (context, estado) {
          if (estado.tablero != null) onNuevaPartida(estado.tablero!);
          if (estado.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(estado.error!)));
          }
        },
        builder: (context, estado) => Scaffold(
          body: FondoEspacial(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'UNA MISIÓN. SEIS NÚMEROS.',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.5,
                                  color: Color(0xFFA3BDCD),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const NaveMarciano(),
                              const SizedBox(height: 12),
                              Semantics(
                                header: true,
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'BRILLIANT',
                                    style: TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                      color: Color(0xFFE2F9FF),
                                      shadows: [
                                        Shadow(
                                          color: Color(0x8872E9FF),
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                'by Alfredo',
                                style: TextStyle(
                                  fontSize: 16,
                                  letterSpacing: 3,
                                  color: Color(0xFF72E9FF),
                                ),
                              ),
                              const SizedBox(height: 36),
                              const Text(
                                'Cada número encuentra su lugar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFB1C4D4)),
                              ),
                              const SizedBox(height: 24),
                              BotonPanel(
                                texto: 'NUEVA PARTIDA',
                                icono: Icons.play_arrow_rounded,
                                onPressed:
                                    estado.fase == FaseMenu.creandoPartida
                                    ? null
                                    : () => context.read<MenuBloc>().add(
                                        const NuevaPartidaSolicitada(),
                                      ),
                              ),
                              const SizedBox(height: 36),
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
        ),
      ),
    );
  }
}
