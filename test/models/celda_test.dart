import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Celda crear({int? valor}) =>
      Celda(id: 'C1', fila: 4, columna: 2, esInicio: true, valorInicial: valor);

  test(
    'Una celda nueva está vacía y conserva su posición y marca de inicio',
    () {
      final celda = crear();
      expect(celda.id, 'C1');
      expect(celda.fila, 4);
      expect(celda.columna, 2);
      expect(celda.esInicio, isTrue);
      expect(celda.valor, isNull);
      expect(celda.estaOcupada, isFalse);
    },
  );

  test('Admite valores iniciales y copias con los límites 1 y 6', () {
    final original = crear(valor: 1);
    final copia = original.conValor(6);
    expect(original.valor, 1);
    expect(copia.valor, 6);
    expect(copia.estaOcupada, isTrue);
    expect(copia.id, original.id);
    expect(copia.fila, original.fila);
    expect(copia.columna, original.columna);
    expect(copia.esInicio, isTrue);
  });

  test('Vaciar una copia no modifica el original ni pierde sus datos', () {
    final original = crear(valor: 4);
    final vacia = original.sinValor();
    expect(original.valor, 4);
    expect(vacia.valor, isNull);
    expect(vacia.estaOcupada, isFalse);
    expect(vacia.id, original.id);
    expect(vacia.esInicio, isTrue);
  });

  test('Rechaza valores fuera de rango tanto al construir como al copiar', () {
    for (final valor in [-1, 0, 7]) {
      expect(() => crear(valor: valor), throwsArgumentError);
      expect(() => crear().conValor(valor), throwsArgumentError);
    }
  });

  test('Rechaza identificadores vacíos', () {
    expect(() => Celda(id: ' ', fila: 0, columna: 0), throwsArgumentError);
  });
}
