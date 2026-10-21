import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'explosion_painter.dart';

/// Duración de la explosión que sustituye a la caída cuando se omite.
const duracionExplosionOmitida = Duration(milliseconds: 1600);

/// Tiempo inicial en el que se ignoran los toques, por si el toque que lanzó
/// los meteoros fue doble.
const esperaParaOmitirCaida = Duration(milliseconds: 300);

class MeteoritosAnimacion extends StatefulWidget {
  final int tiradaId;
  final ValueChanged<int> onImpacto;
  final ValueChanged<int> onCompletada;
  final Future<ui.Codec> Function()? cargar;

  /// Multiplica la velocidad de reproducción del clip.
  final int velocidad;

  const MeteoritosAnimacion({
    super.key,
    required this.tiradaId,
    required this.onImpacto,
    required this.onCompletada,
    this.cargar,
    this.velocidad = 7,
  });

  @override
  State<MeteoritosAnimacion> createState() => _MeteoritosAnimacionState();
}

class _MeteoritosAnimacionState extends State<MeteoritosAnimacion>
    with SingleTickerProviderStateMixin {
  ui.Codec? _codec;
  ui.Image? _imagen;
  Timer? _cuadro;
  Timer? _limite;
  int _version = 0;
  int _indice = 0;
  bool _iniciada = false;
  bool _impacto = false;
  bool _terminada = false;
  Timer? _espera;
  bool _omitible = false;
  final _particulas = ParticulasExplosion(math.Random(120));

  /// Explosión dibujada que reemplaza al video al omitir la caída.
  AnimationController? _explosion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _finalizar();
    } else if (!_iniciada) {
      _iniciada = true;
      _omitible = false;
      _espera?.cancel();
      _espera = Timer(esperaParaOmitirCaida, () => _omitible = true);
      _limite = Timer(const Duration(seconds: 30), _finalizar);
      _cargar(_version);
    }
  }

  @override
  void didUpdateWidget(MeteoritosAnimacion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiradaId != widget.tiradaId) {
      _liberar();
      _indice = 0;
      _impacto = false;
      _terminada = false;
      _iniciada = false;
      _explosion?.dispose();
      _explosion = null;
      didChangeDependencies();
    }
  }

  Future<void> _cargar(int version) async {
    try {
      final codec = await (widget.cargar?.call() ?? _cargarRecurso());
      if (!mounted || version != _version || _terminada) {
        codec.dispose();
        return;
      }
      _codec = codec;
      await _siguiente(version);
    } catch (_) {
      if (mounted && version == _version) _finalizar();
    }
  }

  Future<ui.Codec> _cargarRecurso() async {
    final data = await rootBundle.load(
      'assets/videos/meteoritos_transparente.webp',
    );
    return ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<void> _siguiente(int version) async {
    if (!mounted || version != _version || _terminada) return;
    final codec = _codec;
    if (codec == null) return;
    try {
      if (_indice == codec.frameCount) {
        _finalizar();
        return;
      }
      final cuadro = await codec.getNextFrame();
      if (!mounted || version != _version || _terminada) {
        cuadro.image.dispose();
        return;
      }
      final anterior = _imagen;
      setState(() {
        _imagen = cuadro.image;
        _indice++;
      });
      _desecharImagen(anterior);
      // El impacto se revela en el cuadro 120 del recurso de 24 fps.
      if (_indice >= 120 && !_impacto) {
        _impacto = true;
        widget.onImpacto(widget.tiradaId);
      }
      _cuadro = Timer(
        cuadro.duration ~/ widget.velocidad,
        () => _siguiente(version),
      );
    } catch (_) {
      if (mounted && version == _version) _finalizar();
    }
  }

  /// Omite la caída: detiene el video, revela los números y muestra sólo la
  /// explosión final.
  void _omitir() {
    if (_terminada || _impacto || _explosion != null) return;
    if (!_omitible) return;
    _liberar();
    _impacto = true;
    widget.onImpacto(widget.tiradaId);
    setState(() {
      _explosion =
          AnimationController(vsync: this, duration: duracionExplosionOmitida)
            ..addStatusListener((estado) {
              if (estado == AnimationStatus.completed) _finalizar();
            })
            ..forward();
    });
  }

  void _finalizar() {
    if (_terminada) return;
    _terminada = true;
    final id = widget.tiradaId;
    final impactoPendiente = !_impacto;
    _impacto = true;
    _liberar();
    final version = _version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _version) return;
      setState(() {});
      if (impactoPendiente) widget.onImpacto(id);
      widget.onCompletada(id);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _desecharImagen(ui.Image? imagen) {
    if (imagen == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => imagen.dispose());
    WidgetsBinding.instance.scheduleFrame();
  }

  void _liberar() {
    _version++;
    _cuadro?.cancel();
    _limite?.cancel();
    _codec?.dispose();
    _codec = null;
    _desecharImagen(_imagen);
    _imagen = null;
  }

  @override
  void dispose() {
    _liberar();
    _espera?.cancel();
    _explosion?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explosion = _explosion;
    final puedeOmitir = !_terminada && !_impacto && explosion == null;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ExcludeSemantics(
            child: RawImage(
              image: _imagen,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
        if (explosion != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: explosion,
              builder: (context, _) {
                final segundos =
                    explosion.value *
                    duracionExplosionOmitida.inMilliseconds /
                    1000;
                return Opacity(
                  // El humo se desvanece antes de que se retire la capa.
                  opacity: (1 - (segundos - 1.2) / .4).clamp(0.0, 1.0),
                  child: LayoutBuilder(
                    builder: (context, espacio) => CustomPaint(
                      size: espacio.biggest,
                      // Mismo lugar donde estalla el video.
                      painter: ExplosionPainter(
                        t: segundos,
                        centro: Offset(
                          espacio.maxWidth / 2,
                          espacio.maxHeight * .84,
                        ),
                        radio: espacio.maxWidth * .42,
                        particulas: _particulas,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (puedeOmitir) ...[
          // Tocar durante la caída la omite. El toque también llega a lo que
          // está debajo, como la flecha para volver al menú.
          Semantics(
            button: true,
            label: 'Omitir la caída de los meteoritos',
            onTap: _omitir,
            child: Listener(
              key: const ValueKey('omitir_meteoritos'),
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) => _omitir(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: const IgnorePointer(
              child: Text(
                'Toca para omitir',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: Color(0xCCB6F6FF),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
