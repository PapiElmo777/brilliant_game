import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_game/presentation/widgets/avatar_usuario.dart';
import '../support/auth_support.dart';
import '../support/flujo_niveles.dart';

void main() {
  testWidgets(
    'Menú saluda y cambiar avatar actualiza cuenta y acceso al menú',
    (tester) async {
      pantallaNivel(tester);
      final repository = FakeAuthRepository(name: 'Pepe');
      await iniciarApp(tester, repository: repository);
      expect(find.text('Bienvenido Pepe'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('account_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('seleccionar_avatar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('avatar_tablero_03')));
      await tester.pumpAndSettle();
      expect(repository.avatarId, 'tablero_03');
      expect(
        tester
            .widget<AvatarUsuario>(find.byKey(const ValueKey('avatar_cuenta')))
            .avatarId,
        'tablero_03',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<AvatarUsuario>(find.byType(AvatarUsuario)).avatarId,
        'tablero_03',
      );
    },
  );
  testWidgets('Cancelar avatar conserva el icono general', (tester) async {
    pantallaNivel(tester);
    final repository = FakeAuthRepository();
    await iniciarApp(tester, repository: repository);
    await tester.tap(find.byKey(const ValueKey('account_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('seleccionar_avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.avatarId, isNull);
  });
}
