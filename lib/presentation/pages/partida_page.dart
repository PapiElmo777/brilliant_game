import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/rutas_brilliant.dart';
import '../../bloc/partida_bloc.dart';
import '../../bloc/partida_estado.dart';
import '../../bloc/partida_evento.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/boton_panel.dart';
import '../widgets/celebracion_victoria.dart';
import '../widgets/dados_partida.dart';
import '../widgets/dialogo_salir_partida.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/historial_tiradas.dart';
import '../widgets/meteoritos_animacion.dart';
import '../widgets/nave_marciano.dart';
import '../widgets/respuesta_error.dart';
import '../widgets/resultados_partida.dart';
import '../widgets/tablero_view.dart';

class PartidaPage extends StatefulWidget {
  final DefinicionTablero definicion;
  final String? jugador;
  final Future<ui.Codec> Function()? cargarMeteoritos;

  /// Por omisión abre una preparación nueva con el mismo jugador.
  final VoidCallback? onEmpezarDeNuevo;

  const PartidaPage({
    super.key,
    required this.definicion,
    this.jugador,
    this.cargarMeteoritos,
    this.onEmpezarDeNuevo,
  });
  @override
  State<PartidaPage> createState() => _PartidaPageState();
}

class _PartidaPageState extends State<PartidaPage> {
  /// Reserva para encabezado, nave, mensajes, dados y controles. El tablero
  /// necesita además su ancho completo para conservar casillas utilizables.
  static const _alturaControles = 480.0;

  final _lienzo = GlobalKey();
  final _arriba = GlobalKey();
  final _impactos = GlobalKey();
  final _nave = GlobalKey();
  final _tableroClave = GlobalKey();
  final _celebracion = ControlCelebracion();

  @override
  void dispose() {
    _celebracion.dispose();
    super.dispose();
  }

  /// Durante la celebración, la nave y el tablero originales se ocultan
  /// mientras la animación dibuja sus copias en el mismo lugar.
  Widget _ocultable(Widget child, {required bool Function() oculto}) =>
      ListenableBuilder(
        listenable: _celebracion,
        child: child,
        builder: (context, child) =>
            Opacity(opacity: oculto() ? 0 : 1, child: child),
      );

  /// Sale al menú principal sólo si el jugador acepta perder la partida.
  Future<void> _confirmarSalida() async {
    if (!await DialogoSalirPartida.mostrar(context) || !mounted) return;
    _salirAlMenu();
  }

  void _salirAlMenu() => Navigator.of(context).popUntil((ruta) => ruta.isFirst);

  /// Conserva el nombre y va directo a acomodar los números.
  void _empezarDeNuevo() {
    if (widget.onEmpezarDeNuevo case final empezar?) return empezar();
    Navigator.of(context).pushReplacementNamed(
      RutasBrilliant.preparacion,
      arguments: (widget.definicion, widget.jugador),
    );
  }

  /// Regresar del sistema: con la partida en curso pide confirmación; en la
  /// celebración la omite y en los resultados vuelve al menú.
  void _regresar(PartidaEstado e, PartidaBloc bloc) {
    switch (e.fase) {
      case FasePartida.celebrandoVictoria:
        bloc.add(CelebracionCompletada(e.tirada.id));
      case FasePartida.mostrandoResultados:
        _salirAlMenu();
      default:
        _confirmarSalida();
    }
  }

  String _mensaje(PartidaEstado e) {
    if (e.animandoMeteoros) {
      return e.fase == FasePartida.tirando
          ? (e.tirada.id == 1 ? '¡El juego comenzó!' : 'Llegan los meteoros…')
          : 'Resultados: ${e.tirada.dados.map((d) => d.valor).join(' y ')}';
    }
    if (e.partidaTerminada) return '¡Llegaste a la meta de ${e.meta} puntos!';
    if (e.reclamoRonda case final reclamo?) {
      return '¡Zona completada! +${reclamo.puntos} puntos. '
          'Puedes cambiar tu jugada o lanzar.';
    }
    if (e.puedeModificar) {
      return 'Puedes cambiar tu jugada o lanzar los meteoros.';
    }
    if (e.fase == FasePartida.rondaResuelta) {
      return '¡Listo! Lanza otra vez los meteoros.';
    }
    if (e.ancla != null) {
      return e.fase == FasePartida.eligiendoDestino &&
              e.destinos.isEmpty &&
              !e.puedeOmitir
          ? 'Tu ancla es el ${e.ancla!.valor}. Cambia de número: este no tiene destinos.'
          : 'Tu ancla es el ${e.ancla!.valor}';
    }
    return e.puedeOmitir
        ? 'Ninguno de los dados tiene destinos disponibles.'
        : 'Elige el número que quieres colocar.';
  }

