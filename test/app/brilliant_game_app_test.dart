import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La aplicación abre el menú base sin errores', (tester) async {
    await tester.pumpWidget(const BrilliantGameApp());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Brilliant'), findsOneWidget);
    expect(find.text('Que la Fuerza guíe tus números.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final context = tester.element(
      find.byKey(const ValueKey('nueva_partida_menu')),
    );
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(ModalRoute.of(context)?.settings.name, '/');
  });
}
