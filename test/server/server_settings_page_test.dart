import 'dart:async';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/presentation/pages/menu_inicial_page.dart';
import 'package:brilliant_game/server/server_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/server_support.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class PendingProbe implements ServerProbe {
  final pending = Completer<void>();
  int calls = 0;
  @override
  Future<void> check(Uri address) {
    calls++;
    return pending.future;
  }
}

void main() {
  testWidgets('Configura una vez, persiste dirección y no restaura la sesión', (
    tester,
  ) async {
    final store = MemoryServerSettingsStore();
    final probe = FakeServerProbe();
    final created = <Uri>[];
    AuthRepository factory(Uri address) {
      created.add(address);
      return FakeAuthRepository();
    }

    Future<void> open() async {
      await tester.pumpWidget(
        BrilliantGameApp(
          serverStore: store,
          serverProbe: probe,
          authRepositoryFactory: factory,
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('auth_submit')))
          .onPressed,
      isNull,
    );
    await tap(tester, 'server_settings');
    await tester.enterText(
      find.byKey(const ValueKey('server_address')),
      '192.168.0.31:8080',
    );
    await tap(tester, 'server_save');
    expect(store.value, 'http://192.168.0.31:8080/api/v1');
    expect(probe.calls.single, Uri.parse(store.value!));
    expect(find.text('192.168.0.31:8080'), findsOneWidget);
    expect(find.byKey(const ValueKey('server_save')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('auth_username')), 'Ana');
    await tester.enterText(find.byKey(const ValueKey('auth_password')), 'a!2');
    await tap(tester, 'auth_submit');
    expect(find.byType(MenuInicialPage), findsOneWidget);
    expect(find.byKey(const ValueKey('server_settings')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await open();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(created.last.toString(), store.value);
    expect(store.writes, ['http://192.168.0.31:8080/api/v1']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Cambiar servidor requiere salir y descarta la identidad anterior',
    (tester) async {
      final store = MemoryServerSettingsStore(
        'http://192.168.0.31:8080/api/v1',
      );
      final repositories = <Uri>[];
      await tester.pumpWidget(
        BrilliantGameApp(
          serverStore: store,
          serverProbe: FakeServerProbe(),
          authRepositoryFactory: (address) {
            repositories.add(address);
            return FakeAuthRepository(
              name: address.host.endsWith('32') ? 'PilotoB' : 'PilotoA',
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth_username')),
        'Ana',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password')),
        'a!2',
      );
      await tap(tester, 'auth_submit');
      await tap(tester, 'account_menu');
      await tap(tester, 'logout_account');
      await tap(tester, 'server_settings');
      await tester.enterText(
        find.byKey(const ValueKey('server_address')),
        '192.168.0.32:8080',
      );
      await tap(tester, 'server_save');
      expect(repositories.last.host, '192.168.0.32');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('auth_username')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_username')),
        'Ana',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth_password')),
        'a!2',
      );
      await tap(tester, 'auth_submit');
      expect(find.text('PilotoB'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final storageFailure in [false, true]) {
    testWidgets(
      'Fallo de ${storageFailure ? 'guardado' : 'red'} conserva la dirección anterior',
      (tester) async {
        final store = MemoryServerSettingsStore(
          'http://192.168.0.31:8080/api/v1',
        )..failWrite = storageFailure;
        final probe = FakeServerProbe();
        if (!storageFailure) {
          probe.failure = const ServerConfigurationException(
            'Sin conexión con el servidor.',
          );
        }
        await tester.pumpWidget(
          BrilliantGameApp(
            serverStore: store,
            serverProbe: probe,
            authRepositoryFactory: (_) => FakeAuthRepository(),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, 'server_settings');
        await tester.enterText(
          find.byKey(const ValueKey('server_address')),
          '192.168.0.32',
        );
        await tap(tester, 'server_save');
        expect(find.byKey(const ValueKey('server_error')), findsOneWidget);
        expect(store.value, 'http://192.168.0.31:8080/api/v1');
        expect(store.writes, isEmpty);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('Cancelar o dirección inválida no guardan ni prueban conexión', (
    tester,
  ) async {
    final store = MemoryServerSettingsStore();
    final probe = FakeServerProbe();
    await tester.pumpWidget(
      BrilliantGameApp(
        serverStore: store,
        serverProbe: probe,
        authRepositoryFactory: (_) => FakeAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'server_settings');
    await tester.enterText(
      find.byKey(const ValueKey('server_address')),
      'http://192.168.0.31:8080/api/v1+',
    );
    await tap(tester, 'server_save');
    expect(probe.calls, isEmpty);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(store.writes, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Configurar servidor con texto ampliado y teclado en $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        BrilliantGameApp(
          serverStore: MemoryServerSettingsStore(),
          serverProbe: FakeServerProbe(),
          authRepositoryFactory: (_) => FakeAuthRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'server_settings');
      await tester.enterText(
        find.byKey(const ValueKey('server_address')),
        '192.168.0.31:8080',
      );
      await tap(tester, 'server_save');
      expect(find.text('192.168.0.31:8080'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Una comprobación tardía no guarda tras desmontar la pantalla', (
    tester,
  ) async {
    final store = MemoryServerSettingsStore();
    final probe = PendingProbe();
    await tester.pumpWidget(
      BrilliantGameApp(
        serverStore: store,
        serverProbe: probe,
        authRepositoryFactory: (_) => FakeAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'server_settings');
    await tester.enterText(
      find.byKey(const ValueKey('server_address')),
      '192.168.0.31',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('server_save')));
    await tester.tap(find.byKey(const ValueKey('server_save')));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Comprobando conexión…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    probe.pending.complete();
    await tester.pump();
    expect(store.writes, isEmpty);
  });
}
