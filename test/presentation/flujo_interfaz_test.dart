import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/presentation/pages/preparacion_page.dart';
import 'package:brilliant_game/presentation/widgets/bandeja_numeros.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> abrir(WidgetTester tester) async {
  await tester.pumpWidget(const BrilliantGameApp());
  await tester.pumpAndSettle();
  await pulsar(tester, find.text('NUEVA PARTIDA'));
}

InicioBloc blocDe(WidgetTester tester) =>
    tester.element(find.byType(PreparacionPage)).read<InicioBloc>();

void main() {
  testWidgets('El menú tiene una sola acción y abre las 49 celdas correctas', (
    tester,
  ) async {
    await tester.pumpWidget(const BrilliantGameApp());
    expect(
      find.byWidgetPredicate((widget) => widget is FilledButton),
      findsOneWidget,
    );
    expect(find.text('NUEVA PARTIDA'), findsOneWidget);
    expect(find.text('SALIR'), findsNothing);
    await pulsar(tester, find.text('NUEVA PARTIDA'));
    expect(find.byType(CeldaView), findsNWidgets(49));
    final celdas = tester
        .widgetList<CeldaView>(find.byType(CeldaView))
        .toList();
    expect(celdas.where((c) => c.celda.esInicio).length, 6);
    final tablero = CatalogoTableros.predeterminado().crearTablero(
      'tablero_01',
    );
    for (final celda in celdas) {
      expect(
        celda.tipo.color,
        tablero.obtenerZonaDeCelda(celda.celda.id).tipo.color,
      );
    }
    expect(find.byKey(const ValueKey('boton_inicio')), findsNothing);
    expect(find.byType(OutlinedButton), findsNWidgets(6));
  });

  testWidgets('Selecciona, muestra error, coloca y retira desde BLoC', (
    tester,
  ) async {
    await abrir(tester);
    await pulsar(tester, find.byKey(const ValueKey('numero_2')));
    expect(blocDe(tester).state.numeroSeleccionado, 2);
    final seleccionado = tester.getSemantics(find.bySemanticsLabel('Número 2'));
    expect(
      seleccionado,
      matchesSemantics(
        label: 'Número 2',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    await pulsar(tester, find.byKey(const ValueKey('celda_f1_c1')));
    expect(find.byKey(const ValueKey('mensaje_error')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(blocDe(tester).state.numerosFaltantes.length, 6);
    await pulsar(tester, find.byKey(const ValueKey('celda_f1_c2')));
    expect(blocDe(tester).state.celdas['f1_c2']!.valor, 2);
    expect(find.byKey(const ValueKey('numero_2')), findsNothing);
    expect(find.byKey(const ValueKey('mensaje_error')), findsNothing);
    await pulsar(tester, find.byKey(const ValueKey('celda_f1_c2')));
    expect(find.byKey(const ValueKey('numero_2')), findsOneWidget);
    expect(blocDe(tester).state.celdas['f1_c2']!.valor, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completa, inicia y bloquea; una nueva partida vuelve vacía', (
    tester,
  ) async {
    await abrir(tester);
    final anterior = blocDe(tester);
    const iniciales = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];
    for (var i = 0; i < iniciales.length; i++) {
      await pulsar(tester, find.byKey(ValueKey('numero_${i + 1}')));
      await pulsar(tester, find.byKey(ValueKey('celda_${iniciales[i]}')));
    }
    expect(find.byType(OutlinedButton), findsNothing);
    await pulsar(tester, find.byKey(const ValueKey('boton_inicio')));
    expect(anterior.state.fase, FaseInicio.iniciado);
    expect(find.text('MISIÓN INICIADA'), findsOneWidget);
    await pulsar(tester, find.byKey(const ValueKey('celda_f1_c2')));
    expect(anterior.state.celdas['f1_c2']!.valor, 1);
    await pulsar(tester, find.byTooltip('Volver al menú'));
    expect(anterior.isClosed, isTrue);
    await pulsar(tester, find.text('NUEVA PARTIDA'));
    expect(blocDe(tester).state.numerosFaltantes.length, 6);
    expect(identical(anterior, blocDe(tester)), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('La bandeja refleja estados y bloquea interacción', (
    tester,
  ) async {
    final elegidos = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BandejaNumeros(
            estado: InicioEstado(
              fase: FaseInicio.preparando,
              faseVisual: FaseVisualInicio.disparando,
              celdas: {},
              numerosFaltantes: {6, 2, 4},
            ),
            onSeleccionado: elegidos.add,
          ),
        ),
      ),
    );
    expect(
      tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .map((b) => b.key),
      [
        const ValueKey('numero_2'),
        const ValueKey('numero_4'),
        const ValueKey('numero_6'),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('numero_2')));
    expect(elegidos, isEmpty);
  });

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(844, 390),
  ]) {
    testWidgets('Sin desbordamientos en $size y texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrir(tester);
      expect(find.byType(CeldaView), findsNWidgets(49));
      expect(tester.takeException(), isNull);
    });
  }
}
