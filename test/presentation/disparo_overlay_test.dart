import 'package:brilliant_game/bloc/inicio_estado.dart';
import 'package:brilliant_game/presentation/widgets/disparo_numero_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('El disparo vuela y sólo confirma una vez al reconstruir', (tester) async {
    final origen = GlobalKey();
    final destino = GlobalKey();
    var completados = 0;
    Widget pantalla({bool reducido = false}) => MaterialApp(home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducido),
      child: Scaffold(body: Stack(children: [
        Align(alignment: Alignment.topCenter, child: SizedBox(key: origen, width: 100, height: 80)),
        Align(alignment: Alignment.bottomRight, child: SizedBox(key: destino, width: 50, height: 50)),
        Positioned.fill(child: DisparoNumeroOverlay(key: const ValueKey(4), disparo: const DisparoPendiente(id: 4, numero: 3, celdaId: 'destino'), origen: origen, destino: destino, onCompletado: () => completados++)),
      ])),
    ));
    await tester.pumpWidget(pantalla());
    await tester.pump(const Duration(milliseconds: 100));
    final inicio = tester.getCenter(find.text('3'));
    await tester.pump(const Duration(milliseconds: 200));
    final medio = tester.getCenter(find.text('3'));
    expect(medio.dy, greaterThan(inicio.dy));
    expect(completados, 0);
    await tester.pumpWidget(pantalla());
    await tester.pumpAndSettle();
    expect(completados, 1);
    final llegada = tester.getCenter(find.text('3'));
    final centro = tester.getCenter(find.byKey(destino));
    expect((llegada - centro).distance, lessThan(1));
    await tester.pumpWidget(pantalla());
    await tester.pumpAndSettle();
    expect(completados, 1);
  });

  testWidgets('Movimiento reducido confirma sin dibujar el vuelo', (tester) async {
    var completados = 0;
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: DisparoNumeroOverlay(
        disparo: const DisparoPendiente(id: 1, numero: 5, celdaId: 'destino'),
        origen: GlobalKey(), destino: GlobalKey(), onCompletado: () => completados++,
      )),
    )));
    await tester.pumpAndSettle();
    expect(completados, 1);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('Desmontar durante el disparo no confirma ni deja un ticker', (tester) async {
    var completados = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DisparoNumeroOverlay(
      disparo: const DisparoPendiente(id: 1, numero: 5, celdaId: 'destino'),
      origen: GlobalKey(), destino: GlobalKey(), onCompletado: () => completados++,
    ))));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(completados, 0);
    expect(tester.takeException(), isNull);
  });
}
