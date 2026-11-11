import '../../audio/audio_settings.dart';
import 'dart:math' as math;
import '../../auth/auth_cubit.dart';
import '../widgets/avatar_usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/menu_bloc.dart';
import '../../auth/auth_repository.dart';
import 'cuenta_page.dart';
import '../../catalogo/definicion_tablero.dart';
import 'seleccion_nivel_page.dart';

class MenuInicialPage extends StatefulWidget {
  final void Function(DefinicionTablero tablero, String jugador) onNuevaPartida;

  final Account? cuenta;
  final Future<void> Function()? onMultijugador;
  const MenuInicialPage({
    super.key,
    required this.onNuevaPartida,
    this.cuenta,
    this.onMultijugador,
  });

  @override
  State<MenuInicialPage> createState() => _MenuInicialPageState();
}

class _MenuInicialPageState extends State<MenuInicialPage> {
  bool _selectorAbierto = false;
  bool _multijugadorAbierto = false;
  Future<void> _abrirMultijugador() async {
    if (_multijugadorAbierto || widget.onMultijugador == null) return;
    setState(() => _multijugadorAbierto = true);
    try {
      await widget.onMultijugador!();
    } finally {
      if (mounted) setState(() => _multijugadorAbierto = false);
    }
  }

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
                      child: SeleccionNivelPage(
                        nombreCuenta: widget.cuenta?.username,
                      ),
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
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFF00102F),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _PortadaMenu(
                nombre: widget.cuenta?.username,
                onMultijugador:
                    widget.onMultijugador == null || _multijugadorAbierto
                    ? null
                    : _abrirMultijugador,
                onNuevaPartida:
                    estado.fase == FaseMenu.menuVisible ||
                        estado.fase == FaseMenu.partidaPreparada
                    ? () => context.read<MenuBloc>().add(
                        const NuevaPartidaSolicitada(),
                      )
                    : null,
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AudioSettingsButton(),
                        if (widget.cuenta != null)
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, auth) => IconButton(
                              key: const ValueKey('logout_menu'),
                              tooltip: 'Cerrar sesión',
                              onPressed: auth.busy
                                  ? null
                                  : () => context.read<AuthCubit>().logout(),
                              icon: const Icon(Icons.logout_rounded),
                            ),
                          ),
                        if (widget.cuenta != null)
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, auth) => IconButton(
                              key: const ValueKey('account_menu'),
                              tooltip: 'Mi cuenta',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CuentaPage(),
                                ),
                              ),
                              icon: AvatarUsuario(
                                avatarId: auth.session?.user.avatarId,
                                size: 44,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
  final VoidCallback? onMultijugador;
  final String? nombre;
  const _PortadaMenu({
    required this.onNuevaPartida,
    this.onMultijugador,
    this.nombre,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, espacio) {
      final horizontal = espacio.maxWidth > espacio.maxHeight;
      final barras = MediaQuery.paddingOf(context);
      final ancho = math.min(340.0, espacio.maxWidth - 48);
      final altoLogo = (espacio.maxHeight * .16).clamp(86.0, 140.0);
      final arribaControles = espacio.maxHeight - barras.bottom - 16 - 166;
      final controles = _ControlesMenu(
        onNuevaPartida: onNuevaPartida,
        onMultijugador: onMultijugador,
      );
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
              top: barras.top + 64,
              bottom: barras.bottom + 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LogoMenu(ancho: 230, alto: nombre == null ? 56 : 48),
                      if (nombre != null)
                        SizedBox(
                          height: 18,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Bienvenido $nombre',
                              key: const ValueKey('bienvenida_usuario'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
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
              top: arribaControles - (nombre == null ? 12 : 46) - altoLogo,
              height: altoLogo,
              child: _LogoMenu(ancho: ancho, alto: altoLogo),
            ),
            if (nombre != null)
              Positioned(
                left: 24,
                right: 24,
                top: arribaControles - 42,
                height: 30,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Bienvenido $nombre',
                    key: const ValueKey('bienvenida_usuario'),
                  ),
                ),
              ),
            Positioned(
              left: (espacio.maxWidth - ancho) / 2,
              width: ancho,
              top: arribaControles,
              height: 166,
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
  final VoidCallback? onMultijugador;
  const _ControlesMenu({required this.onNuevaPartida, this.onMultijugador});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _BotonModoMenu(
        clave: const ValueKey('nueva_partida_menu'),
        texto: 'UN JUGADOR',
        icono: Icons.play_arrow_rounded,
        onPressed: onNuevaPartida,
      ),
      const SizedBox(height: 10),
      _BotonModoMenu(
        clave: const ValueKey('multijugador_menu'),
        texto: 'MULTIJUGADOR',
        icono: Icons.groups,
        onPressed: onMultijugador,
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

class _BotonModoMenu extends StatelessWidget {
  final Key clave;
  final String texto;
  final IconData icono;
  final VoidCallback? onPressed;
  const _BotonModoMenu({
    required this.clave,
    required this.texto,
    required this.icono,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF123F69), Color(0xFF061F45)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [BoxShadow(color: Color(0x5533DFFF), blurRadius: 20)],
    ),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        key: clave,
        onPressed: onPressed,
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: const Color(0xFF68EDFF)),
              const SizedBox(width: 10),
              Text(
                texto,
                style: const TextStyle(
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
  );
}
