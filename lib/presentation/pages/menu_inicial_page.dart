import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/menu_bloc.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/boton_panel.dart';
import 'seleccion_nivel_page.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/logotipo_brilliant.dart';
import '../widgets/nave_marciano.dart';

class MenuInicialPage extends StatefulWidget {
  final void Function(DefinicionTablero tablero, String jugador) onNuevaPartida;

  const MenuInicialPage({super.key, required this.onNuevaPartida});

  @override
  State<MenuInicialPage> createState() => _MenuInicialPageState();
}

class _MenuInicialPageState extends State<MenuInicialPage> {
  bool _selectorAbierto = false;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MenuBloc(),
      child: BlocConsumer<MenuBloc, MenuEstado>(
        listener: (context, estado) async {
          if (estado.fase == FaseMenu.seleccionandoNivel && !_selectorAbierto) {
            _selectorAbierto = true;
            final bloc = context.read<MenuBloc>();
            final resultado = await Navigator.of(context)
                .push<(DefinicionTablero, String)>(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: const SeleccionNivelPage(),
                    ),
                  ),
                );
            _selectorAbierto = false;
            if (!mounted || bloc.isClosed) return;
            if (resultado == null) {
              bloc.add(const SeleccionNivelCancelada());
            } else {
              widget.onNuevaPartida(resultado.$1, resultado.$2);
            }
          } else if (estado.fase == FaseMenu.menuVisible &&
              estado.error != null) {
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
                              const LogotipoBrilliant(),
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
                                    estado.fase == FaseMenu.menuVisible ||
                                        estado.fase == FaseMenu.partidaPreparada
                                    ? () => context.read<MenuBloc>().add(
                                        const NuevaPartidaSolicitada(),
                                      )
                                    : null,
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
