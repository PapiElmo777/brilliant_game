import 'package:brilliant_game/presentation/widgets/nave_entrada.dart';
import 'package:brilliant_game/presentation/widgets/bandeja_numeros.dart';
import 'package:brilliant_game/bloc/inicio_estado.dart';
import 'package:brilliant_game/presentation/widgets/nave_marciano.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget escenario(Widget child, {bool reducido = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducido),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('La nave confirma una vez al llegar y no repite al reconstruir', (
    tester,
  ) async {
    var confirmaciones = 0;
    Widget nave() => escenario(
      NaveEntrada(
        llegando: true,
        onCompletada: () => confirmaciones++,
        child: const SizedBox(
          width: 170,
          child: NaveMarciano(hazActivo: false),
        ),
      ),
    );
    await tester.pumpWidget(nave());
    await tester.pump(const Duration(milliseconds: 400));
    expect(confirmaciones, 0);
    await tester.pumpAndSettle();
    expect(confirmaciones, 1);
    await tester.pumpWidget(nave());
    await tester.pumpAndSettle();
    expect(confirmaciones, 1);
  });

  testWidgets('Movimiento reducido completa la llegada sin vuelo', (
    tester,
  ) async {
    var confirmaciones = 0;
    await tester.pumpWidget(
      escenario(
        NaveEntrada(
          llegando: true,
          onCompletada: () => confirmaciones++,
          child: const Text('nave'),
        ),
        reducido: true,
      ),
    );
    await tester.pump();
    expect(confirmaciones, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Salir durante la llegada cancela su confirmación', (
    tester,
  ) async {
    var confirmaciones = 0;
    await tester.pumpWidget(
      escenario(
        NaveEntrada(
          llegando: true,
          onCompletada: () => confirmaciones++,
          child: const Text('nave'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(confirmaciones, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Los números aparecen escalonados y confirman una sola vez', (
    tester,
  ) async {
    var confirmaciones = 0;
    Widget bandeja() => escenario(
      BandejaNumeros(
        estado: InicioEstado(
          fase: FaseInicio.preparando,
          faseVisual: FaseVisualInicio.mostrandoNumeros,
          celdas: {},
          numerosFaltantes: {1, 2, 3, 4, 5, 6},
        ),
        onSeleccionado: (_) {},
        onPresentacionCompletada: () => confirmaciones++,
      ),
    );
    await tester.pumpWidget(bandeja());
    expect(
      tester
          .widgetList<Opacity>(find.byType(Opacity))
          .every((o) => o.opacity == 0),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final opacidades = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .toList();
    expect(opacidades.first.opacity, greaterThan(0));
    expect(opacidades.last.opacity, 0);
    expect(confirmaciones, 0);
    await tester.pumpAndSettle();
    expect(confirmaciones, 1);
    await tester.pumpWidget(bandeja());
    await tester.pumpAndSettle();
    expect(confirmaciones, 1);
  });
}
