import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Los puntos dependen del tamaño de la zona', () {
    final zonas = {for (final z in tablero01Zonas()) z.id: z};
    expect(puntosDeZona(zonas['amarillo_1']!), [2, 1, 0]);
    expect(puntosDeZona(zonas['azul_1']!), [5, 3, 1]);
    expect(puntosDeZona(zonas['verde_1']!), [7, 5, 3]);
    expect(puntosPorTamano[5], [6, 4, 2]);
    expect(puntosPorTamano[7], [8, 6, 4]);
  });

  test('La puntuación suma sólo las zonas completas', () {
    final definicion = CatalogoTableros.predeterminado().obtenerDefinicion('tablero_01');
    final tablero = definicion.crearTablero();
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 0);
    tablero.colocarValor('f1_c1', 3);
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 2);
    for (final id in ['f1_c3', 'f2_c3', 'f2_c4', 'f3_c4']) {
      tablero.colocarValor(id, 4);
    }
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 2 + 5);
  });
}

List<DefinicionZona> tablero01Zonas() =>
    CatalogoTableros.predeterminado().obtenerDefinicion('tablero_01').zonas;
