import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/presentation/pages/multijugador_page.dart';
import 'package:brilliant_game/presentation/widgets/chat_sala.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

Map<String, dynamic> chatLobby() => {
  ...lobbyJson(sequence: 3, levelId: 'tablero_03', guestReady: true),
  'messages': [
    {
      'id': 'sistema',
      'sequence': 1,
      'kind': 'SYSTEM',
      'text': 'Comienza la misión.',
      'authorMemberId': null,
      'authorName': null,
      'serverTime': '2026-11-06T00:00:00Z',
    },
    {
      'id': 'saludo',
      'sequence': 3,
      'kind': 'PLAYER',
      'text': 'Hola, escuadrón',
      'authorMemberId': 'otro',
      'authorName': 'Beto',
      'serverTime': '2026-11-06T00:00:01Z',
    },
  ],
};

void main() {
  testWidgets(
    'Chat muestra sistema y jugador, envía texto plano y confirma el borrador',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()..snapshot = chatLobby();
      await openRooms(tester, repo);
      await tester.tap(find.byKey(const ValueKey('abrir_chat')));
      await tester.pumpAndSettle();
      expect(find.text('Comienza la misión.'), findsOneWidget);
      expect(find.text('Beto'), findsOneWidget);
      final field = find.byKey(const ValueKey('texto_chat'));
      await tester.enterText(field, '<b>Hola</b>');
      await tester.tap(find.byKey(const ValueKey('enviar_chat')));
      await tester.pumpAndSettle();
      expect(find.text('<b>Hola</b>'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      await tester.tap(find.byKey(const ValueKey('cerrar_chat')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatSala), findsNothing);
    },
  );
  testWidgets('Un envío incierto conserva borrador y reintenta sin duplicar', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = chatLobby();
    await openRooms(tester, repo);
    await tester.tap(find.byKey(const ValueKey('abrir_chat')));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('texto_chat'));
    await tester.enterText(field, 'Hola con respuesta perdida');
    repo.loseNextResponse = true;
    await tester.tap(find.byKey(const ValueKey('enviar_chat')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Hola con respuesta perdida',
    );
    final retry = find.descendant(
      of: find.byType(ChatSala),
      matching: find.text('Reintentar operación'),
    );
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(repo.commands.first, repo.commands.last);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.text('Hola con respuesta perdida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Invalidar la sesión desmonta también el chat', (tester) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = chatLobby();
    await openRooms(tester, repo);
    await tester.tap(find.byKey(const ValueKey('abrir_chat')));
    await tester.pumpAndSettle();
    tester
        .element(find.byType(MultijugadorPage))
        .read<AuthCubit>()
        .invalidate();
    await tester.pumpAndSettle();
    expect(find.byType(ChatSala), findsNothing);
    expect(find.byKey(const ValueKey('auth_username')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Chat con teclado y texto 2× en $size', (tester) async {
      pantallaNivel(tester, size: size, escala: 2);
      final repo = FakeRoomsRepository()..snapshot = chatLobby();
      await openRooms(tester, repo);
      await tester.tap(find.byKey(const ValueKey('abrir_chat')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(
        bottom: size.height < 500 ? 180 : 250,
      );
      await tester.pumpAndSettle();
      final close = find.byKey(const ValueKey('cerrar_chat'));
      expect(
        tester.getCenter(close).dy,
        lessThan(size.height - (size.height < 500 ? 180 : 250)),
      );
      await tester.enterText(
        find.byKey(const ValueKey('texto_chat')),
        'Mensaje sin enviar',
      );
      expect(tester.takeException(), isNull);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(ChatSala), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
