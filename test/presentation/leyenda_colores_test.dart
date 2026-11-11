import 'package:brilliant_game/catalogo/catalogo_tableros.dart';
import 'package:brilliant_game/models/tipo.dart';
import 'package:brilliant_game/presentation/widgets/leyenda_colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('El blanco mantiene la igualdad y naranja distingue ambos grupos', () {
    expect(simboloRegla(const TipoBlanco()), '=');
    expect(simboloRegla(const TipoMorado()), '×○');
    expect(simboloRegla(const TipoNaranja(GrupoNaranja.bajo)), '1–3');
    expect(simboloRegla(const TipoNaranja(GrupoNaranja.alto)), '4–6');
  });
  for (final level in CatalogoTableros.predeterminado().definiciones.values) {
    testWidgets(
      'Solo muestra reglas de ${level.id}, sin ocupar el centro de los dados',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 272,
                  height: 80,
                  child: LeyendaColores(definicion: level),
                ),
              ),
            ),
          ),
        );
        final rules = tester.widgetList<CuadroRegla>(find.byType(CuadroRegla));
        expect(rules.length, reglasDelNivel(level).length);
        for (final tile in find.byType(CuadroRegla).evaluate()) {
          final rect = tester.getRect(find.byWidget(tile.widget));
          final center = tester.getCenter(find.byType(LeyendaColores)).dx;
          expect(rect.right <= center - 72 || rect.left >= center + 72, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
