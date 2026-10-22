import 'dart:math';
import 'dart:ui' as ui;

import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:brilliant_game/bloc/partida_bloc.dart';
import 'package:brilliant_game/brilliant_game.dart';
import 'package:brilliant_game/catalogo/tablero_01.dart';
import 'package:brilliant_game/presentation/pages/partida_page.dart';
import 'package:brilliant_game/presentation/widgets/dados_partida.dart';
import 'package:brilliant_game/presentation/widgets/meteoritos_animacion.dart';
import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Falla si la interfaz lanza más veces de las previstas por el escenario.
class _DadosProgramados implements Random {
  final List<int> valores;
  int llamadas = 0;

  _DadosProgramados(this.valores);

  @override
  int nextInt(int max) {
    expect(max, 6);
    expect(llamadas, lessThan(valores.length), reason: 'Tirada inesperada');
    return valores[llamadas++] - 1;
  }

  @override
  bool nextBool() => throw UnsupportedError('Sólo se generan dados.');
  @override
  double nextDouble() => throw UnsupportedError('Sólo se generan dados.');
}

const _iniciales = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];

// Después de las dos primeras rondas, estas cuatro zonas dan 26 puntos.
// Los destinos y totales esperados no se consultan al BLoC.
const _caminoVictoria = [
  ('f1_c3', 1, 0),
  ('f2_c3', 1, 0),
  ('f2_c4', 1, 0),
  ('f3_c4', 1, 7),
  ('f2_c5', 2, 7),
  ('f1_c5', 2, 7),
  ('f1_c4', 2, 7),
  ('f1_c6', 2, 7),
  ('f3_c5', 2, 13),
  ('f5_c3', 5, 13),
  ('f4_c3', 5, 13),
  ('f5_c4', 5, 13),
  ('f7_c3', 5, 13),
  ('f7_c2', 5, 19),
  ('f7_c6', 6, 19),
  ('f6_c6', 6, 19),
  ('f6_c7', 6, 19),
  ('f5_c7', 6, 26),
];

Finder _celda(String id) => find.byKey(ValueKey('celda_$id'));
Finder _dado(int id) => find.byKey(ValueKey('dado_$id'));

Future<void> _pulsar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

/// Toca sin esperar a que terminen las animaciones: la jugada ganadora
/// inicia la celebración, que termina sola en los resultados.
Future<void> _pulsarSinEsperar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.tap(objetivo);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _valorVisible(WidgetTester tester, String id, int valor) {
  expect(
    find.descendant(of: _celda(id), matching: find.text('$valor')),
    findsOneWidget,
  );
}

void _destinosVisibles(WidgetTester tester, Set<String> esperados) {
  expect(
    tester
        .widgetList<CeldaView>(find.byType(CeldaView))
        .where((celda) => celda.esDestino)
        .map((celda) => celda.celda.id)
        .toSet(),
    esperados,
  );
}