  Widget _globo(PartidaEstado e) => Semantics(
    liveRegion: true,
    // Las jugadas no válidas se avisan en el globo con una sacudida.
    child: e.error == null
        ? GloboAlien(mensaje: _mensaje(e))
        : RespuestaError(
            key: ObjectKey(e),
            child: GloboAlien(mensaje: e.error!, error: true),
          ),
  );

  /// El botón ocupa el lugar de los impactos cuando los dados ya subieron.
  Widget? _boton(PartidaEstado e, PartidaBloc bloc) {
    if (!e.dadosArriba) return null;
    if (e.fase == FasePartida.rondaResuelta && !e.gano) {
      return BotonPanel(
        key: const ValueKey('boton_lanzar'),
        texto: 'LANZAR METEOROS',
        icono: Icons.bolt,
        onPressed: () => bloc.add(MeteorosSolicitados(e.tirada.id)),
      );
    }
    if (e.puedeOmitir) {
      return BotonPanel(
        key: const ValueKey('boton_omitir'),
        texto: 'OMITIR TIRO',
        icono: Icons.skip_next_rounded,
        onPressed: () => bloc.add(TiroOmitido(e.tirada.id)),
      );
    }
    return null;
  }

  Widget _tablero(PartidaEstado e, PartidaBloc bloc) => _ocultable(
    oculto: () => _celebracion.ocultarTablero,
    KeyedSubtree(
      key: _tableroClave,
      child: TableroView.partida(
        definicion: widget.definicion,
        celdas: e.celdas,
        destinos: e.destinos,
        puestosReclamados: e.puestosReclamados,
        interactiva: e.puedeSeleccionar,
        onCeldaSeleccionada: (id) =>
            bloc.add(DestinoSeleccionado(e.tirada.id, id)),
      ),
    ),
  );

