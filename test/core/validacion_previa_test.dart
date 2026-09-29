import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Validar no cambia valores ni números disponibles', () {
    final preparacion = PreparacionInicial(
      CatalogoTableros.predeterminado().crearTablero('tablero_01'),
    );
    preparacion.validarColocacion('f1_c2', 1);
    expect(preparacion.celdas['f1_c2']!.valor, isNull);
    expect(preparacion.numerosFaltantes, {1, 2, 3, 4, 5, 6});
    preparacion.colocarValor('f1_c2', 1);
    for (final (id, valor) in [
      ('f2_c6', 1),
      ('f2_c6', 7),
      ('f1_c1', 2),
      ('ausente', 2),
    ]) {
      expect(
        () => preparacion.validarColocacion(id, valor),
        throwsArgumentError,
      );
      expect(preparacion.numerosFaltantes, {2, 3, 4, 5, 6});
    }
  });

  test('La consulta aplica la restricción de zona sin mutar', () {
    final preparacion = PreparacionInicial(
      Tablero(
        id: 'azul',
        zonas: [
          Zona(
            id: 'azul',
            tipo: const TipoAzul(),
            celdas: [
              for (var i = 0; i < 6; i++)
                Celda(id: 'c$i', fila: 0, columna: i, esInicio: true),
            ],
          ),
        ],
      ),
    );
    preparacion.colocarValor('c0', 1);
    expect(() => preparacion.validarColocacion('c1', 2), throwsArgumentError);
    expect(preparacion.celdas['c1']!.valor, isNull);
  });
}
