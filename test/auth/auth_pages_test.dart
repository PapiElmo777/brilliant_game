import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/presentation/pages/menu_inicial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openDelete(WidgetTester tester) async {
  await tap(tester, 'account_menu');
  await tap(tester, 'delete_account');
}

void main() {
  testWidgets('Cerrar sesión limpia rutas y permite volver a entrar', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await iniciarApp(tester, repository: repository);
    await tap(tester, 'account_menu');
    await tap(tester, 'logout_account');
    expect(find.text('Sesión cerrada.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MenuInicialPage), findsNothing);
    expect(repository.logouts, 1);
    expect(repository.deletes, 0);
    await tester.enterText(find.byKey(const ValueKey('auth_username')), 'Ana');
    await tester.enterText(find.byKey(const ValueKey('auth_password')), 'a!2');
    await tap(tester, 'auth_submit');
    expect(find.byType(MenuInicialPage), findsOneWidget);
  });

  for (final local in [false, true]) {
    testWidgets(
      'Logout con red caída permite ${local ? 'salida local' : 'reintentar'}',
      (tester) async {
        final repository = FakeAuthRepository();
        await iniciarApp(tester, repository: repository);
        await tap(tester, 'account_menu');
        repository.failure = const AuthFailure('NETWORK_ERROR');
        await tap(tester, 'logout_account');
        expect(find.byKey(const ValueKey('logout_error')), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsNothing);
        if (local) {
          await tap(tester, 'logout_local');
          expect(
            find.textContaining('No se pudo confirmar el cierre'),
            findsOneWidget,
          );
          expect(repository.logouts, 1);
        } else {
          repository.failure = null;
          await tap(tester, 'logout_account');
          expect(find.text('Sesión cerrada.'), findsOneWidget);
          expect(repository.logouts, 2);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(find.byType(MenuInicialPage), findsNothing);
      },
    );
  }

  testWidgets(
    'Registro por formulario abre el menú; proceso nuevo exige login',
    (tester) async {
      final repository = FakeAuthRepository();
      await tester.pumpWidget(BrilliantGameApp(authRepository: repository));
      await tap(tester, 'auth_switch');
      expect(find.text('Crear cuenta'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('auth_username')),
        'Ana',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password')),
        'a!2',
      );
      await tap(tester, 'auth_submit');
      expect(find.byType(MenuInicialPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(BrilliantGameApp(authRepository: repository));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('NUEVA PARTIDA'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final password in ['a!', 'abc', 'a 2', 'áéí']) {
    testWidgets(
      'Registro rechaza contraseña sin longitud o símbolo: $password',
      (tester) async {
        await tester.pumpWidget(
          BrilliantGameApp(authRepository: FakeAuthRepository()),
        );
        await tap(tester, 'auth_switch');
        await tester.enterText(
          find.byKey(const ValueKey('auth_username')),
          'Ana',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password')),
          password,
        );
        await tap(tester, 'auth_submit');
        expect(find.byType(MenuInicialPage), findsNothing);
        expect(
          find.text(
            password == 'a!'
                ? 'Usa entre 3 y 128 caracteres.'
                : 'Incluye al menos un carácter especial, como !, @ o #.',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Cancelar no borra; contraseña errónea conserva; 204 limpia todas las rutas',
    (tester) async {
      final repository = FakeAuthRepository();
      await iniciarApp(tester, repository: repository);
      await openDelete(tester);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('delete_submit')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.deletes, 0);
      await tap(tester, 'delete_account');
      repository.failure = const AuthFailure(
        'CURRENT_PASSWORD_INVALID',
        status: 403,
      );
      await tester.enterText(
        find.byKey(const ValueKey('delete_password')),
        'contraseña incorrecta',
      );
      await tap(tester, 'delete_confirmation');
      await tap(tester, 'delete_submit');
      expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
      expect(repository.deletes, 1);
      expect(find.byKey(const ValueKey('delete_password')), findsOneWidget);
      repository.failure = null;
      await tester.enterText(
        find.byKey(const ValueKey('delete_password')),
        'contraseña correcta',
      );
      await tap(tester, 'delete_submit');
      expect(repository.deletes, 2);
      expect(find.text('Cuenta eliminada.'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuInicialPage), findsNothing);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    },
  );

  testWidgets('Resultado incierto conserva la cuenta y no anuncia éxito', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await iniciarApp(tester, repository: repository);
    await openDelete(tester);
    repository.failure = const AuthFailure('NETWORK_ERROR');
    await tester.enterText(
      find.byKey(const ValueKey('delete_password')),
      'contraseña de prueba',
    );
    await tap(tester, 'delete_confirmation');
    await tap(tester, 'delete_submit');
    expect(
      find.textContaining('No se pudo confirmar el borrado'),
      findsOneWidget,
    );
    expect(find.text('Cuenta eliminada.'), findsNothing);
    expect(repository.deletes, 1);
  });

  testWidgets('Caducidad desmonta selector y menú, atrás no los recupera', (
    tester,
  ) async {
    await iniciarApp(tester);
    final auth = tester.element(find.byType(MenuInicialPage)).read<AuthCubit>();
    await tap(tester, 'nueva_partida_menu');
    auth.invalidate();
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ELIGE TU NIVEL'), findsNothing);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets(
      'Formularios accesibles con teclado y texto ampliado en $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 180);
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repository = FakeAuthRepository();
        await iniciarApp(tester, repository: repository);
        await openDelete(tester);
        await tester.enterText(
          find.byKey(const ValueKey('delete_password')),
          'contraseña de prueba',
        );
        await tap(tester, 'delete_confirmation');
        await tap(tester, 'delete_submit');
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
