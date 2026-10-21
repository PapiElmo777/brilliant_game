import 'dart:async';
import 'dart:ui' as ui;
import 'package:brilliant_game/presentation/widgets/meteoritos_animacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CuadroPrueba implements ui.FrameInfo {
  @override
  final ui.Image image;
  @override
  Duration get duration => const Duration(milliseconds: 70);
  CuadroPrueba(this.image);
}

class CodecPrueba implements ui.Codec {
  final ui.Image imagen;
  int cuadros = 0;
  bool cerrado = false;
  CodecPrueba(this.imagen);
  @override
  int get frameCount => 122;
  @override
  int get repetitionCount => -1;
  @override
  Future<ui.FrameInfo> getNextFrame() async {
    cuadros++;
    return CuadroPrueba(imagen.clone());
  }

  @override
  void dispose() {
    cerrado = true;
  }
}

void main() {
  late ui.Image imagen;
  setUp(() async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = Colors.red);
    final picture = recorder.endRecording();
    imagen = await picture.toImage(2, 2);
    picture.dispose();
  });
  tearDown(() => imagen.dispose());
  // Los cuadros duran 70 ms y se reproducen cada 10 ms (velocidad x7).
  testWidgets(
    'Impacto y final se confirman una vez a velocidad x7 sin reiniciar',
    (tester) async {
      final codec = CodecPrueba(imagen);
      final eventos = <String>[];
      var cargas = 0;
      Widget pantalla() => MaterialApp(
        home: MeteoritosAnimacion(
          tiradaId: 7,
          cargar: () async {
            cargas++;
            return codec;
          },
          onImpacto: (id) => eventos.add('impacto$id'),
          onCompletada: (id) => eventos.add('fin$id'),
        ),
      );
      await tester.pumpWidget(pantalla());
      for (var i = 0; i < 118; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(eventos, isEmpty);
      await tester.pumpWidget(pantalla());
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(eventos, ['impacto7', 'fin7']);
      expect(cargas, 1);
      expect(codec.cuadros, 122);
      await tester.pumpWidget(pantalla());
      await tester.pump();
      expect(eventos.length, 2);
      expect(codec.cerrado, isTrue);
    },
  );
  testWidgets('Movimiento reducido y error mantienen las confirmaciones', (
    tester,
  ) async {
    for (final reducido in [true, false]) {
      final eventos = <int>[];
      var cargas = 0;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(reducido),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducido),
            child: MeteoritosAnimacion(
              tiradaId: 2,
              cargar: () async {
                cargas++;
                throw StateError('Error de recurso');
              },
              onImpacto: eventos.add,
              onCompletada: eventos.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(eventos, [2, 2]);
      expect(cargas, reducido ? 0 : 1);
    }
  });
  testWidgets('Salir durante carga descarta confirmaciones y libera el codec', (
    tester,
  ) async {
    final carga = Completer<ui.Codec>();
    final codec = CodecPrueba(imagen);
    final eventos = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MeteoritosAnimacion(
          tiradaId: 3,
          cargar: () => carga.future,
          onImpacto: eventos.add,
          onCompletada: eventos.add,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    carga.complete(codec);
    await tester.pump();
    expect(eventos, isEmpty);
    expect(codec.cerrado, isTrue);
  });
  testWidgets('Carga detenida permite continuar tras el límite', (
    tester,
  ) async {
    final carga = Completer<ui.Codec>();
    final eventos = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MeteoritosAnimacion(
          tiradaId: 4,
          cargar: () => carga.future,
          onImpacto: eventos.add,
          onCompletada: eventos.add,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(eventos, [4, 4]);
    final codec = CodecPrueba(imagen);
    carga.complete(codec);
    await tester.pump();
    expect(codec.cerrado, isTrue);
  });

  testWidgets('Tocar durante la caída la omite y muestra sólo la explosión', (
    tester,
  ) async {
    final codec = CodecPrueba(imagen);
    final eventos = <String>[];
    var toquesAbajo = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Center(
              child: TextButton(
                onPressed: () => toquesAbajo++,
                child: const Text('Debajo'),
              ),
            ),
            Positioned.fill(
              child: MeteoritosAnimacion(
                tiradaId: 5,
                cargar: () async => codec,
                onImpacto: (id) => eventos.add('impacto$id'),
                onCompletada: (id) => eventos.add('fin$id'),
              ),
            ),
          ],
        ),
      ),
    );
    // Un toque inmediato se ignora, por si el lanzamiento fue un doble toque.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(eventos, isEmpty);
    expect(find.text('Toca para omitir'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final cuadrosAntes = codec.cuadros;
    expect(cuadrosAntes, lessThan(120));
    // El toque llega también a lo que está debajo.
    await tester.tap(find.text('Debajo'));
    await tester.pump();
    expect(toquesAbajo, 1);
    expect(eventos, ['impacto5']);
    expect(codec.cerrado, isTrue);
    expect(find.text('Toca para omitir'), findsNothing);
    // Otro toque no repite el impacto.
    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(milliseconds: 800));
    expect(eventos, ['impacto5']);
    expect(codec.cuadros, cuadrosAntes);
    await tester.pump(duracionExplosionOmitida);
    await tester.pump();
    expect(eventos, ['impacto5', 'fin5']);
    expect(tester.takeException(), isNull);
  });
}
