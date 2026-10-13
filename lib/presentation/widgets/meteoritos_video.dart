import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum ResultadoVideo { completado, movimientoReducido, fallo }

class MeteoritosVideo extends StatefulWidget {
  final int tiradaId;
  final void Function(int tiradaId, ResultadoVideo resultado) onCompletado;
  final VideoPlayerController Function()? crearController;

  const MeteoritosVideo({
    super.key,
    required this.tiradaId,
    required this.onCompletado,
    this.crearController,
  });

  @override
  State<MeteoritosVideo> createState() => _MeteoritosVideoState();
}

class _MeteoritosVideoState extends State<MeteoritosVideo> {
  VideoPlayerController? _controller;
  Timer? _limite;
  bool _iniciado = false;
  bool _terminado = false;
  int _generacion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _iniciar();
  }

  @override
  void didUpdateWidget(MeteoritosVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiradaId != widget.tiradaId) {
      _liberar();
      _iniciado = false;
      _terminado = false;
      _iniciar();
    }
  }

  void _iniciar() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _finalizar(ResultadoVideo.movimientoReducido);
      return;
    }
    if (_iniciado || _terminado) return;
    _iniciado = true;
    final generacion = _generacion;
    _limite = Timer(const Duration(seconds: 25), () {
      _finalizar(ResultadoVideo.fallo);
    });
    unawaited(_reproducir(generacion));
  }

  Future<void> _reproducir(int generacion) async {
    try {
      final controller =
          widget.crearController?.call() ??
          VideoPlayerController.asset('assets/videos/meteoritos.mp4');
      _controller = controller;
      controller.addListener(_actualizar);
      await controller.initialize();
      if (!_vigente(generacion)) return;
      await controller.setLooping(false);
      if (!_vigente(generacion)) return;
      await controller.setVolume(0);
      if (!_vigente(generacion)) return;
      await controller.play();
      if (!_vigente(generacion)) return;
      setState(() {});
    } catch (_) {
      if (_vigente(generacion)) _finalizar(ResultadoVideo.fallo);
    }
  }

  bool _vigente(int generacion) =>
      mounted && generacion == _generacion && !_terminado;

  void _actualizar() {
    final valor = _controller?.value;
    if (valor == null || _terminado) return;
    if (valor.hasError) {
      _finalizar(ResultadoVideo.fallo);
    } else if (valor.isCompleted) {
      _finalizar(ResultadoVideo.completado);
    }
  }

  void _finalizar(ResultadoVideo resultado) {
    if (_terminado) return;
    _terminado = true;
    final id = widget.tiradaId;
    _liberar();
    final generacion = _generacion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generacion != _generacion) return;
      setState(() {});
      widget.onCompletado(id, resultado);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _liberar() {
    _generacion++;
    _limite?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_actualizar);
      unawaited(_cerrar(controller));
    }
  }

  Future<void> _cerrar(VideoPlayerController controller) async {
    try {
      await Future<void>.value();
      await controller.dispose();
    } catch (_) {
      // Un error nativo al cerrar no debe bloquear la ronda.
    }
  }

  @override
  void dispose() {
    _liberar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_terminado || controller == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
