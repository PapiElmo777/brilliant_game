import 'package:brilliant_game/presentation/widgets/alerta_tiempo_ronda.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Puede desmontarse antes de alcanzar alguna alerta de tiempo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlertaTiempoRonda(roundId: 'r1', seconds: 60)),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Pulso a 30, vuelve a normal y muestra la cuenta de los últimos diez',
    (tester) async {
      Future<void> scene(int seconds, {String round = 'r1'}) =>
          tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 90,
                  height: 90,
                  child: AlertaTiempoRonda(roundId: round, seconds: seconds),
                ),
              ),
            ),
          );
      await scene(31);
      expect(find.byKey(const ValueKey('aviso_30_segundos')), findsNothing);
      await scene(30);
      expect(find.text('30'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('aviso_30_segundos')), findsNothing);
      await scene(31);
      await scene(30);
      expect(find.byKey(const ValueKey('aviso_30_segundos')), findsNothing);
      await scene(10);
      expect(find.byKey(const ValueKey('contador_urgente')), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      await scene(9);
      expect(find.text('9'), findsOneWidget);
      await scene(60, round: 'r2');
      expect(find.byKey(const ValueKey('contador_urgente')), findsNothing);
      await scene(30, round: 'r2');
      expect(find.text('30'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    },
  );
  testWidgets(
    'Al volver con 8 segundos avisa de inmediato, sin animar si se pide movimiento reducido',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SizedBox(
                width: 60,
                height: 60,
                child: AlertaTiempoRonda(roundId: 'r1', seconds: 8),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('8'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
