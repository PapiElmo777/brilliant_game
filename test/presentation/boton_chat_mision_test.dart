import 'package:brilliant_game/multiplayer/rooms_cubit.dart';
import 'package:brilliant_game/multiplayer/rooms_repository.dart';
import 'package:brilliant_game/presentation/widgets/boton_chat_mision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';

void main() {
  testWidgets(
    'Solo un mensaje nuevo ajeno vibra; no historial, sistema ni propios',
    (tester) async {
      final feedback = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          feedback.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final messages = <RoomMessage>[];
      final lobby = LobbySnapshot.fromJson(lobbyJson());
      RoomMessage message(int n, String kind, String author) =>
          RoomMessage.fromJson({
            'id': '$n',
            'sequence': n,
            'kind': kind,
            'text': 'Hola',
            'authorMemberId': author,
            'authorName': author,
            'serverTime': '2026-11-11T00:00:00Z',
          });
      Future<void> scene() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BotonChatMision(
              state: RoomsState(lobby: lobby, messages: List.of(messages)),
              ownId: 'propio',
              onPressed: () {},
            ),
          ),
        ),
      );
      await scene();
      messages.add(message(1, 'SYSTEM', 'sistema'));
      await scene();
      messages.add(message(2, 'PLAYER', 'propio'));
      await scene();
      expect(
        feedback.where((c) => c.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
      messages.add(message(3, 'PLAYER', 'otro'));
      await scene();
      await tester.pump(const Duration(milliseconds: 70));
      expect(
        feedback.where((c) => c.method == 'HapticFeedback.vibrate').length,
        1,
      );
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      await scene();
      messages.insert(0, message(0, 'PLAYER', 'otro'));
      await scene();
      expect(
        feedback.where((c) => c.method == 'HapticFeedback.vibrate').length,
        1,
      );
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
