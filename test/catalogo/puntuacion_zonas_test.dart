import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Los puntos dependen del color de la zona', () {
    final zonas = {for (final z in tablero01Zonas()) z.id: z};
    expect(puntosDeZona(zonas['azul_1']!), [7, 6, 3]);
    expect(puntosDeZona(zonas['morado_1']!), [6, 4, 2]);
    expect(puntosDeZona(zonas['verde_1']!), [4, 3, 2]);
    expect(puntosDeZona(zonas['amarillo']!), [8, 6, 4]);
    expect(puntosDeZona(zonas['rojo_2']!), [6, 4, 2]);
  });
}

List<DefinicionZona> tablero01Zonas() =>
    CatalogoTableros.predeterminado().obtenerDefinicion('tablero_01').zonas;
