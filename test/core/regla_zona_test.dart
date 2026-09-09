import 'package:brilliant_game/brilliant_game.dart';
import 'package:test/test.dart';

void main() {
  for (final regla in ReglaZona.values) {
    test('$regla acepta vacío y rechaza números fuera de 1–6', () {
      expect(regla.validarValores([]), isTrue);
      expect(regla.validarValores([0]), isFalse);
      expect(regla.validarValores([7]), isFalse);
    });
  }

  test(
    'Las funciones existentes también aplican el rango sin mutar entradas',
    () {
      for (final validar in [
        cumpleReglaVerde,
        cumpleReglaAzul,
        cumpleReglaMorado,
        cumpleReglaRojoAmarillo,
      ]) {
        final original = [1];
        expect(validar(original, 7), isFalse);
        expect(validar([7], 1), isFalse);
        expect(original, [1]);
      }
    },
  );
}
