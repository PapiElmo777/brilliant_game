@Tags(['golden'])
library;

import 'dart:io';

import 'package:brilliant_game/app/brilliant_game_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Las capturas dependen de la rasterización del sistema; se generan en macOS
// con `flutter test --update-goldens test/golden`.
final _omitir = !Platform.isMacOS;

const _telefono = Size(390, 844);
const _telefonoPequeno = Size(320, 568);
const _iniciales = ['f1_c2', 'f2_c6', 'f4_c2', 'f4_c5', 'f6_c3', 'f7_c5'];

/// Carga Roboto y los iconos de Material desde el SDK para que las capturas
/// muestren texto legible en lugar de la fuente de pruebas.
Future<void> _cargarFuentes() async {
  var directorio = File(Platform.resolvedExecutable).parent;
  while (directorio.path != directorio.parent.path &&
      !Directory('${directorio.path}/artifacts/material_fonts').existsSync()) {
    directorio = directorio.parent;
  }
  final fuentes = Directory('${directorio.path}/artifacts/material_fonts');
  if (!fuentes.existsSync()) return;
  Future<ByteData> leer(String nombre) async =>
      ByteData.sublistView(await File('${fuentes.path}/$nombre').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final peso in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(leer('Roboto-$peso.ttf'));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(leer('MaterialIcons-Regular.otf'))).load();
}

Future<void> _abrir(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const BrilliantGameApp());
  await tester.pumpAndSettle();
}

Future<void> _pulsar(WidgetTester tester, String clave) async {
  final objetivo = find.byKey(ValueKey(clave));
  await tester.ensureVisible(objetivo);
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Future<void> _nuevaPartida(WidgetTester tester) async {
  await tester.tap(find.text('NUEVA PARTIDA'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('campo_nombre')), 'Ana');
  await tester.pump();
  await _pulsar(tester, 'confirmar_nombre');
}

Future<void> _completar(WidgetTester tester) async {
  for (var i = 0; i < _iniciales.length; i++) {
    await _pulsar(tester, 'numero_${i + 1}');
    await _pulsar(tester, 'celda_${_iniciales[i]}');
  }
  // Vuelve al inicio del contenido: INICIO debe verse sin desplazar.
  await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 2000));
  await tester.pumpAndSettle();
}

Future<void> _comparar(String nombre) => expectLater(
  find.byType(BrilliantGameApp),
  matchesGoldenFile('capturas/$nombre.png'),
);

void main() {
  setUpAll(_cargarFuentes);

  group('Teléfono grande', () {
    testWidgets('Menú', skip: _omitir, (tester) async {
      await _abrir(tester, _telefono);
      await _comparar('menu');
    });

    testWidgets('Diálogo del nombre', skip: _omitir, (tester) async {
      await _abrir(tester, _telefono);
      await tester.tap(find.text('NUEVA PARTIDA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('campo_nombre')), 'Ana');
      await tester.pump();
      await _comparar('dialogo_nombre');
    });

    testWidgets('Preparación vacía', skip: _omitir, (tester) async {
      await _abrir(tester, _telefono);
      await _nuevaPartida(tester);
      await _comparar('preparacion_vacia');
    });

    testWidgets('Número seleccionado', skip: _omitir, (tester) async {
      await _abrir(tester, _telefono);
      await _nuevaPartida(tester);
      await _pulsar(tester, 'numero_3');
      await _comparar('numero_seleccionado');
    });

    testWidgets('Preparación completa con INICIO', skip: _omitir, (
      tester,
    ) async {
      await _abrir(tester, _telefono);
      await _nuevaPartida(tester);
      await _completar(tester);
      await _comparar('preparacion_completa');
    });
  });

  group('Teléfono pequeño', () {
    testWidgets('Menú', skip: _omitir, (tester) async {
      await _abrir(tester, _telefonoPequeno);
      await _comparar('menu_pequeno');
    });

    testWidgets('Preparación vacía', skip: _omitir, (tester) async {
      await _abrir(tester, _telefonoPequeno);
      await _nuevaPartida(tester);
      await _comparar('preparacion_vacia_pequeno');
    });

    testWidgets('Preparación completa con INICIO', skip: _omitir, (
      tester,
    ) async {
      await _abrir(tester, _telefonoPequeno);
      await _nuevaPartida(tester);
      await _completar(tester);
      await _comparar('preparacion_completa_pequeno');
    });
  });
}
