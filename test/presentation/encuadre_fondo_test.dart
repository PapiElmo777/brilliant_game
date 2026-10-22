import 'package:brilliant_game/presentation/widgets/nave_marciano.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/flujo_niveles.dart';

void comprobarNumero(WidgetTester tester) {
  final franja = tester.getRect(
    find.byKey(const ValueKey('numero_fondo_nivel')),
  );
  final nave = tester.getRect(find.byType(NaveMarciano));
  final escala = franja.width / 841;
  final numero = Rect.fromLTRB(
    franja.center.dx - 50 * escala,
    franja.top + 44 * escala,
    franja.center.dx + 50 * escala,
    franja.top + 112 * escala,
  );
  expect(
    numero.top,
    greaterThanOrEqualTo(tester.getRect(find.text('BRILLIANT')).bottom),
  );
  expect(numero.bottom, lessThan(nave.top));
  expect(nave.top - numero.bottom, inInclusiveRange(7.5, 24));
  expect(numero.left, greaterThanOrEqualTo(0));
  expect(numero.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(tester.takeException(), isNull);
}

void main() {
  for (final (nivel, size, escala) in [
    (1, const Size(393, 873), 1.0),
    (2, const Size(393, 873), 1.0),
    (3, const Size(393, 873), 1.0),
    (4, const Size(393, 873), 1.0),
    (3, const Size(320, 568), 1.5),
    (3, const Size(844, 390), 1.0),
  ]) {
    testWidgets('Número del Nivel $nivel sobre la nave con barras en $size', (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: escala);
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      await selectorNivel(tester, dados: DadosNivel([1, 1]));
      await escogerNivel(tester, nivel);
      comprobarNumero(tester);
      await prepararNivel(tester, nivel);
      await pulsarNivel(tester, find.byKey(const ValueKey('boton_inicio')));
      comprobarNumero(tester);
      final desplazable = find.byType(SingleChildScrollView);
      if (desplazable.evaluate().isNotEmpty) {
        await tester.drag(desplazable, const Offset(0, -24));
        await tester.pumpAndSettle();
        comprobarNumero(tester);
      }
    });
  }
}
