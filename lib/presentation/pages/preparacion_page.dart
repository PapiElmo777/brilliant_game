import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/inicio_bloc.dart';
import '../../bloc/inicio_estado.dart';
import '../../bloc/inicio_evento.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/nave_marciano.dart';
import '../widgets/nave_entrada.dart';
import '../widgets/disparo_numero_overlay.dart';
import '../widgets/mensaje_error.dart';
import '../widgets/respuesta_error.dart';
import '../widgets/panel_inicio.dart';
import '../widgets/tablero_view.dart';
import '../widgets/bandeja_numeros.dart';

class PreparacionPage extends StatefulWidget {
  final DefinicionTablero definicion;
  final String? jugador;

  const PreparacionPage({super.key, required this.definicion, this.jugador});

  @override
  State<PreparacionPage> createState() => _PreparacionPageState();
}

class _PreparacionPageState extends State<PreparacionPage> {
  final _origenNave = GlobalKey();
  late final _clavesCeldas = <String, GlobalKey>{
    for (final zona in widget.definicion.zonas)
      for (final celda in zona.celdas) celda.id: GlobalKey(),
  };

  static bool _panelVisible(InicioEstado estado) =>
      estado.puedeIniciar || estado.fase == FaseInicio.iniciado;

  @override
  Widget build(BuildContext context) {
    // El error se presenta sólo en línea, junto al tablero.
    return BlocBuilder<InicioBloc, InicioEstado>(
      builder: (context, estado) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            FondoEspacial(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: estado.faseVisual == FaseVisualInicio.disparando
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Volver al menú',
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'BRILLIANT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.definicion.nombre ??
                                        widget.definicion.id,
                                    style: const TextStyle(
                                      color: Color(0xFF9FBACB),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                key: _origenNave,
                                width: 170,
                                child: NaveEntrada(
                                  llegando:
                                      estado.faseVisual ==
                                      FaseVisualInicio.llegandoNave,
                                  onCompletada: () => context
                                      .read<InicioBloc>()
                                      .add(const LlegadaNaveCompletada()),
                                  child: NaveMarciano(
                                    hazActivo:
                                        estado.faseVisual !=
                                        FaseVisualInicio.llegandoNave,
                                  ),
                                ),
                              ),
                              Text(
                                estado.fase == FaseInicio.iniciado
                                    ? 'MISIÓN INICIADA'
                                    : widget.jugador == null
                                    ? 'PREPARA TU MISIÓN'
                                    : 'PREPARA TU MISIÓN, '
                                          '${widget.jugador!.toUpperCase()}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 2.5,
                                  color: Color(0xFF72E9FF),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                estado.fase == FaseInicio.iniciado
                                    ? 'Tus números están en posición'
                                    : 'Acomoda los números en las celdas iniciales',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              BandejaNumeros(
                                estado: estado,
                                onPresentacionCompletada: () => context
                                    .read<InicioBloc>()
                                    .add(const PresentacionNumerosCompletada()),
                                onSeleccionado: (numero) => context
                                    .read<InicioBloc>()
                                    .add(NumeroInicialSeleccionado(numero)),
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  const ExcludeSemantics(
                                    child: Opacity(
                                      opacity: 0,
                                      child: Text(
                                        'Número 6 seleccionado · toca una celda +',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFFB1C4D4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      estado.fase == FaseInicio.iniciado
                                          ? 'Preparación confirmada'
                                          : estado.faseVisual ==
                                                FaseVisualInicio.disparando
                                          ? 'Enviando número ${estado.numeroSeleccionado}'
                                          : estado.numeroSeleccionado != null
                                          ? 'Número ${estado.numeroSeleccionado} seleccionado · toca una celda +'
                                          : '${6 - estado.numerosFaltantes.length} de 6 colocados',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFB1C4D4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  if (estado.numeroSeleccionado != null)
                                    TextButton(
                                      onPressed: estado.interaccionBloqueada
                                          ? null
                                          : () =>
                                                context.read<InicioBloc>().add(
                                                  const SeleccionCancelada(),
                                                ),
                                      child: const Text('Cancelar selección'),
                                    ),
                                  // Conserva su espacio al completar para que
                                  // el tablero no cambie de posición.
                                  Visibility(
                                    visible:
                                        estado.fase != FaseInicio.iniciado &&
                                        estado.numerosFaltantes.isNotEmpty,
                                    maintainState: true,
                                    maintainAnimation: true,
                                    maintainSize: true,
                                    child: TextButton.icon(
                                      key: const ValueKey('boton_aleatorio'),
                                      onPressed: estado.interaccionBloqueada
                                          ? null
                                          : () => context.read<InicioBloc>().add(
                                              const ColocacionAleatoriaSolicitada(),
                                            ),
                                      icon: const Icon(Icons.shuffle_rounded),
                                      label: const Text('Acomodo aleatorio'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TableroView(
                                definicion: widget.definicion,
                                clavesCeldas: _clavesCeldas,
                                estado: estado,
                                onCeldaSeleccionada: (id) => context
                                    .read<InicioBloc>()
                                    .add(CeldaInicialSeleccionada(id)),
                              ),
                              const SizedBox(height: 16),
                              if (estado.error != null)
                                RespuestaError(
                                  key: ObjectKey(estado),
                                  child: MensajeError(mensaje: estado.error!),
                                ),
                              if (estado.fase != FaseInicio.iniciado)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Las celdas + son tu punto de partida.\nToca un número colocado para retirarlo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFAAC0D1),
                                    ),
                                  ),
                                ),
                              if (_panelVisible(estado))
                                const SizedBox(
                                  height: PanelInicio.alturaReservada,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_panelVisible(estado))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PanelInicio(
                  iniciado: estado.fase == FaseInicio.iniciado,
                  onInicio: () =>
                      context.read<InicioBloc>().add(const InicioSolicitado()),
                ),
              ),
            if (estado.disparoPendiente case final disparo?)
              Positioned.fill(
                child: DisparoNumeroOverlay(
                  key: ValueKey(disparo.id),
                  disparo: disparo,
                  origen: _origenNave,
                  destino: _clavesCeldas[disparo.celdaId]!,
                  onCompletado: () => context.read<InicioBloc>().add(
                    DisparoNumeroCompletado(disparo.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
