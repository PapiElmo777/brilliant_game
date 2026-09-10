import 'package:brilliant_game/brilliant_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final tipo in const [
    TipoVerde(),
    TipoAzul(),
    TipoRojo(),
    TipoMorado(),
    TipoAmarillo(),
  ]) {
    test('$tipo acepta vacío y rechaza números fuera de 1–6', () {
      expect(validarValoresDeTipo(tipo, []), isTrue);
      expect(validarValoresDeTipo(tipo, [0]), isFalse);
      expect(validarValoresDeTipo(tipo, [7]), isFalse);
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
