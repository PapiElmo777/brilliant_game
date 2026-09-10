import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../example/main.dart' as ejemplo;

void main() {
  test('El ejemplo completa la zona verde y rechaza otro número en azul', () {
    final salida = <String>[];
    runZoned(
      ejemplo.main,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => salida.add(line),
      ),
    );
    expect(salida, [
      'Zona 2: [4, 2]',
      'Zona 2 completada: true',
      '¿Se puede poner 3 en C4 (azul)? false',
      'Vecino derecho de C1: C3',
    ]);
  });
}
