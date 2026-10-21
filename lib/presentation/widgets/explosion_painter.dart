import 'dart:math' as math;

import 'package:flutter/material.dart';

const _cian = Color(0xFF72E9FF);
const _dorado = Color(0xFFFFC94D);
const _naranja = Color(0xFFFF8A1F);

double _tramo(double t, double inicio, double fin) =>
    ((t - inicio) / (fin - inicio)).clamp(0.0, 1.0);

/// Partículas de una explosión, precalculadas con una semilla fija para que
/// se vea igual en cada reproducción y en las pruebas.
class ParticulasExplosion {
  final List<(double angulo, double rapidez, double vida, double grosor)>
  chispas;
  final List<(double angulo, double distancia, double radio, double retraso)>
  fuego;
  final List<(double x, double vida, double fase, double radio)> brasas;

  ParticulasExplosion(math.Random azar)
    : chispas = [
        for (var i = 0; i < 140; i++)
          (
            azar.nextDouble() * math.pi * 2,
            420 + azar.nextDouble() * 1100,
            .45 + azar.nextDouble() * .7,
            1.2 + azar.nextDouble() * 2.2,
          ),
      ],
      fuego = [
        for (var i = 0; i < 30; i++)
          (
            azar.nextDouble() * math.pi * 2,
            .15 + azar.nextDouble() * .65,
            .22 + azar.nextDouble() * .3,
            azar.nextDouble() * .12,
          ),
      ],
      brasas = [
        for (var i = 0; i < 46; i++)
          (
            azar.nextDouble() * 2 - 1,
            1 + azar.nextDouble() * 1.3,
            azar.nextDouble() * math.pi * 2,
            1.2 + azar.nextDouble() * 1.8,
          ),
      ];
}

/// Bola de fuego, ondas expansivas, chispas, brasas y humo.
class ExplosionPainter extends CustomPainter {
  final double t;
  final Offset centro;
  final double radio;
  final ParticulasExplosion particulas;

  const ExplosionPainter({
    required this.t,
    required this.centro,
    required this.radio,
    required this.particulas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0 || t > 2.6) return;
    final aditivo = Paint()..blendMode = BlendMode.plus;

    // Humo: bocanadas oscuras que suben y se disipan.
    for (final (angulo, distancia, radioBase, retraso) in particulas.fuego) {
      final vida = _tramo(t, .25 + retraso, 2.4);
      if (vida <= 0 || vida >= 1) continue;
      final d = radio * distancia * (.5 + Curves.easeOut.transform(vida) * .9);
      final p =
          centro +
          Offset(math.cos(angulo), math.sin(angulo)) * d +
          Offset(0, -70 * vida);
      final r = radio * radioBase * (1 + vida * 1.4);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF2A2F3A).withValues(alpha: .55 * (1 - vida)),
              const Color(0xFF2A2F3A).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: p, radius: r)),
      );
    }

    // Bola de fuego: bocanadas de blanco a amarillo, naranja y rojo.
    for (final (angulo, distancia, radioBase, retraso) in particulas.fuego) {
      final vida = _tramo(t, retraso, 1.15 + retraso);
      if (vida <= 0 || vida >= 1) continue;
      final expansion = Curves.easeOutCubic.transform(vida);
      final p =
          centro +
          Offset(math.cos(angulo), math.sin(angulo)) *
              (radio * distancia * expansion) +
          Offset(0, -30 * vida * vida);
      final r = radio * radioBase * (.55 + expansion * 1.1);
      final caliente = 1 - vida;
      final color = Color.lerp(
        Color.lerp(const Color(0xFFFFF6D0), _dorado, _tramo(vida, 0, .25))!,
        Color.lerp(_naranja, const Color(0xFFB3261E), _tramo(vida, .35, .9))!,
        _tramo(vida, .15, .5),
      )!;
      canvas.drawCircle(
        p,
        r,
        aditivo
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: .85 * caliente),
              color.withValues(alpha: .35 * caliente),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .45, 1],
          ).createShader(Rect.fromCircle(center: p, radius: r)),
      );
    }

    // Núcleo cegador al inicio.
    final nucleo = 1 - _tramo(t, 0, .4);
    if (nucleo > 0) {
      final r =
          radio * (.35 + Curves.easeOut.transform(_tramo(t, 0, .25)) * .7);
      canvas.drawCircle(
        centro,
        r,
        aditivo
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: nucleo),
              const Color(0xFFFFF1C2).withValues(alpha: .8 * nucleo),
              _dorado.withValues(alpha: 0),
            ],
            stops: const [0, .35, 1],
          ).createShader(Rect.fromCircle(center: centro, radius: r)),
      );
    }

    // Dos ondas expansivas: una blanca y cian, otra naranja más lenta.
    for (final (retraso, duracion, alcance, grosor, color) in [
      (0.0, .7, 2.1, 22.0, _cian),
      (.08, .95, 1.6, 10.0, _naranja),
    ]) {
      final p = _tramo(t, retraso, retraso + duracion);
      if (p <= 0 || p >= 1) continue;
      final r = radio * alcance * Curves.easeOutCubic.transform(p);
      final alfa = 1 - p;
      canvas.drawCircle(
        centro,
        r,
        aditivo
          ..shader = null
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor * (1 - p) + 2
          ..color = color.withValues(alpha: .75 * alfa)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 8 * p),
      );
      canvas.drawCircle(
        centro,
        r,
        aditivo
          ..strokeWidth = 2
          ..maskFilter = null
          ..color = Colors.white.withValues(alpha: .8 * alfa),
      );
      aditivo.style = PaintingStyle.fill;
    }
    aditivo.maskFilter = null;

    // Chispas: trazos con arrastre y gravedad.
    const arrastre = 2.6;
    const gravedad = 700.0;
    Offset posicion(double angulo, double rapidez, double s) =>
        centro +
        Offset(math.cos(angulo), math.sin(angulo)) *
            (rapidez * (1 - math.exp(-arrastre * s)) / arrastre) +
        Offset(0, .5 * gravedad * s * s);
    for (final (angulo, rapidez, vida, grosor) in particulas.chispas) {
      if (t >= vida) continue;
      final p = t / vida;
      final cabeza = posicion(angulo, rapidez, t);
      final cola = posicion(angulo, rapidez, math.max(0, t - .045));
      final color = Color.lerp(const Color(0xFFFFF6D0), _naranja, p)!;
      canvas.drawLine(
        cola,
        cabeza,
        aditivo
          ..shader = null
          ..color = color.withValues(alpha: 1 - p)
          ..strokeWidth = grosor * (1 - p * .6)
          ..strokeCap = StrokeCap.round,
      );
    }

    // Brasas que suben titilando.
    for (final (x, vida, fase, r) in particulas.brasas) {
      final s = t - .3;
      if (s <= 0 || s >= vida) continue;
      final p = s / vida;
      final punto =
          centro +
          Offset(
            x * radio * (.4 + p * .6) + math.sin(fase + s * 5) * 12,
            -radio * .9 * Curves.easeOut.transform(p) + radio * .2,
          );
      final titileo = .6 + .4 * math.sin(fase + s * 24);
      canvas.drawCircle(
        punto,
        r * 2.4,
        aditivo..color = _naranja.withValues(alpha: .35 * (1 - p) * titileo),
      );
      canvas.drawCircle(
        punto,
        r * .7,
        aditivo
          ..color = const Color(
            0xFFFFE4A8,
          ).withValues(alpha: (1 - p) * titileo),
      );
    }
  }

  @override
  bool shouldRepaint(ExplosionPainter old) =>
      old.t != t || old.centro != centro;
}
