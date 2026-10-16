import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:brilliant_game/bloc/partida_estado.dart';
import 'package:brilliant_game/presentation/pages/partida_page.dart';
import 'package:brilliant_game/presentation/widgets/nave_marciano.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../bloc/partida_bloc_test.dart' show AzarFijo;

void main() {
  Future<PartidaBloc> abrir(WidgetTester tester, {bool lleno = false}) async {
    final d = DefinicionTablero(
      id: 'verde',
      zonas: [
        DefinicionZona(
          id: 'v',
          tipo: const TipoVerde(),
          celdas: [
            for (var f = 0; f < 7; f++)
              for (var c = 0; c < 7; c++)
                Celda(
                  id: '$f-$c',
                  fila: f,
                  columna: c,
                  esInicio: f == 0 && c < 6,
                ),
          ],
        ),
      ],
    );
    final t = d.crearTablero();
    if (lleno) {
      for (final id in t.celdas.keys) {
        t.colocarValor(id, 1);
      }
    } else {
      for (var i = 0; i < 6; i++) {
        t.colocarValor('0-$i', i + 1);
      }
    }
    final b = PartidaBloc(t, azar: AzarFijo([2, 5]));
    addTearDown(b.close);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: tester.view.physicalSize / tester.view.devicePixelRatio,
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.5),
          ),
          child: BlocProvider.value(
            value: b,
            child: PartidaPage(definicion: d),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return b;
  }

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(844, 390),
  ]) {
    testWidgets('Selecciona, intercambia y coloca sin desbordar en $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final b = await abrir(tester);
      final nave = tester.getRect(find.byType(NaveMarciano));
      final panel = tester.getRect(find.byType(PanelPuntos));
      expect(panel.left, greaterThanOrEqualTo(nave.right));
      expect(panel.right, lessThanOrEqualTo(size.width));
      expect(find.text('PUNTOS'), findsOneWidget);
      final antes = tester.getCenter(find.byKey(const ValueKey('dado_0')));
      await tester.ensureVisible(find.byKey(const ValueKey('dado_0')));
      await tester.tap(find.byKey(const ValueKey('dado_0')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(GloboAlien),
          matching: find.text('Tu ancla es el 5'),
        ),
        findsOneWidget,
      );
      expect(b.state.fase, FasePartida.eligiendoDestino);
      expect(
        tester.getCenter(find.byKey(const ValueKey('dado_0'))).dy,
        lessThan(antes.dy),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('dado_1')));
      await tester.tap(find.byKey(const ValueKey('dado_1')));
      await tester.pumpAndSettle();
      expect(find.text('Tu ancla es el 2'), findsOneWidget);
      final disponibles = tester
          .widgetList<CeldaView>(find.byType(CeldaView))
          .where((c) => c.esDestino);
      expect(disponibles.map((c) => c.celda.id).toSet(), b.state.destinos);
      final invalida = b.state.celdas.values.firstWhere(
        (c) => !c.estaOcupada && !b.state.destinos.contains(c.id),
      );
      await tester.ensureVisible(find.byKey(ValueKey('celda_${invalida.id}')));
      await tester.tap(find.byKey(ValueKey('celda_${invalida.id}')));
      await tester.pumpAndSettle();
      expect(
        find.text('Esa casilla no es válida. Elige una casilla resaltada.'),
        findsOneWidget,
      );
      expect(b.state.historial, isEmpty);
      expect(b.state.celdas[invalida.id]!.valor, isNull);
      final destino = find.byKey(ValueKey('celda_${b.state.destinos.first}'));
      await tester.ensureVisible(destino);
      await tester.pumpAndSettle();
      await tester.tap(destino);
      await tester.pumpAndSettle();
      expect(b.state.historial.length, 1);
      expect(b.state.historial.single.dadoId, 1);
      expect(
        find.text('Puedes cambiar tu jugada o lanzar los meteoros.'),
        findsOneWidget,
      );
      // Tocar el número escrito lo retira y permite volver a colocarlo.
      final colocadaId = b.state.celdaColocada!;
      await tester.ensureVisible(find.byKey(ValueKey('celda_$colocadaId')));
      await tester.tap(find.byKey(ValueKey('celda_$colocadaId')));
      await tester.pumpAndSettle();
      expect(b.state.historial, isEmpty);
      expect(b.state.celdas[colocadaId]!.valor, isNull);
      await tester.ensureVisible(find.byKey(ValueKey('celda_$colocadaId')));
      await tester.tap(find.byKey(ValueKey('celda_$colocadaId')));
      await tester.pumpAndSettle();
      expect(b.state.historial.single.celdaId, colocadaId);
      expect(find.text('LANZAR METEOROS'), findsOneWidget);
      final tablero = tester.getRect(find.byType(TableroView));
      expect(
        tester.getRect(find.byKey(const ValueKey('boton_lanzar'))).top,
        greaterThanOrEqualTo(tablero.bottom),
      );
      final globo = tester.getRect(find.byType(GloboAlien));
      for (final id in [0, 1]) {
        final dado = tester.getRect(find.byKey(ValueKey('dado_$id')));
        expect(dado.top, greaterThan(globo.bottom + 8));
        expect(dado.bottom, lessThanOrEqualTo(tablero.top));
      }
      expect(
        tester.getSize(find.byKey(const ValueKey('celda_0-1'))).shortestSide,
        greaterThanOrEqualTo(32),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('boton_lanzar')));
      expect(
        tester.getRect(find.byKey(const ValueKey('boton_lanzar'))).bottom,
        lessThanOrEqualTo(size.height),
      );
      await tester.ensureVisible(find.textContaining('Tiradas · 1'));
      await tester.tap(find.textContaining('Tiradas · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Historial de tiradas'), findsOneWidget);
      final colocada = b.state.celdas[b.state.historial.single.celdaId]!;
      expect(
        find.text('Fila ${colocada.fila + 1}, columna ${colocada.columna + 1}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Omitir conserva tablero y habilita solo un nuevo lanzamiento', (
    tester,
  ) async {
    final b = await abrir(tester, lleno: true);
    final antes = b.state.celdas;
    final omitir = find.text('OMITIR TIRO');
    await tester.ensureVisible(omitir);
    await tester.tap(omitir);
    await tester.pumpAndSettle();
    expect(b.state.celdas, antes);
    expect(b.state.historial.single.dadoId, isNull);
    final lanzar = find.text('LANZAR METEOROS');
    await tester.ensureVisible(lanzar);
    await tester.tap(lanzar);
    await tester.pumpAndSettle();
    expect(b.state.tirada.id, 2);
    expect(b.state.historial.length, 1);
    expect(find.text('LANZAR METEOROS'), findsNothing);
  });
}
