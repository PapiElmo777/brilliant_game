import 'package:brilliant_game/catalogo/tablero_01.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mantener presionada una celda resalta su zona y sus puntos', (
    tester,
  ) async {
    final tocadas = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: TableroView.partida(
              definicion: tablero01,
              celdas: tablero01.crearTablero().celdas,
              destinos: const {},
              onCeldaSeleccionada: tocadas.add,
            ),
          ),
        ),
      ),
    );
    CeldaView celda(String id) =>
        tester.widget<CeldaView>(find.byKey(ValueKey('celda_$id')));

    // Las zonas verdes dan 4 · 3 · 2 puntos.
    final gesto = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('celda_f2_c1'))),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.text('Zona verde · 6 casillas'), findsOneWidget);
    expect(find.text('Al completarla: 1.º 4 · 2.º 3 · 3.º 2'), findsOneWidget);
    expect(celda('f1_c2').enZonaResaltada, isTrue);
    expect(celda('f5_c1').enZonaResaltada, isTrue);
    expect(celda('f1_c1').atenuada, isTrue);
    await gesto.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ficha_zona')), findsNothing);
    expect(celda('f1_c1').atenuada, isFalse);
    expect(tocadas, isEmpty);

    // La zona amarilla es una sola, con cinco casillas separadas.
    await tester.longPress(find.byKey(const ValueKey('celda_f1_c1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ficha_zona')), findsNothing);
    final otro = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('celda_f7_c7'))),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(find.text('Zona amarilla · 5 casillas'), findsOneWidget);
    expect(find.text('Al completarla: 1.º 8 · 2.º 6 · 3.º 4'), findsOneWidget);
    for (final id in ['f1_c1', 'f1_c7', 'f4_c4', 'f7_c1', 'f7_c7']) {
      expect(celda(id).enZonaResaltada, isTrue);
    }
    expect(celda('f1_c2').atenuada, isTrue);
    await otro.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('La ficha marca los puestos ya reclamados', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: TableroView.partida(
              definicion: tablero01,
              celdas: tablero01.crearTablero().celdas,
              destinos: const {},
              puestosReclamados: const {'azul_1': 1},
              onCeldaSeleccionada: (_) {},
            ),
          ),
        ),
      ),
    );
    final gesto = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('celda_f1_c3'))),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(find.text('Al completarla: 1.º 7 · 2.º 6 · 3.º 3'), findsOneWidget);
    expect(find.text('1.º puesto ya reclamado'), findsOneWidget);
    await gesto.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Las zonas completas se marcan sin perder su color', (
    tester,
  ) async {
    final tablero = tablero01.crearTablero();
    for (final id in ['f1_c3', 'f2_c3', 'f2_c4', 'f3_c4']) {
      tablero.colocarValor(id, 4);
    }
    tablero.colocarValor('f1_c4', 2);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: TableroView.partida(
              definicion: tablero01,
              celdas: tablero.celdas,
              destinos: const {},
              onCeldaSeleccionada: (_) {},
            ),
          ),
        ),
      ),
    );
    CeldaView celda(String id) =>
        tester.widget<CeldaView>(find.byKey(ValueKey('celda_$id')));
    // azul_1 está completa; morado_1 tiene una sola casilla ocupada.
    for (final id in ['f1_c3', 'f2_c3', 'f2_c4', 'f3_c4']) {
      expect(celda(id).completada, isTrue);
    }
    expect(celda('f1_c4').completada, isFalse);
    expect(celda('f1_c1').completada, isFalse);
    expect(
      find.bySemanticsLabel(RegExp('Fila 1, columna 3.*zona completa')),
      findsOneWidget,
    );
  });
}
