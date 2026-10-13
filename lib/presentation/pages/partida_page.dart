import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/partida_bloc.dart';
import '../../bloc/partida_estado.dart';
import '../../bloc/partida_evento.dart';
import '../../catalogo/definicion_tablero.dart';
import '../widgets/boton_panel.dart';
import '../widgets/dados_partida.dart';
import '../widgets/fondo_espacial.dart';
import '../widgets/historial_tiradas.dart';
import '../widgets/meteoritos_animacion.dart';
import '../widgets/nave_marciano.dart';
import '../widgets/respuesta_error.dart';
import '../widgets/tablero_view.dart';

class PartidaPage extends StatefulWidget {
  final DefinicionTablero definicion;
  final String? jugador;
  const PartidaPage({super.key, required this.definicion, this.jugador});
  @override
  State<PartidaPage> createState() => _PartidaPageState();
}

class _PartidaPageState extends State<PartidaPage> {
  /// Debajo de esta altura no cabe la partida completa y se permite desplazar.
  static const _alturaMinima = 480.0;

  final _lienzo = GlobalKey();
  final _arriba = GlobalKey();
  final _impactos = GlobalKey();

  String _mensaje(PartidaEstado e) {
    if (e.animandoMeteoros)
      return e.fase == FasePartida.tirando
          ? (e.tirada.id == 1 ? '¡El juego comenzó!' : 'Llegan los meteoros…')
          : 'Resultados: ${e.tirada.dados.map((d) => d.valor).join(' y ')}';
    if (e.fase == FasePartida.rondaResuelta)
      return '¡Listo! Lanza otra vez los meteoros.';
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
    if (e.fase == FasePartida.rondaResuelta) {
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

  Widget _tablero(PartidaEstado e, PartidaBloc bloc) => TableroView.partida(
    definicion: widget.definicion,
    celdas: e.celdas,
    destinos: e.destinos,
    interactiva: e.puedeSeleccionar,
    onCeldaSeleccionada: (id) => bloc.add(DestinoSeleccionado(e.tirada.id, id)),
  );

  Widget _contenido(PartidaEstado e, PartidaBloc bloc, {required bool fijo}) {
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
                    onPressed: () => Navigator.of(context).pop(),
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
              const SizedBox(width: 100, child: NaveMarciano()),
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
              // Lugar de los dados bajo la nave, separado del globo.
              SizedBox(key: _arriba, height: 92, width: double.infinity),
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
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            FondoEspacial(
              child: SafeArea(
                // La partida se ajusta a la pantalla sin desplazarse; sólo en
                // alturas muy reducidas se permite el desplazamiento.
                child: LayoutBuilder(
                  builder: (context, espacio) {
                    final fijo = espacio.maxHeight >= _alturaMinima;
                    final contenido = Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _contenido(e, bloc, fijo: fijo),
                      ),
                    );
                    return fijo
                        ? contenido
                        : SingleChildScrollView(child: contenido);
                  },
                ),
              ),
            ),
            // Los meteoros caen sobre toda la pantalla sin bloquear toques.
            if (e.animandoMeteoros)
              Positioned.fill(
                child: MeteoritosAnimacion(
                  key: ValueKey(e.tirada.id),
                  tiradaId: e.tirada.id,
                  onImpacto: (id) => bloc.add(ImpactoConfirmado(id)),
                  onCompletada: (id) => bloc.add(MeteorosCompletados(id)),
                ),
              ),
          ],
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
