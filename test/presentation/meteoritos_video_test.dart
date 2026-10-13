import 'dart:async';

import 'package:brilliant_game/presentation/widgets/meteoritos_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class VideoPrueba extends VideoPlayerController {
  int reproducciones = 0;
  bool cerrado = false;
  bool falla = false;
  Completer<void>? carga;

  VideoPrueba() : super.asset('prueba');

  @override
  Future<void> initialize() async {
    await carga?.future;
    if (falla) throw StateError('Sin video');
  }

  @override
  Future<void> setLooping(bool looping) async {
    expect(looping, isFalse);
  }

  @override
  Future<void> setVolume(double volume) async {
    expect(volume, 0);
  }

  @override
  Future<void> play() async => reproducciones++;

  @override
  Future<void> dispose() async {
    cerrado = true;
    await super.dispose();
  }

  void completar() {
    value = value.copyWith(isCompleted: true);
  }
}

void main() {
  late VideoPrueba video;
  late List<(int, ResultadoVideo)> resultados;
  setUp(() {
    video = VideoPrueba();
    resultados = [];
  });

  Widget pantalla({int id = 1, bool reducido = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducido),
      child: SizedBox(
        width: 200,
        height: 300,
        child: MeteoritosVideo(
          tiradaId: id,
          crearController: () => video,
          onCompletado: (id, resultado) => resultados.add((id, resultado)),
        ),
      ),
    ),
  );

  testWidgets('Reproduce y confirma una vez aunque se reconstruya', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla());
    await tester.pump();
    await tester.pumpWidget(pantalla());
    expect(video.reproducciones, 1);
    video.completar();
    await tester.pump();
    await tester.pumpWidget(pantalla());
    expect(resultados, [(1, ResultadoVideo.completado)]);
    expect(video.cerrado, isTrue);
  });

  testWidgets('Movimiento reducido omite la reproducción', (tester) async {
    await tester.pumpWidget(pantalla(reducido: true));
    await tester.pump();
    expect(video.reproducciones, 0);
    expect(resultados, [(1, ResultadoVideo.movimientoReducido)]);
  });

  testWidgets('Fallo de carga permite continuar', (tester) async {
    video.falla = true;
    await tester.pumpWidget(pantalla());
    await tester.pump();
    expect(resultados, [(1, ResultadoVideo.fallo)]);
  });

  testWidgets('Fallo durante reproducción confirma una vez', (tester) async {
    await tester.pumpWidget(pantalla());
    await tester.pump();
    video.value = VideoPlayerValue.erroneous('Error nativo');
    await tester.pump();
    expect(resultados, [(1, ResultadoVideo.fallo)]);
  });

  testWidgets('Una reproducción detenida no bloquea indefinidamente', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla());
    await tester.pump(const Duration(seconds: 26));
    expect(resultados, [(1, ResultadoVideo.fallo)]);
  });

  testWidgets('Salir durante la carga no confirma ni reproduce', (
    tester,
  ) async {
    final carga = Completer<void>();
    video.carga = carga;
    await tester.pumpWidget(pantalla());
    await tester.pumpWidget(const SizedBox());
    carga.complete();
    await tester.pump();
    expect(resultados, isEmpty);
    expect(video.reproducciones, 0);
    expect(video.cerrado, isTrue);
  });

  testWidgets('Cambiar tirada descarta la carga anterior', (tester) async {
    final carga = Completer<void>();
    final anterior = video..carga = carga;
    await tester.pumpWidget(pantalla());
    video = VideoPrueba();
    await tester.pumpWidget(pantalla(id: 2));
    await tester.pump();
    carga.complete();
    await tester.pump();
    expect(anterior.reproducciones, 0);
    expect(video.reproducciones, 1);
    video.completar();
    await tester.pump();
    expect(resultados, [(2, ResultadoVideo.completado)]);
  });
}
