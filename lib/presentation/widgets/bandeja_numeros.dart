import 'package:flutter/material.dart';

import '../../bloc/inicio_estado.dart';

class BandejaNumeros extends StatefulWidget {
  final InicioEstado estado;
  final ValueChanged<int> onSeleccionado;
  final VoidCallback? onPresentacionCompletada;

  const BandejaNumeros({
    super.key,
    required this.estado,
    required this.onSeleccionado,
    this.onPresentacionCompletada,
  });

  @override
  State<BandejaNumeros> createState() => _BandejaNumerosState();
}

class _BandejaNumerosState extends State<BandejaNumeros>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _notificar();
      });
  bool _notificada = false;

  void _notificar() {
    if (widget.estado.faseVisual != FaseVisualInicio.mostrandoNumeros ||
        _notificada)
      return;
    _notificada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPresentacionCompletada?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizar();
  }

  @override
  void didUpdateWidget(BandejaNumeros oldWidget) {
    super.didUpdateWidget(oldWidget);
    _actualizar();
  }

  void _actualizar() {
    if (widget.estado.faseVisual == FaseVisualInicio.llegandoNave) {
      _controller.value = 0;
    } else if (widget.estado.faseVisual == FaseVisualInicio.mostrandoNumeros &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (_controller.status == AnimationStatus.dismissed)
        _controller.forward();
    } else {
      _controller.value = 1;
      _notificar();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final onSeleccionado = widget.onSeleccionado;
    final numeros = estado.numerosFaltantes.toList()..sort();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var numero = 1; numero <= 6; numero++)
            if (!numeros.contains(numero))
              const SizedBox(width: 48, height: 56)
            else
              _AparicionNumero(
                progreso: Interval(
                  .26 + (numero - 1) * .09,
                  .5 + (numero - 1) * .09,
                  curve: Curves.easeOutCubic,
                ).transform(_controller.value),
                child: Semantics(
                  selected: numero == estado.numeroSeleccionado,
                  button: true,
                  enabled: !estado.interaccionBloqueada,
                  label: 'Número $numero',
                  onTap: estado.interaccionBloqueada
                      ? null
                      : () => onSeleccionado(numero),
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 48,
                    height: 56,
                    child: OutlinedButton(
                      key: ValueKey('numero_$numero'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        disabledForegroundColor:
                            numero == estado.numeroSeleccionado
                            ? const Color(0xFF234254)
                            : const Color(0xFF8DA5B5),
                        backgroundColor: numero == estado.numeroSeleccionado
                            ? const Color(0xFF72E9FF)
                            : const Color(0xFF132D46),
                        foregroundColor: numero == estado.numeroSeleccionado
                            ? const Color(0xFF071226)
                            : const Color(0xFFF4FAFF),
                        side: BorderSide(
                          color: numero == estado.numeroSeleccionado
                              ? Colors.white
                              : const Color(0xFF44647A),
                          width: numero == estado.numeroSeleccionado ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: estado.interaccionBloqueada
                          ? null
                          : () => onSeleccionado(numero),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$numero',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (numero == estado.numeroSeleccionado)
                            const Icon(Icons.check_rounded, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _AparicionNumero extends StatelessWidget {
  final double progreso;
  final Widget child;

  const _AparicionNumero({required this.progreso, required this.child});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    excluding: progreso < 1,
    child: Opacity(
      opacity: progreso,
      child: Transform.translate(
        offset: Offset(0, -36 * (1 - progreso)),
        child: child,
      ),
    ),
  );
}