void _pantalla(
  WidgetTester tester,
  Size size, {
  double escala = 1,
  bool movimientoReducido = true,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: movimientoReducido);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Tablero _preparado() {
  final tablero = tablero01.crearTablero();
  for (var i = 0; i < _iniciales.length; i++) {
    tablero.colocarValor(_iniciales[i], i + 1);
  }
  return tablero;
}

Future<void> _abrirPartida(
  WidgetTester tester,
  Tablero tablero,
  _DadosProgramados azar, {
  Future<ui.Codec> Function()? cargar,
}) async {
  // La partida queda sobre una pantalla de menú para poder volver a ella.
  await tester.pumpWidget(
    MaterialApp(
      initialRoute: '/partida',
      routes: {
        '/': (_) => const Scaffold(body: Text('MENÚ DE PRUEBA')),
        '/partida': (_) => BlocProvider(
          create: (_) => PartidaBloc(tablero, azar: azar),
          child: PartidaPage(definicion: tablero01, cargarMeteoritos: cargar),
        ),
      },
    ),
  );
}

void main() {
  for (final caso in [
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 1.5),
  ]) {
    testWidgets(
      'Del menú a ${caso.$2 == 1 ? 'victoria' : 'dos rondas'}, historial y nueva partida en $caso',
      (tester) async {
        _pantalla(tester, caso.$1, escala: caso.$2);
        final terminarPartida = caso.$2 == 1;
        final azar = _DadosProgramados([
          2,
          5,
          5,
          5,
          if (terminarPartida)
            for (final (_, valor, _) in _caminoVictoria) ...[valor, valor],
        ]);
        await tester.pumpWidget(BrilliantGameApp(azarPartida: azar));
        await tester.pumpAndSettle();
        await _pulsar(tester, find.text('NUEVA PARTIDA'));
        await _pulsar(tester, find.byKey(const ValueKey('elegir_tablero_01')));
        await tester.enterText(
          find.byKey(const ValueKey('campo_nombre')),
          'Ana',
        );
        await tester.pump();
        await _pulsar(tester, find.byKey(const ValueKey('confirmar_nombre')));
        expect(find.text('PREPARA TU MISIÓN, ANA'), findsOneWidget);
        for (var i = 0; i < _iniciales.length; i++) {
          expect(find.byKey(const ValueKey('boton_inicio')), findsNothing);
          await _pulsar(tester, find.byKey(ValueKey('numero_${i + 1}')));
          await _pulsar(tester, _celda(_iniciales[i]));
          _valorVisible(tester, _iniciales[i], i + 1);
          expect(find.byKey(ValueKey('numero_${i + 1}')), findsNothing);
        }
        await _pulsar(tester, find.byKey(const ValueKey('boton_inicio')));
        expect(find.byType(PartidaPage), findsOneWidget);
        expect(find.byKey(const ValueKey('boton_inicio')), findsNothing);
        expect(find.text('MISIÓN DE ANA'), findsOneWidget);
        expect(
          tester.getSize(_celda('f1_c2')).shortestSide,
          greaterThanOrEqualTo(32),
          reason: 'Las casillas deben poder tocarse',
        );
        expect(
          find.text('Elige el número que quieres colocar.'),
          findsOneWidget,
        );
        expect(
          tester
              .widgetList<FichaDado>(find.byType(FichaDado))
              .map((ficha) => ficha.dado.valor),
          [2, 5],
        );
        expect(find.text('LANZAR METEOROS'), findsNothing);
        expect(find.text('OMITIR TIRO'), findsNothing);

        await _pulsar(tester, _dado(0));
        expect(find.text('Tu ancla es el 5'), findsOneWidget);
        _destinosVisibles(tester, {'f5_c3', 'f6_c2', 'f6_c4', 'f7_c3'});
        await _pulsar(tester, _dado(1));
        expect(find.text('Tu ancla es el 2'), findsOneWidget);
        _destinosVisibles(tester, {'f1_c6', 'f2_c5', 'f2_c7', 'f3_c6'});
        expect(azar.llamadas, 2);
        await _pulsar(tester, _celda('f2_c7'));
        _valorVisible(tester, 'f2_c7', 5);
        expect(find.text('Tiradas · 1  (2 · 5)'), findsOneWidget);
        expect(find.text('LANZAR METEOROS'), findsOneWidget);

        await _pulsar(tester, find.text('LANZAR METEOROS'));
        expect(azar.llamadas, 4);
        _valorVisible(tester, 'f2_c7', 5);
        _destinosVisibles(tester, {});
        expect(find.text('LANZAR METEOROS'), findsNothing);
        expect(
          tester
              .widgetList<FichaDado>(find.byType(FichaDado))
              .map((ficha) => ficha.dado.valor),
          [5, 5],
        );
        await _pulsar(tester, _dado(1));
        expect(find.text('Tu ancla es el 5'), findsOneWidget);
        _destinosVisibles(tester, {
          'f1_c7',
          'f3_c7',
          'f5_c3',
          'f6_c2',
          'f6_c4',
          'f7_c3',
        });
        await _pulsar(tester, _celda('f3_c7'));
        _valorVisible(tester, 'f3_c7', 5);
        for (var i = 0; i < _iniciales.length; i++) {
          _valorVisible(tester, _iniciales[i], i + 1);
        }
        await _pulsar(tester, find.text('Tiradas · 2  (5 · 5)'));
        final historial = find.byType(BottomSheet);
        expect(
          find.descendant(of: historial, matching: find.text('1:')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: historial, matching: find.text('2:')),
          findsOneWidget,
        );
        expect(find.text('Fila 2, columna 7'), findsOneWidget);
        expect(find.text('Fila 3, columna 7'), findsOneWidget);
        final fichas = tester.widgetList<FichaDado>(
          find.descendant(of: historial, matching: find.byType(FichaDado)),
        );
        expect(
          fichas
              .where((ficha) => ficha.seleccionado)
              .map((ficha) => (ficha.dado.id, ficha.dado.valor)),
          [(1, 5), (1, 5)],
        );
        expect(find.bySemanticsLabel('Dado 2: 5, colocado'), findsNWidgets(2));
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        if (terminarPartida) {
          for (var i = 0; i < _caminoVictoria.length; i++) {
            final (destino, valor, puntos) = _caminoVictoria[i];
            await _pulsar(tester, find.text('LANZAR METEOROS'));
            await _pulsar(tester, _dado(0));
            if (i == _caminoVictoria.length - 1) {
              await _pulsarSinEsperar(tester, _celda(destino));
            } else {
              await _pulsar(tester, _celda(destino));
            }
            _valorVisible(tester, destino, valor);
            expect(
              find.descendant(
                of: find.byType(PanelPuntos),
                matching: find.text('$puntos'),
              ),
              findsOneWidget,
            );
            expect(
              find.text('Tiradas · ${i + 3}  ($valor · $valor)'),
              findsOneWidget,
            );
          }
          expect(
            find.text('¡Llegaste a la meta de 26 puntos!'),
            findsOneWidget,
          );
          expect(find.text('LANZAR METEOROS'), findsNothing);
          expect(find.text('OMITIR TIRO'), findsNothing);
          // Tocar salta la celebración y muestra el ranking.
          await _pulsar(
            tester,
            find.byKey(const ValueKey('saltar_celebracion')),
          );
          expect(find.text('RESULTADOS'), findsOneWidget);
          expect(find.text('Meta: 26 puntos'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('ranking_jugador_1')),
              matching: find.text('Ana'),
            ),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(RegExp(r'^Lugar 1: Ana, 26 puntos')),
            findsOneWidget,
          );
        }
        final llamadasEsperadas = terminarPartida ? 40 : 4;
        expect(azar.llamadas, llamadasEsperadas);
        if (terminarPartida) {
          // Empezar de nuevo conserva el nombre y va directo a la preparación.
          await _pulsar(
            tester,
            find.byKey(const ValueKey('boton_empezar_de_nuevo')),
          );
          expect(find.byType(PartidaPage), findsNothing);
          expect(find.byType(TextField), findsNothing);
          expect(find.text('PREPARA TU MISIÓN, ANA'), findsOneWidget);
          expect(
            tester
                .widgetList<CeldaView>(find.byType(CeldaView))
                .every((celda) => celda.celda.valor == null),
            isTrue,
          );
          await _pulsar(tester, find.byTooltip('Volver al menú'));
        } else {
          await _pulsar(tester, find.byTooltip('Volver al menú'));
          await _pulsar(tester, find.byKey(const ValueKey('confirmar_salida')));
        }
        await _pulsar(tester, find.text('NUEVA PARTIDA'));
        await _pulsar(tester, find.byKey(const ValueKey('elegir_tablero_01')));
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Ana',
        );
        await _pulsar(tester, find.byKey(const ValueKey('confirmar_nombre')));
        expect(
          tester
              .widgetList<CeldaView>(find.byType(CeldaView))
              .every((celda) => celda.celda.valor == null),
          isTrue,
        );
        expect(find.byType(OutlinedButton), findsNWidgets(6));
        expect(azar.llamadas, llamadasEsperadas);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Completar zonas actualiza puntos, puestos y victoria en pantalla',
    (tester) async {
      _pantalla(tester, const Size(390, 844));
      final tablero = _preparado();
      // Tablero real avanzado: cuatro zonas a una casilla de completarse.
      for (final (zona, hueco, valor) in [
        ('azul_1', 'f1_c3', 1),
        ('azul_2', 'f5_c7', 3),
        ('morado_1', 'f1_c4', 2),
        ('morado_2', 'f4_c3', 5),
      ]) {
        for (final celda in tablero.obtenerZona(zona).celdas.values) {
          if (celda.id != hueco) tablero.colocarValor(celda.id, valor);
        }
      }
      tablero.colocarValor('f4_c7', 4);
      final azar = _DadosProgramados([1, 1, 3, 4, 2, 1, 5, 3]);
      await _abrirPartida(tester, tablero, azar);
      await tester.pumpAndSettle();
      final panel = find.byType(PanelPuntos);
      expect(
        find.descendant(of: panel, matching: find.text('0')),
        findsOneWidget,
      );
      for (final (destino, total, ganados) in [
        ('f1_c3', 7, 7),
        ('f5_c7', 14, 7),
        ('f1_c4', 20, 6),
        ('f4_c3', 26, 6),
      ]) {
        await _pulsar(tester, _dado(0));
        if (total == 26) {
          await _pulsarSinEsperar(tester, _celda(destino));
        } else {
          await _pulsar(tester, _celda(destino));
        }
        expect(
          find.descendant(of: panel, matching: find.text('$total')),
          findsOneWidget,
        );
        if (total < 26) {
          expect(
            find.text(
              '¡Zona completada! +$ganados puntos. '
              'Puedes cambiar tu jugada o lanzar.',
            ),
            findsOneWidget,
          );
          if (total == 7) {
            await _pulsar(tester, _celda(destino));
            expect(
              find.descendant(of: panel, matching: find.text('0')),
              findsOneWidget,
            );
            expect(find.text('Tiradas · 0'), findsOneWidget);
            await _pulsar(tester, _celda(destino));
            expect(
              find.descendant(of: panel, matching: find.text('7')),
              findsOneWidget,
            );
            expect(find.text('Tiradas · 1  (1 · 1)'), findsOneWidget);
            await tester.ensureVisible(_celda(destino));
            final gesto = await tester.startGesture(
              tester.getCenter(_celda(destino)),
            );
            await tester.pump(const Duration(milliseconds: 600));
            expect(find.text('1.º puesto ya reclamado'), findsOneWidget);
            await gesto.up();
            await tester.pumpAndSettle();
          }
          await _pulsar(tester, find.text('LANZAR METEOROS'));
        }
      }
      expect(find.text('¡Llegaste a la meta de 26 puntos!'), findsOneWidget);
      expect(find.text('LANZAR METEOROS'), findsNothing);
      expect(find.text('OMITIR TIRO'), findsNothing);
      expect(find.text('Tiradas · 4  (5 · 3)'), findsOneWidget);
      expect(azar.llamadas, 8);
      // El regreso del sistema omite la celebración y luego sale sin
      // pedir confirmación.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('RESULTADOS'), findsOneWidget);
      await tester.pumpAndSettle();
      await _pulsar(tester, find.byKey(const ValueKey('boton_salir_menu')));
      expect(find.byType(PartidaPage), findsNothing);
      expect(find.text('MENÚ DE PRUEBA'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirmar_salida')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sin destinos, omitir conserva tablero e historial sin dado elegido',
    (tester) async {
      _pantalla(tester, const Size(390, 844));
      final tablero = _preparado();
      for (final celda in tablero.celdas.values) {
        if (!celda.estaOcupada) {
          tablero.colocarValor(
            celda.id,
            [
              1,
              2,
              3,
              4,
              5,
              6,
            ].firstWhere((valor) => tablero.puedeColocarValor(celda.id, valor)),
          );
        }
      }
      final azar = _DadosProgramados([2, 5, 1, 6]);
      await _abrirPartida(tester, tablero, azar);
      await tester.pumpAndSettle();
      expect(
        find.text('Ninguno de los dados tiene destinos disponibles.'),
        findsOneWidget,
      );
      await _pulsar(tester, find.text('OMITIR TIRO'));
      for (final celda in tablero.celdas.values) {
        _valorVisible(tester, celda.id, celda.valor!);
      }
      await _pulsar(tester, find.text('Tiradas · 1  (2 · 5)'));
      expect(find.text('Omitida'), findsOneWidget);
      expect(
        tester
            .widgetList<FichaDado>(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(FichaDado),
              ),
            )
            .every((ficha) => !ficha.seleccionado),
        isTrue,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _pulsar(tester, find.text('LANZAR METEOROS'));
      expect(azar.llamadas, 4);
      expect(find.text('Tiradas · 1  (2 · 5)'), findsOneWidget);
      expect(find.text('OMITIR TIRO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Impacto, revelado y movimiento habilitan la selección en orden',
    (tester) async {
      _pantalla(tester, const Size(390, 844), movimientoReducido: false);
      final grabador = ui.PictureRecorder();
      Canvas(grabador).drawColor(Colors.transparent, BlendMode.src);
      final dibujo = grabador.endRecording();
      final imagen = await dibujo.toImage(2, 2);
      dibujo.dispose();
      addTearDown(imagen.dispose);
      final azar = _DadosProgramados([2, 5]);
      await _abrirPartida(
        tester,
        _preparado(),
        azar,
        cargar: () async => _ClipPrueba(imagen),
      );
      await tester.pump();
      expect(find.text('¡El juego comenzó!'), findsOneWidget);
      expect(find.byType(FichaDado), findsNothing);
      for (var i = 0; i < 119; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.text('Resultados: 2 y 5'), findsOneWidget);
      expect(tester.widget<FichaDado>(_dado(0)).onTap, isNull);
      expect(find.byType(MeteoritosAnimacion), findsOneWidget);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();
      expect(find.byType(MeteoritosAnimacion), findsNothing);
      final abajo = tester.getCenter(_dado(1));
      await tester.tap(_dado(1));
      await tester.pump();
      expect(tester.widget<FichaDado>(_dado(0)).onTap, isNull);
      _destinosVisibles(tester, {});
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getCenter(_dado(1)).dy, lessThan(abajo.dy));
      await tester.pumpAndSettle();
      expect(find.text('Tu ancla es el 2'), findsOneWidget);
      _destinosVisibles(tester, {'f1_c6', 'f2_c5', 'f2_c7', 'f3_c6'});
      await _pulsar(tester, _celda('f2_c7'));
      _valorVisible(tester, 'f2_c7', 5);
      expect(find.text('Tiradas · 1  (2 · 5)'), findsOneWidget);
      expect(azar.llamadas, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _ClipPrueba implements ui.Codec {
  final ui.Image imagen;
  _ClipPrueba(this.imagen);
  @override
  int get frameCount => 130;
  @override
  int get repetitionCount => -1;
  @override
  Future<ui.FrameInfo> getNextFrame() async => _CuadroPrueba(imagen.clone());
  @override
  void dispose() {}
}

class _CuadroPrueba implements ui.FrameInfo {
  @override
  final ui.Image image;
  _CuadroPrueba(this.image);
  @override
  Duration get duration => const Duration(milliseconds: 70);
}
