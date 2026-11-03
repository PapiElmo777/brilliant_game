import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La aplicación exige iniciar sesión al arrancar', (tester) async {
    await tester.pumpWidget(const BrilliantGameApp());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('NUEVA PARTIDA'), findsNothing);
    expect(tester.takeException(), isNull);
    final context = tester.element(find.byKey(const ValueKey('auth_submit')));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
