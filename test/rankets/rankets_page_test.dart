import 'dart:async';
import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/app/tema_brilliant.dart';
import 'package:brilliant_game/auth/auth_cubit.dart';
import 'package:brilliant_game/auth/auth_repository.dart';
import 'package:brilliant_game/presentation/pages/rankets_page.dart';
import 'package:brilliant_game/rankets/rankets_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/auth_support.dart';

Map<String, dynamic> player(String id, {int wins = 2, int position = 1}) => {
  'userId': id,
  'username': id == 'uuid-de-prueba' ? 'Ana' : 'Jugador $id',
  'avatarId': null,
  'wins': wins,
  'position': position,
  'winsByLevel': {
    'tablero_01': wins,
    'tablero_02': 0,
    'tablero_03': 0,
    'tablero_04': 0,
  },
};
RanketsPageData data({int offset = 0, int total = 26, bool own = true}) =>
    RanketsPageData.fromJson({
      'entries': [player(offset == 0 ? 'best' : 'last', position: offset + 1)],
      'total': total,
      'offset': offset,
      'me': own ? player('uuid-de-prueba', wins: 0, position: 26) : null,
    });

class FakeRankets implements RanketsRepository {
  AuthFailure? failure;
  final offsets = <int>[];
  Completer<RanketsPageData>? pending;
  RanketsPageData? value;
  @override
  Future<RanketsPageData> list(String token, {int offset = 0}) async {
    offsets.add(offset);
    if (failure != null) throw failure!;
    return pending == null ? value ?? data(offset: offset) : pending!.future;
  }

  @override
  void close() {}
}

Future<AuthCubit> open(
  WidgetTester tester,
  FakeRankets repo, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthCubit(FakeAuthRepository());
  await auth.authenticate('Ana', 'a!2', register: false);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => auth,
      child: MaterialApp(
        theme: TemaBrilliant.oscuro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RanketsPage(repository: repo),
      ),
    ),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
  });
  await tester.pump();
  await tester.pump();
  return auth;
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets(
      'Ranking, own position and level details fit $size with large text',
      (tester) async {
        await open(tester, FakeRankets(), size: size, scale: 2);
        await tester.pumpAndSettle();
        expect(find.text('#26 · Ana (Tú)'), findsOneWidget);
        expect(find.text('Nivel 4: 0'), findsWidgets);
        expect(find.text('0 victorias'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Pagination and refresh query the server again', (tester) async {
    final repo = FakeRankets();
    await open(tester, repo);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(repo.offsets, [0, 25]);
    await tester.tap(find.byTooltip('Actualizar ranking'));
    await tester.pumpAndSettle();
    expect(repo.offsets, [0, 25, 0]);
  });
  testWidgets(
    'Empty ranking explains participation without inventing a position',
    (tester) async {
      final repo = FakeRankets()
        ..value = RanketsPageData.fromJson({
          'entries': [],
          'me': null,
          'total': 0,
          'offset': 0,
        });
      await open(tester, repo);
      await tester.pumpAndSettle();
      expect(
        find.text('Todavía no hay jugadores en el ranking.'),
        findsOneWidget,
      );
      expect(find.text('Tu posición'), findsNothing);
    },
  );
  testWidgets('Loading, retry and invalid session are handled', (tester) async {
    final repo = FakeRankets()..pending = Completer<RanketsPageData>();
    final auth = await open(tester, repo);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.pending!.completeError(const AuthFailure('NETWORK_ERROR'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    repo.pending = null;
    repo.failure = const AuthFailure('SESSION_INVALID', status: 401);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(auth.state.session, isNull);
  });
  testWidgets('Main menu button opens Rankets', (tester) async {
    await tester.pumpWidget(
      BrilliantGameApp(
        authRepository: FakeAuthRepository(),
        ranketsRepository: FakeRankets(),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('auth_username')), 'Ana');
    await tester.enterText(find.byKey(const ValueKey('auth_password')), 'a!2');
    await tester.ensureVisible(find.byKey(const ValueKey('auth_submit')));
    await tester.tap(find.byKey(const ValueKey('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rankets_menu')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rankets_boton_menu')));
    await tester.pumpAndSettle();
    expect(find.byType(RanketsPage), findsOneWidget);
    expect(find.text('Los mejores jugadores'), findsOneWidget);
  });
}
