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
import '../widgets/diseno_juego_fijo.dart';
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

  Widget _globo(PartidaEstado e, {bool compacto = false}) => Semantics(
    liveRegion: true,
    // Las jugadas no válidas se avisan en el globo con una sacudida.
    child: e.error == null
        ? GloboAlien(mensaje: _mensaje(e), compacto: compacto)
        : RespuestaError(
            key: ObjectKey(e),
            child: GloboAlien(
              mensaje: e.error!,
              error: true,
              compacto: compacto,
            ),
          ),
  );

  /// El botón ocupa el lugar de los impactos cuando los dados ya subieron.
  Widget? _boton(PartidaEstado e, PartidaBloc bloc) {
    if (!e.dadosArriba) return null;
    if (e.fase == FasePartida.rondaResuelta && !e.gano) {
      return BotonPanel(
        key: const ValueKey('boton_lanzar'),
        texto: 'LANZAR METEOROS',
        compacto: true,
        icono: Icons.bolt,
        onPressed: () => bloc.add(MeteorosSolicitados(e.tirada.id)),
      );
    }
    if (e.puedeOmitir) {
      return BotonPanel(
        key: const ValueKey('boton_omitir'),
        texto: 'OMITIR TIRO',
        compacto: true,
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

  Widget _contenido(PartidaEstado e, PartidaBloc bloc, BoxConstraints espacio) {
    final m = MedidasJuegoFijo(espacio);
    final ancho = m.anchoPanel;
    final naveAncho = m.compacto
        ? 56.0
        : (espacio.maxHeight * .17).clamp(110.0, 160.0);
    final naveAlto =
        naveAncho / (widget.definicion.recursos?.proporcionNave ?? 1.65);
    final numeroAlto = widget.definicion.recursos == null
        ? 0.0
        : FondoEspacial.altoNumero(ancho);
    final etiquetaAlto = MediaQuery.textScalerOf(context).scale(12) * 1.3;
    final globoAlto = MediaQuery.textScalerOf(context).scale(16) * 1.3 * 2 + 29;
    Widget nave() => _ocultable(
      oculto: () => _celebracion.ocultarNave,
      SizedBox(
        key: _nave,
        width: naveAncho,
        child: NaveMarciano(recursos: widget.definicion.recursos),
      ),
    );
    Widget globo(bool compacto) => FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: compacto ? ancho - 88 : ancho,
        child: _globo(e, compacto: compacto),
      ),
    );
    final superior = m.compacto
        ? SizedBox(
            height: 68,
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        child: NumeroFondoNivel(
                          ruta: widget.definicion.recursos?.fondo,
                          compacto: true,
                        ),
                      ),
                      nave(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 22,
                        child: PanelPuntos(
                          puntos: e.puntos,
                          meta: e.meta,
                          compacto: true,
                        ),
                      ),
                      Expanded(child: globo(true)),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              SizedBox(
                height: numeroAlto,
                child: NumeroFondoNivel(
                  ruta: widget.definicion.recursos?.fondo,
                ),
              ),
              SizedBox(
                height: naveAlto,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(),
                    nave(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: PanelPuntos(puntos: e.puntos, meta: e.meta),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: etiquetaAlto,
                child: Text(
                  widget.jugador == null
                      ? 'MISIÓN INICIADA'
                      : 'MISIÓN DE ${widget.jugador!.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, letterSpacing: 1.5),
                ),
              ),
              SizedBox(height: globoAlto, child: globo(false)),
            ],
          );
    final altoSuperior = m.compacto
        ? 68.0
        : numeroAlto + naveAlto + etiquetaAlto + globoAlto;
    final boton = _boton(e, bloc);
    return Stack(
      key: _lienzo,
      children: [
        DisenoJuegoFijo(
          medidas: m,
          altoControles: altoSuperior + 80,
          cabecera: Row(
            children: [
              IconButton(
                tooltip: 'Volver al menú',
                constraints: BoxConstraints.tightFor(
                  width: 40,
                  height: m.altoCabecera,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => _regresar(e, bloc),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: m.compacto
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'BRILLIANT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                widget.jugador == null
                                    ? 'MISIÓN INICIADA'
                                    : 'MISIÓN DE ${widget.jugador!.toUpperCase()}',
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Text(
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
          controles: Column(
            children: [
              superior,
              SizedBox(
                key: _arriba,
                height: 80,
                width: double.infinity,
                child: e.puedeRelanzar
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: BotonRelanzar(
                          tamano: m.compacto ? 56 : 64,
                          onPressed: () =>
                              bloc.add(DadosRelanzados(e.tirada.id)),
                        ),
                      )
                    : null,
              ),
            ],
          ),
          tablero: _tablero(e, bloc),
          pie: SizedBox(
            key: _impactos,
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
                numeroEnContenido: true,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, espacio) {
                      final pantalla = _contenido(e, bloc, espacio);
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
  final bool compacto;
  const GloboAlien({
    super.key,
    required this.mensaje,
    this.error = false,
    this.compacto = false,
  });

  Color get _borde => error ? const Color(0xFFFF6B6B) : const Color(0xFF72E9FF);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomPaint(
        size: compacto ? const Size(12, 6) : const Size(18, 9),
        painter: _PicoGlobo(_borde),
      ),
      Container(
        // Reserva dos renglones para que el cambio de mensaje no mueva el
        // tablero ni los dados.
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.textScalerOf(context).scale(compacto ? 12 : 16) *
                  (compacto ? 1.2 : 1.3) *
                  2 +
              (compacto ? 12 : 20),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 8 : 16,
          vertical: compacto ? 6 : 10,
        ),
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
            fontSize: compacto ? 12 : 16,
            height: compacto ? 1.2 : 1.3,
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
  final bool compacto;
  const PanelPuntos({
    super.key,
    required this.puntos,
    required this.meta,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Puntuación: $puntos de $meta para ganar',
    excludeSemantics: true,
    child: compacto
        ? Container(
            key: const ValueKey('puntuacion'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xCC0C2640),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF72E9FF)),
            ),
            child: FittedBox(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PUNTOS', style: TextStyle(fontSize: 10)),
                  Text(
                    '$puntos',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(' / $meta', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          )
        : FittedBox(
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
  final double tamano;
  const BotonRelanzar({super.key, required this.onPressed, this.tamano = 78});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Volver a tirar los dados',
    excludeSemantics: true,
    child: SizedBox(
      key: const ValueKey('boton_relanzar'),
      width: tamano,
      height: tamano,
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
