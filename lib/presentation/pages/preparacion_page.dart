import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/inicio_bloc.dart';
import '../../bloc/inicio_estado.dart';
import '../../bloc/inicio_evento.dart';
import '../../bloc/partida_bloc.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/diseno_juego_fijo.dart';
import '../widgets/nave_marciano.dart';
import '../widgets/nave_entrada.dart';
import '../widgets/disparo_numero_overlay.dart';
import '../widgets/mensaje_error.dart';
import '../widgets/respuesta_error.dart';
import '../widgets/boton_inicio.dart';
import '../widgets/tablero_view.dart';
import '../widgets/bandeja_numeros.dart';
import 'partida_page.dart';

class PreparacionPage extends StatefulWidget {
  final DefinicionTablero definicion;
  final String? jugador;
  final Random? azarPartida;
  const PreparacionPage({
    super.key,
    required this.definicion,
    this.jugador,
    this.azarPartida,
  });
  @override
  State<PreparacionPage> createState() => _PreparacionPageState();
}

class _PreparacionPageState extends State<PreparacionPage> {
  final _origenNave = GlobalKey();
  late final _clavesCeldas = <String, GlobalKey>{
    for (final z in widget.definicion.zonas)
      for (final c in z.celdas) c.id: GlobalKey(),
  };
  String _mensaje(InicioEstado e) => e.faseVisual == FaseVisualInicio.disparando
      ? 'Enviando número ${e.numeroSeleccionado}'
      : e.celdaSeleccionada != null
      ? 'Número ${e.celdas[e.celdaSeleccionada]!.valor} elegido · toca otra celda + para moverlo o intercambiarlo'
      : e.numeroSeleccionado != null
      ? 'Número ${e.numeroSeleccionado} seleccionado · toca una celda +'
      : '${6 - e.numerosFaltantes.length} de 6 colocados';
  String get _nombre => widget.jugador == null
      ? 'PREPARA TU MISIÓN'
      : 'PREPARA TU MISIÓN, ${widget.jugador!.toUpperCase()}';
  Widget _ajustar(Widget child, double ancho) => FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox(width: ancho, child: child),
  );
  Widget _estado(InicioEstado e, double ancho) => _ajustar(
    e.error == null
        ? Semantics(
            liveRegion: true,
            child: Text(
              _mensaje(e),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: Color(0xFFB1C4D4)),
            ),
          )
        : RespuestaError(
            key: ObjectKey(e),
            child: MensajeError(mensaje: e.error!),
          ),
    ancho,
  );
  Widget _nave(InicioEstado e, double ancho) => SizedBox(
    key: _origenNave,
    width: ancho,
    child: NaveEntrada(
      llegando: e.faseVisual == FaseVisualInicio.llegandoNave,
      onCompletada: () =>
          context.read<InicioBloc>().add(const LlegadaNaveCompletada()),
      child: NaveMarciano(
        recursos: widget.definicion.recursos,
        hazActivo: e.faseVisual != FaseVisualInicio.llegandoNave,
      ),
    ),
  );
  Widget _numero(double ancho, bool compacto) => SizedBox(
    width: ancho,
    child: NumeroFondoNivel(
      ruta: widget.definicion.recursos?.fondo,
      compacto: compacto,
    ),
  );
  Widget _acciones(InicioEstado e) => Row(
    children: [
      Expanded(
        child: e.puedeReiniciar
            ? _accion(
                'boton_cancelar',
                'Cancelar selección',
                Icons.undo_rounded,
                e.interaccionBloqueada
                    ? null
                    : () => context.read<InicioBloc>().add(
                        const PreparacionReiniciada(),
                      ),
              )
            : const SizedBox(),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: e.numerosFaltantes.isNotEmpty
            ? _accion(
                'boton_aleatorio',
                'Acomodo aleatorio',
                Icons.shuffle_rounded,
                e.interaccionBloqueada
                    ? null
                    : () => context.read<InicioBloc>().add(
                        const ColocacionAleatoriaSolicitada(),
                      ),
              )
            : const SizedBox(),
      ),
    ],
  );
  Widget _accion(
    String clave,
    String texto,
    IconData icono,
    VoidCallback? accion,
  ) => TextButton(
    key: ValueKey(clave),
    onPressed: accion,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      backgroundColor: const Color(0xCC0C2640),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(texto, maxLines: 1),
          ),
        ),
      ],
    ),
  );
  Widget _controles(InicioEstado e, MedidasJuegoFijo m) {
    final ancho = m.anchoPanel;
    final bandeja = BandejaNumeros(
      estado: e,
      altura: m.compacto ? 48 : 52,
      onPresentacionCompletada: () =>
          context.read<InicioBloc>().add(const PresentacionNumerosCompletada()),
      onSeleccionado: (n) =>
          context.read<InicioBloc>().add(NumeroInicialSeleccionado(n)),
    );
    if (m.compacto) {
      return Column(
        children: [
          SizedBox(
            height: 62,
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_numero(64, true), _nave(e, 48)],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                        child: FittedBox(
                          child: Text(
                            _nombre,
                            style: const TextStyle(
                              color: Color(0xFF72E9FF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _estado(e, ancho - 84)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 48, child: bandeja),
          SizedBox(height: 36, child: _acciones(e)),
        ],
      );
    }
    final altoNumero = widget.definicion.recursos == null
        ? 0.0
        : FondoEspacial.altoNumero(ancho);
    final altoNave = 134 / (widget.definicion.recursos?.proporcionNave ?? 1.65);
    return Column(
      children: [
        SizedBox(height: altoNumero, child: _numero(ancho, false)),
        SizedBox(height: altoNave, child: _nave(e, 134)),
        SizedBox(
          height: 22,
          child: FittedBox(
            child: Text(
              _nombre,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 2.5,
                color: Color(0xFF72E9FF),
              ),
            ),
          ),
        ),
        SizedBox(height: 52, child: bandeja),
        SizedBox(height: 28, child: _estado(e, ancho)),
        SizedBox(height: 40, child: _acciones(e)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<InicioBloc, InicioEstado>(
    builder: (context, e) {
      if (e.fase == FaseInicio.iniciado) {
        return BlocProvider(
          create: (_) => PartidaBloc(
            context.read<InicioBloc>().crearTableroParaJuego(),
            azar: widget.azarPartida,
            nombreJugador: widget.jugador,
          ),
          child: PartidaPage(
            definicion: widget.definicion,
            jugador: widget.jugador,
          ),
        );
      }
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            FondoEspacial(
              ruta: widget.definicion.recursos?.fondo,
              numeroEnContenido: true,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, espacio) {
                    final m = MedidasJuegoFijo(espacio);
                    final altoControles = m.compacto
                        ? 146.0
                        : (widget.definicion.recursos == null
                                  ? 0
                                  : FondoEspacial.altoNumero(m.anchoPanel)) +
                              134 /
                                  (widget.definicion.recursos?.proporcionNave ??
                                      1.65) +
                              22 +
                              52 +
                              28 +
                              40;
                    return DisenoJuegoFijo(
                      medidas: m,
                      altoControles: altoControles,
                      cabecera: Row(
                        children: [
                          IconButton(
                            tooltip: 'Volver al menú',
                            constraints: BoxConstraints.tightFor(
                              width: 40,
                              height: m.altoCabecera,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Expanded(
                            child: Text(
                              'BRILLIANT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Text(
                            widget.definicion.nombre ?? widget.definicion.id,
                            style: const TextStyle(
                              color: Color(0xFF9FBACB),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      controles: _controles(e, m),
                      tablero: TableroView(
                        definicion: widget.definicion,
                        clavesCeldas: _clavesCeldas,
                        estado: e,
                        onCeldaSeleccionada: (id) => context
                            .read<InicioBloc>()
                            .add(CeldaInicialSeleccionada(id)),
                      ),
                      pie: Center(
                        child: e.puedeIniciar
                            ? BotonInicio(
                                compacto: true,
                                onPressed: () => context.read<InicioBloc>().add(
                                  const InicioSolicitado(),
                                ),
                              )
                            : _ajustar(
                                const Text(
                                  'Acomoda los números en las celdas iniciales.\nToca un número colocado para moverlo o intercambiarlo; tócalo dos veces para retirarlo.',
                                  maxLines: 3,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFAAC0D1),
                                  ),
                                ),
                                m.anchoPanel,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (e.disparoPendiente case final disparo?)
              Positioned.fill(
                child: DisparoNumeroOverlay(
                  key: ValueKey(disparo.id),
                  disparo: disparo,
                  fraccionOrigen: Offset(
                    .5,
                    widget.definicion.recursos?.emisionY ?? .68,
                  ),
                  origen: _origenNave,
                  destino: _clavesCeldas[disparo.celdaId]!,
                  onCompletado: () => context.read<InicioBloc>().add(
                    DisparoNumeroCompletado(disparo.id),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
