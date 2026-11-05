import 'dart:convert';
import 'dart:io';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/server/server_configuration.dart';
import '../support/server_support.dart';
import 'package:brilliant_game/presentation/pages/menu_inicial_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brilliant_game/presentation/pages/partida_page.dart';
import 'package:brilliant_game/presentation/pages/preparacion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealHttpOverrides extends HttpOverrides {}

// Opt-in: usa exclusivamente una carpeta temporal y un puerto libre. Nunca
// conecta con la base de desarrollo ni modifica cuentas existentes.
void main() {
  testWidgets(
    'Flutter → JAR: registro, reinicios, partida y borrado real',
    (tester) async {
      final jar = File(
        const String.fromEnvironment(
          'AUTH_SERVER_JAR',
          defaultValue: '../brilliant_server/target/brilliant-server.jar',
        ),
      ).absolute.path;
      final setup = await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'brilliant-auth-e2e-',
        );
        final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = socket.port;
        await socket.close();
        return (directory, port);
      });
      final (directory, port) = setup!;
      Process? process;
      final url = Uri.parse('http://127.0.0.1:$port/api/v1');
      HttpClient realClient() => HttpOverrides.runWithHttpOverrides(
        () => HttpClient(),
        _RealHttpOverrides(),
      );
      final repository = HttpAuthRepository(baseUrl: url, client: realClient());
      final serverStore = MemoryServerSettingsStore();
      final serverProbe = HttpServerProbe(clientFactory: realClient);
      Widget app() => BrilliantGameApp(
        authRepository: repository,
        serverStore: serverStore,
        serverProbe: serverProbe,
      );
      Future<void> start() async {
        process = await Process.start(
          const String.fromEnvironment(
            'AUTH_SERVER_JAVA',
            defaultValue: '/usr/bin/java',
          ),
          [
            '-jar',
            jar,
            '--server.port=$port',
            '--server.address=127.0.0.1',
            '--logging.level.org.springframework.boot.web.embedded.tomcat=INFO',
          ],
          workingDirectory: directory.path,
          environment: {
            'PORT': '$port',
            'BIND_ADDRESS': '127.0.0.1',
            'DATA_DIR': '${directory.path}/data',
          },
        );
        final startup = StringBuffer();
        process!.stdout.transform(utf8.decoder).listen(startup.write);
        process!.stderr.transform(utf8.decoder).listen(startup.write);
        int? exitCode;
        process!.exitCode.then((value) => exitCode = value);
        final health = realClient()
          ..connectionTimeout = const Duration(seconds: 1);
        var lastHealth = 'sin petición';
        try {
          for (var i = 0; i < 200; i++) {
            if (exitCode != null) {
              throw StateError('JAR terminó: $exitCode: $startup');
            }
            try {
              final req = await health.getUrl(
                url.resolve('/api/v1/health/ready'),
              );
              final res = await req.close();
              await res.drain<void>();
              lastHealth = 'HTTP ${res.statusCode}';
              if (res.statusCode == 200) return;
            } on IOException catch (error) {
              lastHealth = error.toString();
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          throw StateError(
            'El JAR no quedó disponible en $url ($lastHealth): $startup',
          );
        } finally {
          health.close(force: true);
        }
      }

      Future<void> stop() async {
        process?.kill();
        await process?.exitCode;
        process = null;
      }

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        repository.close();
        await tester.runAsync(() async {
          await stop();
          await directory.delete(recursive: true);
        });
      });
      await tester.runAsync(start);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      Future<void> settleNetwork() async {
        for (var i = 0; i < 100; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pump();
          if (find.text('Conectando…').evaluate().isEmpty &&
              find.text('Eliminando…').evaluate().isEmpty &&
              find.text('Cerrando sesión…').evaluate().isEmpty &&
              find.text('Comprobando conexión…').evaluate().isEmpty) {
            break;
          }
        }
        await tester.pumpAndSettle();
      }

      Future<void> tap(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await settleNetwork();
      }

      const password = 'a!2';
      const username = 'PilotoE2E';
      Future<void> credentials(String name) async {
        await tester.enterText(
          find.byKey(const ValueKey('auth_username')),
          name,
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password')),
          password,
        );
        await tap('auth_submit');
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap('server_settings');
      await tester.enterText(
        find.byKey(const ValueKey('server_address')),
        url.toString(),
      );
      await tap('server_save');
      expect(serverStore.value, url.toString());
      await tap('auth_switch');
      await credentials(username);
      expect(find.text('NUEVA PARTIDA'), findsOneWidget);
      // La misma cuenta sobrevive a reiniciar JAR y cliente. El cliente no
      // conserva tokens ni pide nuevamente registro después del reinicio.
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await stop();
        await start();
      });
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      await credentials(username.toLowerCase());
      expect(find.text('NUEVA PARTIDA'), findsOneWidget);
      final account = await tester.runAsync(
        () => repository.login(username, password),
      );
      expect(account, isNotNull);
      await tester.runAsync(() async {
        await expectLater(
          repository.register(username.toLowerCase(), password),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.code,
              'code',
              'USERNAME_UNAVAILABLE',
            ),
          ),
        );
      });
      final previousSession = tester
          .element(find.byType(MenuInicialPage))
          .read<AuthCubit>()
          .state
          .session!;
      await tap('account_menu');
      await tap('logout_account');
      expect(find.text('Sesión cerrada.'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MenuInicialPage), findsNothing);
      await tester.runAsync(() async {
        final client = realClient();
        try {
          for (final (token, expected) in [
            (previousSession.accessToken, 401),
            (account!.accessToken, 200),
          ]) {
            final request = await client.getUrl(
              url.resolve('/api/v1/users/me'),
            );
            request.headers.set('authorization', 'Bearer $token');
            final response = await request.close();
            await response.drain<void>();
            expect(response.statusCode, expected);
          }
        } finally {
          client.close(force: true);
        }
      });
      await credentials(username);
      expect(find.byType(MenuInicialPage), findsOneWidget);
      expect(
        tester
            .element(find.byType(MenuInicialPage))
            .read<AuthCubit>()
            .state
            .session!
            .user
            .id,
        account!.user.id,
      );
      await tap('nueva_partida_menu');
      await tap('elegir_tablero_01');
      expect(find.byType(PreparacionPage), findsOneWidget);
      expect(find.byKey(const ValueKey('campo_nombre')), findsNothing);
      const initial = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];
      for (var i = 0; i < initial.length; i++) {
        await tap('numero_${i + 1}');
        await tap('celda_${initial[i]}');
      }
      await tap('boton_inicio');
      expect(
        tester.widget<PreparacionPage>(find.byType(PreparacionPage)).jugadorId,
        account.user.id,
      );
      expect(
        tester.widget<PartidaPage>(find.byType(PartidaPage)).jugador,
        username,
      );
      await tester.tap(find.byTooltip('Volver al menú'));
      await tester.pumpAndSettle();
      await tap('confirmar_salida');
      await tap('account_menu');
      await tap('delete_account');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tap('delete_account');
      await tester.enterText(
        find.byKey(const ValueKey('delete_password')),
        'una contraseña equivocada',
      );
      await tap('delete_confirmation');
      await tap('delete_submit');
      expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('delete_password')),
        password,
      );
      await tap('delete_submit');
      expect(find.text('Cuenta eliminada.'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('NUEVA PARTIDA'), findsNothing);
      await credentials(username);
      expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
      await tester.runAsync(() async {
        final client = realClient();
        try {
          final req = await client.getUrl(url.resolve('/api/v1/users/me'));
          req.headers.set('authorization', 'Bearer ${account.accessToken}');
          final res = await req.close();
          await utf8.decoder.bind(res).join();
          expect(res.statusCode, 401);
        } finally {
          client.close(force: true);
        }
      });
      await tester.pumpWidget(const SizedBox());
      repository.close();
      await tester.pump();
    },
    skip: !const bool.fromEnvironment('RUN_AUTH_API_E2E'),
  );
}
