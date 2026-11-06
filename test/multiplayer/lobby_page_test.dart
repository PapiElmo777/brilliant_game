import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/presentation/pages/multijugador_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';

Future<void> openRooms(WidgetTester tester, FakeRoomsRepository rooms) async {
  await tester.pumpWidget(
    BrilliantGameApp(
      authRepository: FakeAuthRepository(),
      roomsRepository: rooms,
    ),
  );
  addTearDown(() async => tester.pumpWidget(const SizedBox()));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('auth_username')), 'Ana');
  await tester.enterText(find.byKey(const ValueKey('auth_password')), 'a!2');
  await tester.ensureVisible(find.byKey(const ValueKey('auth_submit')));
  await tester.tap(find.byKey(const ValueKey('auth_submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('multijugador_menu')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Del menú a crear, elegir mapa, iniciar preparación y salir con confirmación',
    (tester) async {
      pantallaNivel(tester);
      final rooms = FakeRoomsRepository();
      await openRooms(tester, rooms);
      expect(find.byType(MultijugadorPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('alojar_partida')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('nombre_sala')),
        'Escuadrón',
      );
      await tester.tap(find.byKey(const ValueKey('crear_sala')));
      await tester.pumpAndSettle();
      final map = find.byKey(const ValueKey('sala_tablero_02'));
      await tester.ensureVisible(map);
      await tester.tap(map);
      await tester.pumpAndSettle();
      expect((rooms.snapshot!['room'] as Map)['levelId'], 'tablero_02');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('iniciar_sala')))
            .onPressed,
        isNull,
      );
      rooms.snapshot = lobbyJson(
        levelId: 'tablero_02',
        revision: 1,
        guestReady: true,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('iniciar_sala')));
      await tester.pumpAndSettle();
      expect(find.text('Preparando la misión'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Preparando la misión'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar_salida_sala')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('alojar_partida')), findsOneWidget);
      expect(rooms.snapshot, isNull);
      expect(rooms.paths.last, 'POST rooms/sala-1/leave');
    },
  );
  testWidgets(
    'Invitado solo cambia su Listo, conserva selección y no modifica mapas',
    (tester) async {
      pantallaNivel(tester);
      final rooms = FakeRoomsRepository(guest: true)
        ..snapshot = lobbyJson(
          guest: true,
          levelId: 'tablero_04',
          guestReady: true,
        );
      await openRooms(tester, rooms);
      final map = find.byKey(const ValueKey('sala_tablero_01'));
      expect(tester.widget<InkWell>(map).onTap, isNull);
      expect(find.text('Quitar Listo'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('listo_sala')));
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsOneWidget);
      expect(rooms.commands.single['ready'], false);
      expect(rooms.paths.single, 'PUT rooms/sala-1/ready');
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Lobby con texto grande y teclado en $size', (tester) async {
      pantallaNivel(tester, size: size, escala: 2);
      final rooms = FakeRoomsRepository()
        ..snapshot = lobbyJson(levelId: 'tablero_03');
      await openRooms(tester, rooms);
      expect(tester.takeException(), isNull);
      final random = find.byKey(const ValueKey('nivel_aleatorio_sala'));
      await tester.scrollUntilVisible(
        random,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(random);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar_salida_sala')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('alojar_partida')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('nombre_sala')),
        'Otra sala',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
