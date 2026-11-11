import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../multiplayer/rooms_cubit.dart';

class TiempoRondaOnline extends StatelessWidget {
  final RoomsCubit rooms;
  final String roundId;
  final int initialSeconds;
  const TiempoRondaOnline({
    super.key,
    required this.rooms,
    required this.roundId,
    required this.initialSeconds,
  });
  @override
  Widget build(BuildContext context) =>
      BlocSelector<RoomsCubit, RoomsState, int?>(
        bloc: rooms,
        selector: (s) => s.secondsRemaining,
        builder: (context, seconds) => AlertaTiempoRonda(
          roundId: roundId,
          seconds: seconds ?? initialSeconds,
        ),
      );
}

class AlertaTiempoRonda extends StatefulWidget {
  final String roundId;
  final int seconds;
  const AlertaTiempoRonda({
    super.key,
    required this.roundId,
    required this.seconds,
  });
  @override
  State<AlertaTiempoRonda> createState() => _AlertaTiempoRondaState();
}

class _AlertaTiempoRondaState extends State<AlertaTiempoRonda>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Timer? _thirtyTimer;
  bool _thirty = false, _started = false, _thirtyShown = false;
  bool get _urgent => widget.seconds > 0 && widget.seconds <= 10;
  void _animate() {
    if (!MediaQuery.disableAnimationsOf(context)) _pulse.forward(from: 0);
  }

  void _update(int? previous) {
    if (widget.seconds <= 0) {
      _thirtyTimer?.cancel();
      _thirty = false;
      _pulse.stop();
      return;
    }
    if (_urgent) {
      _thirtyTimer?.cancel();
      _thirty = false;
      _animate();
    } else if (!_thirtyShown &&
        ((previous == null && widget.seconds == 30) ||
            (previous != null && previous > 30 && widget.seconds <= 30))) {
      _thirty = true;
      _thirtyShown = true;
      _animate();
      _thirtyTimer?.cancel();
      _thirtyTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _thirty = false);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _update(null);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void didUpdateWidget(AlertaTiempoRonda oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roundId != oldWidget.roundId) {
      _thirtyShown = false;
      _thirtyTimer?.cancel();
      _thirty = false;
      _pulse.stop();
      _pulse.value = 0;
      _update(null);
    } else if (widget.seconds != oldWidget.seconds) {
      _update(oldWidget.seconds);
    }
  }

  @override
  void dispose() {
    _thirtyTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_thirty && !_urgent) return const SizedBox.shrink();
    final color = _urgent ? const Color(0xFFFF7D7D) : const Color(0xFFFFD583);
    return Semantics(
      liveRegion: true,
      label: 'Quedan ${widget.seconds} segundos para terminar la ronda',
      child: LayoutBuilder(
        builder: (context, space) {
          final d = math.min(82.0, math.min(space.maxWidth, space.maxHeight));
          return Center(
            child: SizedBox.square(
              dimension: d,
              child: AnimatedBuilder(
                animation: _pulse,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _urgent ? 'ÚLTIMOS' : 'TIEMPO',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: d * .10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      '${widget.seconds}',
                      key: ValueKey(
                        _urgent ? 'contador_urgente' : 'aviso_30_segundos',
                      ),
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: d * .43,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      'SEGUNDOS',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: d * .09,
                        letterSpacing: .8,
                        color: color,
                      ),
                    ),
                  ],
                ),
                builder: (context, child) => Transform.scale(
                  scale:
                      1 +
                      math.sin(_pulse.value * math.pi) * (_urgent ? .10 : .18),
                  child: CustomPaint(
                    painter: _RadarTiempo(
                      color,
                      _urgent ? widget.seconds / 10 : 1,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadarTiempo extends CustomPainter {
  final Color color;
  final double fraction;
  const _RadarTiempo(this.color, this.fraction);
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - 3;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xE6081728));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, p..color = color.withValues(alpha: .18));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0, 1),
      false,
      p..color = color,
    );
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final offset = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + offset * (radius - 1),
        center + offset * (radius + 3),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarTiempo old) =>
      old.color != color || old.fraction != fraction;
}
