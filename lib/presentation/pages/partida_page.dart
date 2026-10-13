import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/partida_bloc.dart';
import '../../bloc/partida_estado.dart';
import '../../bloc/partida_evento.dart';
import '../../catalogo/definicion_tablero.dart';
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
  final _lienzo = GlobalKey();
  final _arriba = GlobalKey();
  final _impactos = GlobalKey();
  final _scroll = ScrollController();
  int? _tiradaVisible;

  void _mostrarImpactos(int id) {
    if (_tiradaVisible == id) return;
    _tiradaVisible = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _impactos.currentContext != null) {
        Scrollable.ensureVisible(_impactos.currentContext!, alignment: 1);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _mensaje(PartidaEstado e) {
    if (e.animandoMeteoros)
      return e.fase == FasePartida.tirando
          ? (e.tirada.id == 1 ? '¡El juego comenzó!' : 'Llegan los meteoros…')
          : 'Resultados: ${e.tirada.dados.map((d) => d.valor).join(' y ')}';
    if (e.fase == FasePartida.rondaResuelta)
      return 'Ronda resuelta. Puedes lanzar de nuevo.';
    if (e.ancla != null) return 'Tu ancla es el ${e.ancla!.valor}';
    return e.puedeOmitir
        ? 'Ninguno de los dados tiene destinos disponibles.'
        : 'Elige el número que quieres colocar.';
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PartidaBloc, PartidaEstado>(
    builder: (context, e) {
      _mostrarImpactos(e.tirada.id);
      final bloc = context.read<PartidaBloc>();
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            FondoEspacial(
              child: SafeArea(
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics:
                      e.animandoMeteoros || e.fase == FasePartida.moviendoDados
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        child: Stack(
                          key: _lienzo,
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Volver al menú',
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                      ),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'BRILLIANT',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
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
                                const SizedBox(
                                  width: 130,
                                  child: NaveMarciano(),
                                ),
                                Text(
                                  widget.jugador == null
                                      ? 'MISIÓN INICIADA'
                                      : 'MISIÓN DE ${widget.jugador!.toUpperCase()}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  liveRegion: true,
                                  // Las jugadas no válidas se avisan en el globo
                                  // con una sacudida.
                                  child: e.error == null
                                      ? GloboAlien(mensaje: _mensaje(e))
                                      : RespuestaError(
                                          key: ObjectKey(e),
                                          child: GloboAlien(
                                            mensaje: e.error!,
                                            error: true,
                                          ),
                                        ),
                                ),
                                SizedBox(
                                  key: _arriba,
                                  height: 80,
                                  width: double.infinity,
                                ),
                                if (e.fase == FasePartida.eligiendoDestino &&
                                    e.destinos.isEmpty &&
                                    !e.puedeOmitir)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'Cambia el número seleccionado para encontrar destinos.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                TableroView.partida(
                                  definicion: widget.definicion,
                                  celdas: e.celdas,
                                  destinos: e.destinos,
                                  interactiva: e.puedeSeleccionar,
                                  onCeldaSeleccionada: (id) => bloc.add(
                                    DestinoSeleccionado(e.tirada.id, id),
                                  ),
                                ),
                                SizedBox(
                                  key: _impactos,
                                  height: 260,
                                  width: double.infinity,
                                ),
                                if (e.puedeOmitir)
                                  ElevatedButton(
                                    onPressed: () =>
                                        bloc.add(TiroOmitido(e.tirada.id)),
                                    child: const Text('Omitir tiro'),
                                  ),
                                if (e.fase == FasePartida.rondaResuelta)
                                  ElevatedButton.icon(
                                    onPressed: () => bloc.add(
                                      MeteorosSolicitados(e.tirada.id),
                                    ),
                                    icon: const Icon(Icons.bolt),
                                    label: const Text('Lanzar meteoros'),
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
                                onMovimientoCompletado: () {
                                  bloc.add(
                                    MovimientoDadosCompletado(e.tirada.id),
                                  );
                                  if (_arriba.currentContext != null)
                                    Scrollable.ensureVisible(
                                      _arriba.currentContext!,
                                      alignment: .2,
                                      duration:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? Duration.zero
                                          : const Duration(milliseconds: 350),
                                    );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xE6102B4A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borde, width: error ? 2.5 : 1.5),
        ),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
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
