import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Los puntos dependen del tamaño de la zona', () {
    final zonas = {for (final z in tablero01Zonas()) z.id: z};
    expect(zonas['amarillo']!.celdas.length, 5);
    expect(puntosDeZona(zonas['amarillo']!), [2, 1, 0]);
    expect(puntosDeZona(zonas['azul_1']!), [5, 3, 1]);
    expect(puntosDeZona(zonas['verde_1']!), [7, 5, 3]);
    expect(puntosPorTamano[5], [6, 4, 2]);
    expect(puntosPorTamano[7], [8, 6, 4]);
  });

  test('La puntuación suma sólo las zonas completas', () {
    final definicion = CatalogoTableros.predeterminado().obtenerDefinicion(
      'tablero_01',
    );
    final tablero = definicion.crearTablero();
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 0);
    // La zona amarilla sólo puntúa con sus cinco casillas ocupadas.
    for (final (id, valor) in [
      ('f1_c1', 1),
      ('f1_c7', 2),
      ('f4_c4', 3),
      ('f7_c1', 4),
    ]) {
      tablero.colocarValor(id, valor);
    }
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 0);
    tablero.colocarValor('f7_c7', 5);
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 2);
    for (final id in ['f1_c3', 'f2_c3', 'f2_c4', 'f3_c4']) {
      tablero.colocarValor(id, 4);
    }
    expect(puntuacionRepresentativa(definicion, tablero.celdas), 2 + 5);
  });
}

List<DefinicionZona> tablero01Zonas() =>
    CatalogoTableros.predeterminado().obtenerDefinicion('tablero_01').zonas;
