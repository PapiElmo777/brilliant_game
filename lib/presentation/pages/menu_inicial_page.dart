import 'dart:math' as math;
import 'dart:ui' as ui;
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

/// Se separan la batalla y el logo para ordenar los controles sin repetir
/// la firma que ya contiene la imagen de fondo. Los originales se conservan.
class _PortadaMenu extends StatelessWidget {
  final VoidCallback? onNuevaPartida;
  const _PortadaMenu({required this.onNuevaPartida});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, espacio) {
        final horizontal = espacio.maxWidth > espacio.maxHeight;
        final ancho = math.min(300.0, espacio.maxWidth - 48);
        final logo = _LogoMenu(ancho: horizontal ? 240 : ancho);
        final controles = _ControlesMenu(onNuevaPartida: onNuevaPartida);
        if (horizontal) {
          return Row(
            children: [
              const Expanded(child: _BatallaMenu()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [logo, const SizedBox(height: 8), controles],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            const Expanded(child: _BatallaMenu()),
            logo,
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: controles,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    ),
  );
}

class _BatallaMenu extends StatelessWidget {
  const _BatallaMenu();
  static const _altoArte = 1250.0;
  Widget _imagen({required BoxFit fit, bool principal = false}) => FittedBox(
    fit: fit,
    alignment: Alignment.bottomCenter,
    child: SizedBox(
      width: 841,
      height: _altoArte,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 841,
          maxWidth: 841,
          minHeight: 1870,
          maxHeight: 1870,
          child: Image.asset(
            'assets/images/backgrounds/PantallaMenu1.png',
            key: principal ? const ValueKey('fondo_menu') : null,
            width: 841,
            height: 1870,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white, Colors.transparent],
      stops: [0, .92, 1],
    ).createShader(rect),
    child: ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Extiende el cielo hasta los bordes sin recortar las naves.
          Opacity(
            opacity: .5,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: _imagen(fit: BoxFit.cover),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final escala = math.min(
                rect.width / 841,
                rect.height / _altoArte,
              );
              final margen = (rect.width - 841 * escala) / (2 * rect.width);
              final borde = (1 - 2 * margen) * .08;
              return LinearGradient(
                colors: const [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [margen, margen + borde, 1 - margen - borde, 1 - margen],
              ).createShader(rect);
            },
            child: _imagen(fit: BoxFit.contain, principal: true),
          ),
        ],
      ),
    ),
  );
}

class _LogoMenu extends StatelessWidget {
  final double ancho;
  const _LogoMenu({required this.ancho});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Brilliant',
    image: true,
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, .12, .88, 1],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, .1, .86, 1],
        ).createShader(rect),
        child: Image.asset(
          'assets/images/branding/LogoMenu.png',
          key: const ValueKey('logo_menu'),
          width: ancho,
          height: ancho * 272 / 448,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
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
