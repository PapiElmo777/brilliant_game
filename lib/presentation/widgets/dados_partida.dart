import 'package:flutter/material.dart';
import '../../bloc/partida_estado.dart';
import '../../models/tirada.dart';

class FichaDado extends StatelessWidget {
  final Dado dado;
  final bool seleccionado;
  final VoidCallback? onTap;
  final String? etiqueta;

  const FichaDado({
    super.key,
    required this.dado,
    this.seleccionado = false,
    this.onTap,
    this.etiqueta,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: etiqueta ?? 'Dado ${dado.id + 1}, número ${dado.valor}',
    button: true,
    selected: seleccionado,
    enabled: onTap != null,
    onTap: onTap,
    excludeSemantics: true,
    child: SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: seleccionado ? Colors.white : const Color(0xFFB6F6FF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: seleccionado ? Colors.white : const Color(0xFF72E9FF),
                width: 3,
              ),
              boxShadow: seleccionado
                  ? const [BoxShadow(color: Colors.white54, blurRadius: 14)]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${dado.valor}',
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF071226),
                    ),
                  ),
                ),
                if (seleccionado)
                  const Positioned(
                    right: 3,
                    top: 3,
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: Color(0xFF071226),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class DadosPartida extends StatefulWidget {
  final PartidaEstado estado;
  final GlobalKey lienzo;
  final GlobalKey arriba;
  final GlobalKey abajo;
  final ValueChanged<int> onSeleccionar;
  final VoidCallback onMovimientoCompletado;

  const DadosPartida({
    super.key,
    required this.estado,
    required this.lienzo,
    required this.arriba,
    required this.abajo,
    required this.onSeleccionar,
    required this.onMovimientoCompletado,
  });

  @override
  State<DadosPartida> createState() => _DadosPartidaState();
}

class _DadosPartidaState extends State<DadosPartida>
    with SingleTickerProviderStateMixin {
  late final AnimationController _movimiento = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  bool _notificado = false;

  @override
  void initState() {
    super.initState();
    _movimiento.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_notificado) {
        _notificado = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onMovimientoCompletado();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animar();
  }

  @override
  void didUpdateWidget(DadosPartida oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animar();
  }

  void _animar() {
    if (!widget.estado.dadosArriba) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _movimiento.value = 1;
    } else if (!_movimiento.isAnimating && _movimiento.value == 0) {
      _movimiento.forward();
    }
  }

  Offset? _centro(GlobalKey key, RenderBox lienzo, {bool inferior = false}) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return lienzo.globalToLocal(
      box.localToGlobal(
        Offset(
          box.size.width / 2,
          inferior ? box.size.height - 54 : box.size.height / 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _movimiento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _movimiento,
    builder: (context, _) {
      if (widget.estado.fase == FasePartida.tirando) return const SizedBox();
      final box = widget.lienzo.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return const SizedBox();
      final abajo = _centro(widget.abajo, box, inferior: true);
      final arriba = _centro(widget.arriba, box);
      if (abajo == null || arriba == null) return const SizedBox();
      final t = Curves.easeInOutCubic.transform(_movimiento.value);
      return Stack(
        children: [
          for (final dado in widget.estado.tirada.dados)
            Positioned(
              left:
                  Offset.lerp(
                    abajo +
                        Offset(dado.id == 0 ? -52 : 52, dado.id == 0 ? -4 : 4),
                    arriba + Offset(dado.id == 0 ? -36 : 36, 0),
                    t,
                  )!.dx -
                  28,
              top:
                  Offset.lerp(
                    abajo + Offset(0, dado.id == 0 ? -4 : 4),
                    arriba,
                    t,
                  )!.dy -
                  28,
              child: Transform.rotate(
                angle: (1 - t) * (dado.id == 0 ? -.12 : .13),
                child: FichaDado(
                  key: ValueKey('dado_${dado.id}'),
                  dado: dado,
                  seleccionado: widget.estado.dadoSeleccionado == dado.id,
                  onTap: widget.estado.puedeSeleccionar
                      ? () => widget.onSeleccionar(dado.id)
                      : null,
                ),
              ),
            ),
        ],
      );
    },
  );
}