  Widget _contenido(
    PartidaEstado e,
    PartidaBloc bloc, {
    required bool fijo,
    required double alto,
  }) {
    final boton = _boton(e, bloc);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Stack(
        key: _lienzo,
        children: [
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Volver al menú',
                    onPressed: () => _regresar(e, bloc),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'BRILLIANT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Flexible(
                    child: HistorialTiradas(
                      registros: e.historial,
                      celdas: e.celdas,
                    ),
                  ),
                ],
              ),
              // La nave crece con la altura disponible sin quitarle demasiado
              // espacio al tablero.
              // La puntuación acompaña a la nave por la derecha.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Spacer(),
                  _ocultable(
                    oculto: () => _celebracion.ocultarNave,
                    SizedBox(
                      key: _nave,
                      width: (alto * .18).clamp(110.0, 180.0),
                      child: NaveMarciano(recursos: widget.definicion.recursos),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: PanelPuntos(puntos: e.puntos, meta: e.meta),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                widget.jugador == null
                    ? 'MISIÓN INICIADA'
                    : 'MISIÓN DE ${widget.jugador!.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, letterSpacing: 1.5),
              ),
              _globo(e),
              // Lugar de los dados bajo la nave, separado del globo. A la
              // derecha, sin estorbar a los dados, la opción de volver a tirar.
              SizedBox(
                key: _arriba,
                height: 92,
                width: double.infinity,
                child: e.puedeRelanzar
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: BotonRelanzar(
                          onPressed: () =>
                              bloc.add(DadosRelanzados(e.tirada.id)),
                        ),
                      )
                    : null,
              ),
              if (fijo)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, espacio) => Center(
                      child: SizedBox.square(
                        dimension: espacio.biggest.shortestSide,
                        child: _tablero(e, bloc),
                      ),
                    ),
                  ),
                )
              else
                _tablero(e, bloc),
              SizedBox(
                key: _impactos,
                height: 96,
                width: double.infinity,
                child: boton == null
                    ? null
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: boton,
                        ),
                      ),
              ),
            ],
          ),
          if (!e.partidaTerminada)
            Positioned.fill(
              child: DadosPartida(
                key: ValueKey('dados_${e.tirada.id}'),
                estado: e,
                lienzo: _lienzo,
                arriba: _arriba,
                abajo: _impactos,
                onSeleccionar: (id) =>
                    bloc.add(DadoSeleccionado(e.tirada.id, id)),
                onMovimientoCompletado: () =>
                    bloc.add(MovimientoDadosCompletado(e.tirada.id)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PartidaBloc, PartidaEstado>(
    builder: (context, e) {
      final bloc = context.read<PartidaBloc>();
      if (e.fase == FasePartida.mostrandoResultados) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (salio, _) {
            if (!salio) _regresar(e, bloc);
          },
          child: Scaffold(
            body: FondoEspacial(
              ruta: widget.definicion.recursos?.fondo,
              child: SafeArea(
                child: ResultadosPartida(
                  resultados: e.resultados,
                  meta: e.meta,
                  onEmpezarDeNuevo: _empezarDeNuevo,
                  onSalirAlMenu: _salirAlMenu,
                ),
              ),
            ),
          ),
        );
      }
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (salio, _) {
          if (!salio) _regresar(e, bloc);
        },
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              FondoEspacial(
                ruta: widget.definicion.recursos?.fondo,
                child: SafeArea(
                  // Si no cabe el tablero a su ancho completo, se permite
                  // desplazar en lugar de encoger sus casillas.
                  child: LayoutBuilder(
                    builder: (context, espacio) {
                      final anchoTablero =
                          espacio.maxWidth.clamp(0.0, 520.0) - 24;
                      final textoExtra =
                          (MediaQuery.textScalerOf(context).scale(16) - 16)
                              .clamp(0.0, double.infinity) *
                          8;
                      final fijo =
                          espacio.maxHeight >=
                          _alturaControles + anchoTablero + textoExtra;
                      final contenido = Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _contenido(
                            e,
                            bloc,
                            fijo: fijo,
                            alto: espacio.maxHeight,
                          ),
                        ),
                      );
                      final pantalla = fijo
                          ? contenido
                          : SingleChildScrollView(child: contenido);
                      // La celebración hace temblar la partida y atenúa lo
                      // que no participa en ella.
                      return ListenableBuilder(
                        listenable: _celebracion,
                        child: pantalla,
                        builder: (context, child) => Transform.translate(
                          offset: _celebracion.temblor,
                          child: Opacity(
                            opacity: 1 - _celebracion.atenuacion,
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (e.fase == FasePartida.celebrandoVictoria)
                Positioned.fill(
                  child: CelebracionVictoria(
                    key: ValueKey('celebracion_${e.tirada.id}'),
                    definicion: widget.definicion,
                    celdas: e.celdas,
                    puntos: e.puntos,
                    nave: _nave,
                    tablero: _tableroClave,
                    control: _celebracion,
                    onCompletada: () =>
                        bloc.add(CelebracionCompletada(e.tirada.id)),
                  ),
                ),
              // Los meteoros caen sobre toda la pantalla sin bloquear toques.
              if (e.animandoMeteoros)
                Positioned.fill(
                  child: MeteoritosAnimacion(
                    key: ValueKey(e.tirada.id),
                    tiradaId: e.tirada.id,
                    cargar: widget.cargarMeteoritos,
                    onImpacto: (id) => bloc.add(ImpactoConfirmado(id)),
                    onCompletada: (id) => bloc.add(MeteorosCompletados(id)),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Globo de diálogo que sale de la nave del alien.
class GloboAlien extends StatelessWidget {
  final String mensaje;
  final bool error;
  const GloboAlien({super.key, required this.mensaje, this.error = false});

  Color get _borde => error ? const Color(0xFFFF6B6B) : const Color(0xFF72E9FF);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomPaint(size: const Size(18, 9), painter: _PicoGlobo(_borde)),
      Container(
        // Reserva dos renglones para que el cambio de mensaje no mueva el
        // tablero ni los dados.
        constraints: BoxConstraints(
          minHeight: MediaQuery.textScalerOf(context).scale(16) * 1.3 * 2 + 20,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xE6102B4A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borde, width: error ? 2.5 : 1.5),
        ),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            height: 1.3,
            color: error ? const Color(0xFFFFB4B4) : const Color(0xFFB6F6FF),
          ),
        ),
      ),
    ],
  );
}

class _PicoGlobo extends CustomPainter {
  final Color color;
  const _PicoGlobo(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final pico = Path()
      ..moveTo(0, size.height + 1)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height + 1)
      ..close();
    canvas.drawPath(pico, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PicoGlobo oldDelegate) => oldDelegate.color != color;
}

/// Puntuación del jugador junto a la nave y meta para ganar.
class PanelPuntos extends StatelessWidget {
  final int puntos;
  final int meta;
  const PanelPuntos({super.key, required this.puntos, required this.meta});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Puntuación: $puntos de $meta para ganar',
    excludeSemantics: true,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        key: const ValueKey('puntuacion'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC0C2640),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF72E9FF), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x4472E9FF), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PUNTOS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Color(0xFF9FBACB),
              ),
            ),
            Text(
              '$puntos',
              style: const TextStyle(
                fontSize: 26,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB6F6FF),
              ),
            ),
            Text(
              'META $meta',
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: Color(0xFF9FBACB),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Botón compacto para omitir la tirada y pasar directamente a la siguiente.
class BotonRelanzar extends StatelessWidget {
  final VoidCallback onPressed;
  const BotonRelanzar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Volver a tirar los dados',
    excludeSemantics: true,
    child: SizedBox(
      key: const ValueKey('boton_relanzar'),
      width: 78,
      height: 78,
      child: Material(
        color: const Color(0xCC0C2640),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: Color(0xFF72E9FF), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.casino_rounded,
                    color: Color(0xFF72E9FF),
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'VOLVER\nA TIRAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Color(0xFFB6F6FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
