import 'package:brilliant_game/presentation/widgets/fondo_espacial.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:brilliant_game/presentation/widgets/nave_marciano.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/flujo_niveles.dart';

void comprobarNumero(WidgetTester tester) {
  final franja = tester.getRect(
    find.byKey(const ValueKey('numero_fondo_nivel')),
  );
  final nave = tester.getRect(find.byType(NaveMarciano));
  final compacto = tester
      .widget<NumeroFondoNivel>(find.byType(NumeroFondoNivel))
      .compacto;
  final escala = franja.width / (compacto ? 300 : 841);
  final recorte = compacto ? 24.0 : 0.0;
  final numero = Rect.fromLTRB(
    franja.center.dx - 50 * escala,
    franja.top + (44 - recorte) * escala,
    franja.center.dx + 50 * escala,
    franja.top + (112 - recorte) * escala,
  );
  expect(
    numero.top,
    greaterThanOrEqualTo(tester.getRect(find.text('BRILLIANT')).bottom),
  );
  expect(numero.bottom, lessThan(nave.top));
  expect(nave.top - numero.bottom, inInclusiveRange(1.5, 26));
  expect(numero.left, greaterThanOrEqualTo(0));
  expect(numero.right, lessThanOrEqualTo(tester.view.physicalSize.width));
  expect(tester.takeException(), isNull);
}

Future<void> comprobarFija(WidgetTester tester) async {
  expect(find.byType(SingleChildScrollView), findsNothing);
  final tablero = find.byType(TableroView);
  final rect = tester.getRect(tablero);
  final nave = tester.getRect(find.byType(NaveMarciano));
  final pantalla = tester.view.physicalSize;
  expect(rect.top, greaterThanOrEqualTo(32));
  expect(rect.bottom, lessThanOrEqualTo(pantalla.height - 24));
  expect(
    tester.getSize(find.byType(CeldaView).first).shortestSide,
    greaterThanOrEqualTo(32),
  );
  for (final y in [-180.0, 180.0]) {
    await tester.drag(tablero, Offset(0, y));
    await tester.pumpAndSettle();
    expect(tester.getRect(tablero), rect);
    expect(tester.getRect(find.byType(NaveMarciano)), nave);
  }
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
      await comprobarFija(tester);
      await prepararNivel(tester, nivel);
      await pulsarNivel(tester, find.byKey(const ValueKey('boton_inicio')));
      comprobarNumero(tester);
      await comprobarFija(tester);
    });
  }
}
