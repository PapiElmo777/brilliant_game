import 'dart:ui' as ui;
import 'package:brilliant_game/presentation/pages/preparacion_page.dart';
import 'package:brilliant_game/presentation/pages/seleccion_nivel_page.dart';
import 'package:brilliant_game/presentation/widgets/celebracion_victoria.dart';
import 'package:brilliant_game/presentation/widgets/fondo_espacial.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/flujo_niveles.dart';
import '../support/recorridos_niveles.dart';

void main() {
  for (final nivel in [1, 2, 3, 4]) {
    testWidgets(
      'Nivel $nivel: del selector a victoria y reinicio del mismo nivel',
      (tester) async {
        pantallaNivel(tester);
        final camino = caminosNiveles[nivel]!;
        final dados = DadosNivel([
          for (final paso in camino) ...[paso.$2, paso.$3],
        ]);
        await selectorNivel(tester, dados: dados);
        await escogerNivel(tester, nivel);
        naveDelNivel(tester, nivel);
        expect(
          tester.widget<FondoEspacial>(find.byType(FondoEspacial)).ruta,
          'assets/images/backgrounds/Nivel $nivel.png',
        );
        await prepararNivel(tester, nivel);
        await pulsarNivel(tester, find.byKey(const ValueKey('boton_inicio')));
        for (var i = 0; i < camino.length; i++) {
          final (id, valor, _, puntos) = camino[i];
          await pulsarNivel(tester, find.byKey(const ValueKey('dado_0')));
          final celda = find.byKey(ValueKey('celda_$id'));
          expect(
            tester.widget<CeldaView>(celda).esDestino,
            isTrue,
            reason: 'Nivel $nivel ronda ${i + 1}: $id',
          );
          if (i == camino.length - 1) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: false);
            await tester.pump();
            await tester.ensureVisible(celda);
            await tester.tap(celda);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(CelebracionVictoria), findsOneWidget);
            naveDelNivel(tester, nivel);
            await tester.pump(const Duration(seconds: 2));
            expect(tester.takeException(), isNull);
            await tester.pump(const Duration(seconds: 5));
            await tester.pumpAndSettle();
            expect(find.text('RESULTADOS'), findsOneWidget);
            expect(
              find.bySemanticsLabel(RegExp('^Lugar 1: Ana, $puntos puntos')),
              findsOneWidget,
            );
          } else {
            await pulsarNivel(tester, celda);
            expect(tester.widget<CeldaView>(celda).celda.valor, valor);
            expect(
              find.descendant(
                of: find.byKey(const ValueKey('puntuacion')),
                matching: find.text('$puntos'),
              ),
              findsOneWidget,
            );
            await pulsarNivel(
              tester,
              find.byKey(const ValueKey('boton_lanzar')),
            );
          }
        }
        expect(dados.llamadas, camino.length * 2);
        expect(
          tester.widget<FondoEspacial>(find.byType(FondoEspacial)).ruta,
          'assets/images/backgrounds/Nivel $nivel.png',
        );
        await pulsarNivel(
          tester,
          find.byKey(const ValueKey('boton_empezar_de_nuevo')),
        );
        expect(find.byType(PreparacionPage), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(
          tester
              .widget<PreparacionPage>(find.byType(PreparacionPage))
              .definicion
              .id,
          'tablero_0$nivel',
        );
        naveDelNivel(tester, nivel);
        expect(
          tester
              .widgetList<CeldaView>(find.byType(CeldaView))
              .every((c) => c.celda.valor == null),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'El selector admite accesibilidad y recupera un nombre inválido',
    (tester) async {
      pantallaNivel(tester);
      await selectorNivel(tester);
      final semantica = tester.getSemantics(
        find.bySemanticsLabel('Elegir Nivel 1'),
      );
      expect(
        semantica.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      await pulsarNivel(
        tester,
        find.byKey(const ValueKey('elegir_tablero_01')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('campo_nombre')),
        '😀' * 9,
      );
      await tester.pump();
      await pulsarNivel(tester, find.byKey(const ValueKey('confirmar_nombre')));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('El nombre admite hasta 16 caracteres.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('campo_nombre')), 'Ana');
      await tester.pump();
      await pulsarNivel(tester, find.byKey(const ValueKey('confirmar_nombre')));
      expect(find.byType(PreparacionPage), findsOneWidget);
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(844, 390),
  ]) {
    testWidgets('Selector y nave de Nivel 4 con texto ampliado en $size', (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: 1.5);
      await selectorNivel(tester);
      await escogerNivel(tester, 4);
      expect(tester.widgetList<CeldaView>(find.byType(CeldaView)).length, 49);
      naveDelNivel(tester, 4);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Cancelar el nombre permite elegir otro nivel sin duplicar diálogos',
    (tester) async {
      pantallaNivel(tester);
      await selectorNivel(tester);
      final nivel = find.byKey(const ValueKey('elegir_tablero_02'));
      await tester.ensureVisible(nivel);
      await tester.tap(nivel);
      await tester.tap(nivel, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await pulsarNivel(tester, find.text('Cancelar'));
      expect(find.byType(SeleccionNivelPage), findsOneWidget);
      await escogerNivel(tester, 3);
      naveDelNivel(tester, 3);
    },
  );
}
