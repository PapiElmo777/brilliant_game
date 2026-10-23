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

/// Conserva el paisaje a pantalla completa. La sombra inferior y el logo
/// con alfa se mezclan con el cielo, sin paneles ni recortes de la batalla.
class _PortadaMenu extends StatelessWidget {
  final VoidCallback? onNuevaPartida;
  const _PortadaMenu({required this.onNuevaPartida});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, espacio) {
      final horizontal = espacio.maxWidth > espacio.maxHeight;
      final barras = MediaQuery.paddingOf(context);
      final ancho = math.min(340.0, espacio.maxWidth - 48);
      final altoLogo = (espacio.maxHeight * .16).clamp(86.0, 140.0);
      final arribaControles = espacio.maxHeight - barras.bottom - 16 - 104;
      final controles = _ControlesMenu(onNuevaPartida: onNuevaPartida);
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/PantallaMenu1.png',
            key: const ValueKey('fondo_menu'),
            fit: horizontal ? BoxFit.contain : BoxFit.cover,
            alignment: horizontal
                ? Alignment.centerLeft
                : Alignment.bottomCenter,
            excludeFromSemantics: true,
          ),
          // El propio cielo continúa detrás del logo y de los controles.
          // La firma original se desvanece bajo esta sombra sin cortar la imagen.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .62, .79, 1],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xFF00102F),
                  Color(0xFF00102F),
                ],
              ),
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
                      const _LogoMenu(ancho: 260, alto: 140),
                      const SizedBox(height: 12),
                      controles,
                    ],
                  ),
                ),
              ),
            )
          else ...[
            Positioned(
              left: (espacio.maxWidth - ancho) / 2,
              width: ancho,
              top: arribaControles - 12 - altoLogo,
              height: altoLogo,
              child: _LogoMenu(ancho: ancho, alto: altoLogo),
            ),
            Positioned(
              left: (espacio.maxWidth - ancho) / 2,
              width: ancho,
              top: arribaControles,
              height: 104,
              child: controles,
            ),
          ],
        ],
      );
    },
  );
}

class _LogoMenu extends StatelessWidget {
  final double ancho;
  final double alto;
  const _LogoMenu({required this.ancho, required this.alto});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Brilliant',
    image: true,
    child: Image.asset(
      'assets/images/branding/LogoBrilliant.png',
      key: const ValueKey('logo_menu'),
      width: ancho,
      height: alto,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    ),
  );
}

class _ControlesMenu extends StatelessWidget {
  final VoidCallback? onNuevaPartida;
  const _ControlesMenu({required this.onNuevaPartida});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
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
      const SizedBox(height: 10),
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
    ],
  );
}
