import 'package:brilliant_game/bloc/partida_estado.dart';
import 'package:brilliant_game/presentation/widgets/resultados_partida.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resultados = [
    ResultadoJugador(
      jugadorId: 'jugador_1',
      nombre: 'Babo',
      puntos: 26,
      zonasCompletadas: 4,
      posicion: 1,
      esLocal: true,
    ),
  ];

  for (final (size, escala, reducido) in [
    (const Size(320, 568), 1.5, false),
    (const Size(430, 932), 1.0, true),
    (const Size(844, 390), 1.0, false),
  ]) {
    testWidgets('Muestra ranking y opciones en $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final acciones = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(escala),
              disableAnimations: reducido,
            ),
            child: Scaffold(
              body: ResultadosPartida(
                resultados: resultados,
                meta: 26,
                onEmpezarDeNuevo: () => acciones.add('empezar'),
                onSalirAlMenu: () => acciones.add('salir'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('RESULTADOS'), findsOneWidget);
      expect(find.text('Babo'), findsOneWidget);
      expect(find.text('4 zonas completadas'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Lugar 1: Babo, 26 puntos, 4 zonas completadas',
        ),
        findsOneWidget,
      );
      for (final (clave, accion) in [
        ('boton_empezar_de_nuevo', 'empezar'),
        ('boton_salir_menu', 'salir'),
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(clave)));
        await tester.tap(find.byKey(ValueKey(clave)));
        await tester.pumpAndSettle();
        expect(acciones.last, accion);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
