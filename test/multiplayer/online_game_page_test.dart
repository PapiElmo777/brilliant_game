import 'package:brilliant_game/presentation/widgets/dados_partida.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/rooms_support.dart';
import '../support/flujo_niveles.dart';
import 'lobby_page_test.dart' show openRooms;

Future<void> revealOnline(
  WidgetTester tester,
  Finder target, {
  double step = 250,
}) async {
  await tester.scrollUntilVisible(
    target,
    step,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Preparación manual de 1 a 6 solo se publica al confirmar', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()..snapshot = onlineSnapshot();
    await openRooms(tester, repo);
    final placements = onlinePreparation();
    for (final entry in placements.entries) {
      final number = find.byKey(ValueKey('numero_online_${entry.value}'));
      await revealOnline(tester, number, step: -250);
      await tester.tap(number);
      await tester.pumpAndSettle();
      final cell = find.byKey(ValueKey('celda_${entry.key}'));
      await revealOnline(tester, cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
    }
    expect(repo.commands, isEmpty);
    final confirm = find.byKey(const ValueKey('confirmar_preparacion_online'));
    await revealOnline(tester, confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repo.paths.single, 'PUT matches/partida-1/preparation');
    expect(repo.commands.single['placements'], placements);
    await tester.drag(
      find.byKey(const ValueKey('contenido_partida_online')),
      const Offset(0, 1000),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Preparación confirmada. Falta 1 participante.'),
      findsOneWidget,
    );
  });
  testWidgets('Permite alternar ambos dados antes de confirmar', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = onlineSnapshot(prepared: true, playing: true);
    await openRooms(tester, repo);
    for (final id in [0, 1, 0, 1]) {
      await tester.tap(find.byKey(ValueKey('dado_online_$id')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FichaDado>(find.byKey(ValueKey('dado_online_$id')))
            .seleccionado,
        isTrue,
      );
      expect(
        tester
            .widget<FichaDado>(find.byKey(ValueKey('dado_online_${1 - id}')))
            .onTap,
        isNotNull,
      );
    }
    expect(repo.commands, isEmpty);
  });
  testWidgets('El reloj avanza sin reconstruir el tablero cada segundo', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = onlineSnapshot(prepared: true, playing: true);
    await openRooms(tester, repo);
    final before = tester.widget<TableroView>(find.byType(TableroView));
    final clockBefore = tester
        .widget<Text>(find.byKey(const ValueKey('reloj_online')))
        .data;
    // El reloj del servidor usa Stopwatch para resistir cambios de hora.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('reloj_online'))).data,
      isNot(clockBefore),
    );
    expect(
      identical(before, tester.widget<TableroView>(find.byType(TableroView))),
      isTrue,
    );
  });
  testWidgets(
    'Elegir dado y celda mantiene una propuesta local hasta confirmar',
    (tester) async {
      pantallaNivel(tester);
      final repo = FakeRoomsRepository()
        ..snapshot = onlineSnapshot(prepared: true, playing: true);
      await openRooms(tester, repo);
      await tester.tap(find.byKey(const ValueKey('dado_online_0')));
      await tester.pumpAndSettle();
      final cell = find.byKey(const ValueKey('celda_f1_c6'));
      await revealOnline(tester, cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(repo.commands, isEmpty);
      final preview = tester.widget<CeldaView>(cell);
      expect(preview.numeroPropuesto, 1);
      expect(preview.seleccionada, isTrue);
      expect(
        find.descendant(of: cell, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TableroView>(find.byType(TableroView))
            .celdasPartida!['f1_c6']!
            .valor,
        isNull,
      );
      final confirm = find.byKey(const ValueKey('confirmar_jugada_online'));
      await revealOnline(tester, confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(repo.commands.single['kind'], 'PLACE');
      expect(repo.commands.single['dieIndex'], 0);
      expect(repo.commands.single['cellId'], 'f1_c6');
      expect((repo.snapshot!['match'] as Map)['ownBoard']['f1_c6'], 1);
      await tester.drag(
        find.byKey(const ValueKey('contenido_partida_online')),
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FichaDado>(find.byKey(const ValueKey('dado_online_0')))
            .onTap,
        isNull,
      );
    },
  );
  testWidgets('Omitir resuelve solo esta ronda y no coloca una propuesta', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = onlineSnapshot(prepared: true, playing: true);
    await openRooms(tester, repo);
    final skip = find.byKey(const ValueKey('omitir_ronda_online'));
    await revealOnline(tester, skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(repo.commands.single['kind'], 'SKIP');
    expect(repo.commands.single.containsKey('cellId'), isFalse);
    expect((repo.snapshot!['match'] as Map)['ownBoard'], onlinePreparation());
    repo.publish(
      onlineSnapshot(
        prepared: true,
        playing: true,
        roundNumber: 2,
        sequence: 7,
      ),
      type: 'ROUND_STARTED',
    );
    await tester.pumpAndSettle();
    expect(repo.commands, hasLength(1));
    expect(find.text('Ronda 2 · 60 s'), findsOneWidget);
  });
  testWidgets('El cambio de ronda descarta la selección sin enviarla', (
    tester,
  ) async {
    pantallaNivel(tester);
    final repo = FakeRoomsRepository()
      ..snapshot = onlineSnapshot(prepared: true, playing: true);
    await openRooms(tester, repo);
    await tester.tap(find.byKey(const ValueKey('dado_online_0')));
    await tester.pumpAndSettle();
    final cell = find.byKey(const ValueKey('celda_f1_c6'));
    await revealOnline(tester, cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    repo.publish(
      onlineSnapshot(
        prepared: true,
        playing: true,
        roundNumber: 2,
        sequence: 6,
      ),
      type: 'ROUND_STARTED',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirmar_jugada_online')), findsNothing);
    expect(repo.commands, isEmpty);
    expect(
      tester
          .widget<TableroView>(find.byType(TableroView))
          .celdasPartida!['f1_c6']!
          .valor,
      isNull,
    );
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Ronda, reloj, controles y chat con texto 2× en $size', (
      tester,
    ) async {
      pantallaNivel(tester, size: size, escala: 2);
      final repo = FakeRoomsRepository()
        ..snapshot = onlineSnapshot(prepared: true, playing: true);
      await openRooms(tester, repo);
      expect(find.byKey(const ValueKey('reloj_online')), findsOneWidget);
      final skip = find.byKey(const ValueKey('omitir_ronda_online'));
      await revealOnline(tester, skip);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('abrir_chat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cerrar_chat')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
