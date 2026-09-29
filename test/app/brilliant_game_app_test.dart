import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La aplicación abre el menú base sin errores', (tester) async {
    await tester.pumpWidget(const BrilliantGameApp());
    await tester.pumpAndSettle();

    expect(find.text('BRILLIANT'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final context = tester.element(find.text('BRILLIANT'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(ModalRoute.of(context)?.settings.name, '/');
  });
}
