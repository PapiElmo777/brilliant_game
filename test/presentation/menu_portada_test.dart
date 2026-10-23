import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/presentation/pages/seleccion_nivel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/flujo_niveles.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(393, 873),
    const Size(430, 932),
    const Size(844, 390),
  ]) {
    testWidgets('Portada fija y nueva partida accesible en $size', (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: 1.5);
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      await tester.pumpWidget(const BrilliantGameApp());
      await precargarRecursos(tester);
      final boton = find.byKey(const ValueKey('nueva_partida_menu'));
      final rect = tester.getRect(boton);
      expect(rect.top, greaterThanOrEqualTo(32));
      expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(find.byType(Scrollable), findsNothing);
      final logo = find.byKey(const ValueKey('logo_menu'));
      expect(
        tester.widget<Image>(logo).image,
        const AssetImage('assets/images/branding/LogoMenu.png'),
      );
      expect(tester.getRect(logo).bottom, lessThanOrEqualTo(rect.top));
      expect(
        tester.getRect(find.text('Que la Fuerza guíe tus números.')).top,
        greaterThan(rect.bottom),
      );
      final fondo = find.byKey(const ValueKey('fondo_menu'));
      expect(
        tester.widget<Image>(fondo).image,
        const AssetImage('assets/images/backgrounds/PantallaMenu1.png'),
      );
      await tester.drag(fondo, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(tester.getRect(boton), rect);
      expect(tester.takeException(), isNull);
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(find.byType(SeleccionNivelPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
