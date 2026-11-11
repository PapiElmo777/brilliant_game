import 'package:brilliant_game/presentation/widgets/tablero_view.dart';
import 'package:brilliant_game/catalogo/tablero_01.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Cada puesto reduce la saturación y los premios agotados quedan apagados',
    () {
      const original = Color(0xFFF44336);
      final colors = [
        for (var n = 0; n <= 3; n++) colorPremioZona(original, n, 3),
      ];
      expect(colors.first, original);
      for (var n = 1; n < colors.length; n++) {
        expect(
          HSVColor.fromColor(colors[n]).value,
          lessThan(HSVColor.fromColor(colors[n - 1]).value),
        );
      }
      expect(colorPremioZona(original, 6, 3), colors.last);
    },
  );
  testWidgets('Tres reclamos apagan la zona y no impiden tocar una casilla', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: TableroView.partida(
              definicion: tablero01,
              celdas: tablero01.crearTablero().celdas,
              destinos: const {'f1_c2'},
              atenuarPremios: true,
              puestosReclamados: const {'verde_1': 3},
              onCeldaSeleccionada: (id) => tapped = id,
            ),
          ),
        ),
      ),
    );
    final cell = find.byKey(const ValueKey('celda_f1_c2'));
    expect(tester.widget<CeldaView>(cell).puestosReclamados, 3);
    expect(
      tester
          .widget<CeldaView>(find.byKey(const ValueKey('celda_f2_c7')))
          .puestosReclamados,
      0,
    );
    await tester.tap(cell);
    expect(tapped, 'f1_c2');
  });
}
