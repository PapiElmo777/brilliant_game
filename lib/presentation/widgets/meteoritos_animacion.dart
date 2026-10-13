import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.velocidad = 3,
  });

  @override
  State<MeteoritosAnimacion> createState() => _MeteoritosAnimacionState();
}

class _MeteoritosAnimacionState extends State<MeteoritosAnimacion> {
  ui.Codec? _codec;
  ui.Image? _imagen;
  Timer? _cuadro;
  Timer? _limite;
  int _version = 0;
  int _indice = 0;
  bool _iniciada = false;
  bool _impacto = false;
  bool _terminada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _finalizar();
    } else if (!_iniciada) {
      _iniciada = true;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RawImage(
        image: _imagen,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
      ),
    ),
  );
}
