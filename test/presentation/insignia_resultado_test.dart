import 'package:brilliant_game/presentation/widgets/insignia_resultado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'El campeón anima su insignia una sola vez y termina sin un bucle',
    (tester) async {
      Widget scene() => const MaterialApp(
        home: Scaffold(body: InsigniaResultado(ganador: true, puesto: 1)),
      );
      await tester.pumpWidget(scene());
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byKey(const ValueKey('insignia_ganador')), findsOneWidget);
      expect(find.text('1.º'), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(scene());
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
  testWidgets('Movimiento reducido muestra los puestos grandes sin animación', (
    tester,
  ) async {
    for (var place = 2; place <= 6; place++) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: InsigniaResultado(
                key: ValueKey(place),
                ganador: false,
                puesto: place,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('$place.º'), findsOneWidget);
      expect(find.byKey(const ValueKey('insignia_posicion')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    }
  });
}
