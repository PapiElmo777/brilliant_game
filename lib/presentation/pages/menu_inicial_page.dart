import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/menu_bloc.dart';
import '../../catalogo/definicion_tablero.dart';
import 'seleccion_nivel_page.dart';

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
          backgroundColor: const Color(0xFF00102F),
          body: _PortadaMenu(
            onNuevaPartida:
                estado.fase == FaseMenu.menuVisible ||
                    estado.fase == FaseMenu.partidaPreparada
                ? () => context.read<MenuBloc>().add(
                    const NuevaPartidaSolicitada(),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// La ilustración ya contiene el logotipo. Los controles ocupan el hueco
/// oscuro entre la batalla y la firma, sin tapar ninguno de los dos.
class _PortadaMenu extends StatelessWidget {
  final VoidCallback? onNuevaPartida;
  const _PortadaMenu({required this.onNuevaPartida});
  static const _fondo = 'assets/images/backgrounds/PantallaMenu1.png';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, espacio) {
      final horizontal = espacio.maxWidth > espacio.maxHeight;
      final escala = math.max(espacio.maxWidth / 841, espacio.maxHeight / 1870);
      // La imagen se ancla abajo para mantener visible la firma Brilliant.
      final centroControles = espacio.maxHeight - 1870 * escala * .27;
      final barras = MediaQuery.paddingOf(context);
      final ancho = math.min(340.0, espacio.maxWidth - 48);
      final controles = _ControlesMenu(onNuevaPartida: onNuevaPartida);
      return Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: 'Brilliant',
            image: true,
            child: Image.asset(
              _fondo,
              key: const ValueKey('fondo_menu'),
              fit: horizontal ? BoxFit.contain : BoxFit.cover,
              alignment: horizontal
                  ? Alignment.centerLeft
                  : Alignment.bottomCenter,
              excludeFromSemantics: true,
            ),
          ),
          if (horizontal)
            Positioned(
              left: espacio.maxHeight * 841 / 1870 + 24,
              right: barras.right + 24,
              top: barras.top + 16,
              bottom: barras.bottom + 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BRILLIANT',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Color(0xFFDCF9FF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      controles,
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: (espacio.maxWidth - ancho) / 2,
              width: ancho,
              top: centroControles - 52,
              height: 104,
              child: controles,
            ),
        ],
      );
    },
  );
}

class _ControlesMenu extends StatelessWidget {
  final VoidCallback? onNuevaPartida;
  const _ControlesMenu({required this.onNuevaPartida});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 42,
        child: LayoutBuilder(
          builder: (context, espacio) => FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: espacio.maxWidth,
              child: const Text(
                'Que la Fuerza guíe tus números.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE5F7FF),
                  shadows: [Shadow(color: Color(0xFF00102F), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF123F69), Color(0xFF061F45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x5533DFFF), blurRadius: 20),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const ValueKey('nueva_partida_menu'),
            onPressed: onNuevaPartida,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFE8FCFF),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF55DFFF), width: 1.3),
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Color(0xFF68EDFF)),
                  SizedBox(width: 10),
                  Text(
                    'NUEVA PARTIDA',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
